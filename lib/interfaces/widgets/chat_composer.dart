import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:provider/provider.dart';

class ChatComposer extends StatefulWidget {
  final Function(String text) onSend;
  final VoidCallback? onAddMedia;
  final bool isStreaming;
  final VoidCallback? onStop;
  final String? selectedModel;

  const ChatComposer({
    super.key,
    required this.onSend,
    this.onAddMedia,
    this.isStreaming = false,
    this.onStop,
    this.selectedModel,
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
  };

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

  void _showOverlay(String trigger) {
    _hideOverlay();
    _currentTrigger = trigger;

    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final items = _options[trigger] ?? [];
        const double itemHeight = 44;
        final double totalHeight = (items.length * itemHeight + 16).clamp(
          0,
          400,
        );

        return Positioned(
          width: 300,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, -totalHeight - 12),
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(20),
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : Colors.black12,
                    width: 1.5,
                  ),
                ),
                constraints: BoxConstraints(maxHeight: totalHeight),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return _OptionTile(
                      label: item,
                      index: i + 1,
                      height: itemHeight,
                      onTap: () => _selectOption(item),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentTrigger = null;
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : Colors.black12,
              width: 1.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
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
                        ? const Color(0xFF0B1120)
                        : Colors.black.withAlpha(5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : Colors.black12,
                    ),
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
                    },
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                      decoration: InputDecoration(
                        hintText: widget.selectedModel != null
                            ? 'Message ${widget.selectedModel}'
                            : 'Message',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
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
                  final hasText = _controller.text.trim().isNotEmpty;
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
                  return IconButton(
                    onPressed: hasText ? _handleSend : null,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    iconSize: 22,
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: hasText
                          ? theme.colorScheme.primary
                          : Colors.grey.withAlpha(50),
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                },
              ),
            ],
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
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.index,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      leading: CircleAvatar(
        radius: 12,
        child: Text('$index', style: const TextStyle(fontSize: 10)),
      ),
      dense: true,
      onTap: onTap,
    );
  }
}
