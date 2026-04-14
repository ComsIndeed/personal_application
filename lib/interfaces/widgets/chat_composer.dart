import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:provider/provider.dart';

class ChatComposer extends StatefulWidget {
  final Function(String text) onSend;
  final VoidCallback? onAddMedia;

  const ChatComposer({super.key, required this.onSend, this.onAddMedia});

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
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    // Height calculation:
    // Header: 32px
    // Item: 36px * 10.5 = 378px
    // Total: ~410px
    const double itemHeight = 36.0;
    const double headerHeight = 36.0;
    const double totalHeight = headerHeight + (itemHeight * 10.5);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -totalHeight),
          child: Material(
            elevation: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            color: Theme.of(context).cardColor,
            child: Container(
              height: totalHeight,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(color: Colors.white10),
                  left: BorderSide(color: Colors.white10),
                  right: BorderSide(color: Colors.white10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: headerHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      trigger == '@' ? 'MENTIONS' : 'COMMANDS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(180),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _options[trigger]!.length,
                      itemBuilder: (context, i) {
                        return _OptionTile(
                          label: _options[trigger]![i],
                          index: i + 1,
                          height: itemHeight,
                          onTap: () => _selectOption(_options[trigger]![i]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() {});
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
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
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
                  final hasText = _controller.text.trim().isNotEmpty;
                  return IconButton(
                    onPressed: hasText ? _handleSend : null,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    iconSize: 24,
                    color: hasText ? Colors.white : Colors.grey.withAlpha(100),
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
    if (_currentTrigger != null) {
      final list = _options[_currentTrigger]!;
      if (index < list.length) {
        _selectOption(list[index]);
      }
    }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(10)
                        : Colors.black.withAlpha(5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white.withAlpha(200) : Colors.black,
                  ),
                ),
                if (index <= 10)
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
