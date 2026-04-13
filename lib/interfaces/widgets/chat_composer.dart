import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
            // Add Media Button
            IconButton(
              onPressed: widget.onAddMedia,
              icon: const Icon(Icons.add_rounded),
              iconSize: 26,
              color: theme.colorScheme.primary,
              tooltip: 'Add media',
            ),

            const SizedBox(width: 4),

            // Text Input Layer
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(15)
                      : Colors.black.withAlpha(10),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 5,
                  minLines: 1,
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
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send Button
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
    );
  }
}
