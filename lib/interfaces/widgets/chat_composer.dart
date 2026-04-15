import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:personal_application/core/database/app_database.dart';
import 'package:personal_application/core/models/message/enums.dart';
import 'package:personal_application/core/services/assistant_chat_cubit.dart';
import 'package:personal_application/core/services/llm_service.dart';
import 'package:provider/provider.dart';

class ChatComposer extends StatefulWidget {
  final Function(String text) onSend;
  final VoidCallback? onAddMedia;
  final bool isStreaming;
  final VoidCallback? onStop;

  const ChatComposer({
    super.key,
    required this.onSend,
    this.onAddMedia,
    this.isStreaming = false,
    this.onStop,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _containerKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  String? _currentTrigger;

  final Map<String, List<String>> _options = {
    '@': [
      'Assistant',
      'Notes',
      'Sprints',
      'Files',
      'Settings',
      'Profile',
      'Search',
      'Archive',
      'Trash',
      'Favorites',
      'Recent',
      'Support',
      'Feedback',
    ],
    '/': [
      'Summarize',
      'Explain',
      'Fix',
      'Translate',
      'Clear',
      'Export',
      'Copy',
      'Share',
      'Delete',
      'Rename',
      'Move',
      'Edit',
      'History',
    ],
    '!': [],
  };

  Map<LLMProvider, List<String>> _fetchedModels = {};
  List<Conversation> _fetchedConversations = [];
  bool _isLoadingModels = false;
  String? _modelError;

  Future<void> _fetchModels() async {
    if (_fetchedModels.isNotEmpty && !_isLoadingModels) return;

    setState(() {
      _isLoadingModels = true;
      _modelError = null;
    });

    try {
      final service = LLMService();
      final results = await Future.wait(
        LLMProvider.values.map((p) async {
          try {
            if (!service.hasApiKey(p)) return MapEntry(p, <String>[]);
            final models = await service.listModels(p);
            return MapEntry(p, models);
          } catch (e) {
            return MapEntry(p, <String>[]);
          }
        }),
      );

      if (mounted) {
        setState(() {
          _fetchedModels = Map.fromEntries(results);
          _isLoadingModels = false;
        });
        // Re-open overlay to refresh data if still showing #
        if (_currentTrigger == '#') {
          _showOverlay('#');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _modelError = e.toString();
          _isLoadingModels = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  void _measureHeight() {
    if (!mounted) return;
    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final height = renderBox.size.height;
      final bottomSafeArea = MediaQuery.of(context).padding.bottom;
      context.read<ComposerHeightNotifier>().setHeight(height - bottomSafeArea);
    }
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchConversations() async {
    setState(() {
      _isLoadingModels = true;
      _modelError = null;
    });
    try {
      final convos = await context
          .read<AssistantChatCubit>()
          .getConversations();
      setState(() {
        _fetchedConversations = convos;
        _isLoadingModels = false;
      });
    } catch (e) {
      setState(() {
        _modelError = e.toString();
        _isLoadingModels = false;
      });
    }
  }

  void _onTextChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
    final text = _controller.text;
    final selection = _controller.selection;

    if (!selection.isValid || selection.baseOffset == 0) {
      _hideOverlay();
      return;
    }

    final beforeCursor = text.substring(0, selection.baseOffset);
    final lastChar = beforeCursor[beforeCursor.length - 1];

    if (lastChar == '@' || lastChar == '/') {
      _showOverlay(lastChar);
    } else if (lastChar == ' ' || beforeCursor.isEmpty) {
      _hideOverlay();
    }
  }

  void _selectConversation(String id) {
    context.read<AssistantChatCubit>().selectConversation(id);
    _hideOverlay();
    _focusNode.requestFocus();
  }

  void _showOverlay(String trigger) {
    _hideOverlay();
    _currentTrigger = trigger;

    final overlay = Overlay.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final items = [];
        if (trigger == '!') {
          items.add('NEW_CHAT_ACTION');
          items.addAll(_fetchedConversations);
        } else if (trigger == '#') {
          if (_modelError != null) {
            items.add('Error: $_modelError');
          } else if (_isLoadingModels) {
            items.add('Loading models...');
          } else {
            final service = LLMService();
            for (final provider in LLMProvider.values) {
              items.add(provider);
              final models = _fetchedModels[provider] ?? [];
              if (models.isEmpty) {
                if (!service.hasApiKey(provider)) {
                  items.add('API key missing');
                } else {
                  items.add('No models found');
                }
              } else {
                items.addAll(models);
              }
            }
          }
        } else {
          items.addAll(_options[trigger] ?? []);
        }

        const double itemHeight = 36;
        final double totalHeight = (items.length * itemHeight + 16).clamp(
          0,
          300,
        );

        return Positioned(
          width: 280,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, -totalHeight - 8),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                constraints: BoxConstraints(maxHeight: totalHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];

                          if (item is LLMProvider) {
                            return Container(
                              height: 24,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              alignment: Alignment.centerLeft,
                              color: Colors.white.withAlpha(5),
                              child: Text(
                                item.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }

                          if (item == 'NEW_CHAT_ACTION') {
                            return _OptionTile(
                              label: 'New Chat',
                              index: 1,
                              height: itemHeight,
                              icon: Icons.add_rounded,
                              onTap: () {
                                context
                                    .read<AssistantChatCubit>()
                                    .startNewChat();
                                _hideOverlay();
                              },
                            );
                          }

                          if (item is Conversation) {
                            return _OptionTile(
                              label: item.title ?? 'Untitled',
                              index: i + 1,
                              height: itemHeight,
                              onTap: () => _selectConversation(item.id),
                            );
                          }

                          final isSelectable =
                              item != 'Loading models...' &&
                              item != 'API key missing' &&
                              item != 'No models found' &&
                              !item.toString().startsWith('Error:');

                          return _OptionTile(
                            label: item.toString(),
                            index: i + 1,
                            height: itemHeight,
                            isSelectable: isSelectable,
                            onTap: isSelectable
                                ? () {
                                    if (trigger == '#') {
                                      LLMProvider? provider;
                                      for (final p in LLMProvider.values) {
                                        if (_fetchedModels[p]?.contains(item) ??
                                            false) {
                                          provider = p;
                                          break;
                                        }
                                      }
                                      if (provider != null) {
                                        _selectModel(provider, item.toString());
                                      }
                                    } else {
                                      _selectOption(item.toString());
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
    setState(() {});
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentTrigger = null;
  }

  void _selectModel(LLMProvider provider, String model) {
    context.read<AssistantChatCubit>().setModel(provider, model);
    _hideOverlay();
    _focusNode.requestFocus();
  }

  void _selectOption(String option) {
    if (_currentTrigger == null) return;

    final text = _controller.text;
    final selection = _controller.selection;
    final beforeTrigger = text.substring(0, selection.baseOffset - 1);
    final afterTrigger = text.substring(selection.baseOffset);

    final newText = '$beforeTrigger$option $afterTrigger';
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: beforeTrigger.length + option.length + 1,
    );

    _hideOverlay();
    _focusNode.requestFocus();
  }

  void _handleSend() {
    if (widget.isStreaming) return;
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
      _hideOverlay();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        key: _containerKey,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(20),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: widget.onAddMedia,
                    icon: const Icon(Icons.add_rounded),
                    iconSize: 26,
                    color: theme.colorScheme.primary,
                    tooltip: 'Add media',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withAlpha(15)
                            : Colors.black.withAlpha(10),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: CallbackShortcuts(
                        bindings: {
                          const SingleActivator(
                            LogicalKeyboardKey.enter,
                            control: true,
                          ): _handleSend,
                          const SingleActivator(
                            LogicalKeyboardKey.enter,
                            meta: true,
                          ): _handleSend,
                          for (int i = 0; i < 9; i++)
                            SingleActivator(
                              _getDigitKey(i + 1),
                              control: true,
                            ): () =>
                                _selectShortcut(i),
                          const SingleActivator(
                            LogicalKeyboardKey.digit0,
                            control: true,
                          ): () =>
                              _selectShortcut(9),
                        },
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          enabled: true,
                          maxLines: 5,
                          minLines: 1,
                          textInputAction: TextInputAction.newline,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                          decoration: const InputDecoration(
                            hintText: 'Message',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, child) {
                      if (widget.isStreaming) {
                        return IconButton(
                          onPressed: widget.onStop,
                          icon: const Icon(Icons.stop_rounded),
                          iconSize: 24,
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.all(8),
                          ),
                        );
                      }

                      final hasText = _controller.text.trim().isNotEmpty;
                      return IconButton(
                        onPressed: hasText ? _handleSend : null,
                        icon: const Icon(Icons.arrow_upward_rounded),
                        iconSize: 24,
                        color: hasText
                            ? Colors.white
                            : Colors.grey.withAlpha(100),
                        style: IconButton.styleFrom(
                          backgroundColor: hasText
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          padding: const EdgeInsets.all(8),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 44),
                  _ComposerIconButton(
                    icon: Icons.psychology_rounded,
                    tooltip: 'Model Settings',
                    isActive: _currentTrigger == '#',
                    onPressed: () async {
                      if (_currentTrigger == '#') {
                        _hideOverlay();
                      } else {
                        await _fetchModels();
                        _showOverlay('#');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _ComposerIconButton(
                    icon: Icons.forum_rounded,
                    tooltip: 'Conversations',
                    isActive: _currentTrigger == '!',
                    onPressed: () async {
                      if (_currentTrigger == '!') {
                        _hideOverlay();
                      } else {
                        await _fetchConversations();
                        _showOverlay('!');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  LogicalKeyboardKey _getDigitKey(int digit) {
    switch (digit) {
      case 1:
        return LogicalKeyboardKey.digit1;
      case 2:
        return LogicalKeyboardKey.digit2;
      case 3:
        return LogicalKeyboardKey.digit3;
      case 4:
        return LogicalKeyboardKey.digit4;
      case 5:
        return LogicalKeyboardKey.digit5;
      case 6:
        return LogicalKeyboardKey.digit6;
      case 7:
        return LogicalKeyboardKey.digit7;
      case 8:
        return LogicalKeyboardKey.digit8;
      case 9:
        return LogicalKeyboardKey.digit9;
      default:
        return LogicalKeyboardKey.digit1;
    }
  }

  void _selectShortcut(int index) {
    if (_currentTrigger == null) return;

    if (_currentTrigger == '#') {
      List<dynamic> items = [];
      if (_modelError != null) {
        items = ['Error: $_modelError'];
      } else if (_isLoadingModels) {
        items = ['Loading models...'];
      } else {
        for (final provider in LLMProvider.values) {
          items.add(provider);
          final models = _fetchedModels[provider] ?? [];
          if (models.isEmpty) {
            if (!LLMService().hasApiKey(provider)) {
              items.add('API key missing');
            } else {
              items.add('No models found');
            }
          } else {
            items.addAll(models);
          }
        }
      }

      if (index < items.length) {
        final item = items[index];
        final isSelectable =
            item is! LLMProvider &&
            item != 'Loading models...' &&
            item != 'API key missing' &&
            item != 'No models found' &&
            !item.toString().startsWith('Error:');

        if (isSelectable) {
          LLMProvider? provider;
          for (final p in LLMProvider.values) {
            if (_fetchedModels[p]?.contains(item) ?? false) {
              provider = p;
              break;
            }
          }
          if (provider != null) {
            _selectModel(provider, item.toString());
          }
        }
      }
    } else if (_currentTrigger == '!') {
      if (index < _fetchedConversations.length) {
        _selectConversation(_fetchedConversations[index].id);
      }
    } else {
      final list = _options[_currentTrigger]!;
      if (index < list.length) {
        _selectOption(list[index]);
      }
    }
  }
}

class _ComposerIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  const _ComposerIconButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? (isDark
                  ? theme.colorScheme.primary.withAlpha(40)
                  : theme.colorScheme.primary.withAlpha(20))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
          color: isActive
              ? theme.colorScheme.primary
              : (isDark ? Colors.white60 : Colors.black45),
        ),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final int index;
  final double height;
  final VoidCallback? onTap;
  final bool isSelectable;
  final IconData? icon;

  const _OptionTile({
    required this.label,
    required this.index,
    required this.height,
    this.onTap,
    this.isSelectable = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSelectable ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (isSelectable) ...[
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(10)
                          : Colors.black.withAlpha(5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: icon != null
                        ? Icon(icon, size: 14, color: theme.colorScheme.primary)
                        : Text(
                            '${index % 10}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: index <= 10
                                  ? theme.colorScheme.primary
                                  : Colors.grey,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelectable
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: isSelectable
                          ? (isDark
                                ? Colors.white.withAlpha(200)
                                : Colors.black)
                          : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelectable && index <= 10)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'Ctrl+$index',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.withAlpha(100),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
