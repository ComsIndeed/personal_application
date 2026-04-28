import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

/// A callback that receives the current markdown string when autosave fires.
typedef MarkdownSaveCallback = Future<void> Function(String markdown);

/// An editable AppFlowy-backed markdown editor with cooldown-based autosave.
class NoteMarkdownEditor extends StatefulWidget {
  const NoteMarkdownEditor({
    super.key,
    required this.initialMarkdown,
    required this.onSave,
    this.readOnly = false,
    this.placeholder = 'Write something...',
    this.saveCooldown = const Duration(milliseconds: 1500),
    this.loopInterval = const Duration(milliseconds: 300),
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    this.shrinkWrap = false,
    this.isCard = false,
  });

  final String initialMarkdown;
  final MarkdownSaveCallback onSave;
  final bool readOnly;
  final String placeholder;
  final Duration saveCooldown;
  final Duration loopInterval;
  final EdgeInsets padding;
  final bool shrinkWrap;
  final bool isCard;

  @override
  State<NoteMarkdownEditor> createState() => _NoteMarkdownEditorState();
}

class _NoteMarkdownEditorState extends State<NoteMarkdownEditor> {
  late EditorState _editorState;
  StreamSubscription? _transactionSub;
  Timer? _loopTimer;

  bool _isDirty = false;
  DateTime? _lastEditTime;

  @override
  void initState() {
    super.initState();
    _initEditor(widget.initialMarkdown);
    if (!widget.readOnly) _startAutosaveLoop();
  }

  void _initEditor(String markdown) {
    final document = markdown.trim().isEmpty
        ? EditorState.blank(withInitialText: true).document
        : markdownToDocument(markdown);

    _editorState = EditorState(document: document);

    if (!widget.readOnly) {
      _transactionSub = _editorState.transactionStream.listen((_) {
        _isDirty = true;
        _lastEditTime = DateTime.now();
      });
    }
  }

  void _startAutosaveLoop() {
    _loopTimer?.cancel();
    _loopTimer = Timer.periodic(widget.loopInterval, (_) async {
      if (!_isDirty) return;
      final lastEdit = _lastEditTime;
      if (lastEdit == null) return;
      if (DateTime.now().difference(lastEdit) < widget.saveCooldown) return;

      // Cooldown elapsed – commit the save.
      _isDirty = false;
      _lastEditTime = null;
      final markdown = documentToMarkdown(_editorState.document);
      await widget.onSave(markdown);
    });
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _transactionSub?.cancel();
    // Flush any unsaved dirty state on widget removal.
    if (_isDirty) {
      final markdown = documentToMarkdown(_editorState.document);
      widget.onSave(markdown);
    }
    _editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final editorStyle = EditorStyle.desktop(
      padding: widget.padding,
      cursorColor: theme.colorScheme.primary,
      selectionColor: theme.colorScheme.primary.withAlpha(60),
      textStyleConfiguration: TextStyleConfiguration(
        text: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        bold: const TextStyle(fontWeight: FontWeight.bold),
        italic: const TextStyle(fontStyle: FontStyle.italic),
        href: TextStyle(
          color: isDark ? Colors.blueAccent : Colors.blue,
          decoration: TextDecoration.underline,
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1),
          backgroundColor: isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFE0F2FE),
        ),
        strikethrough: const TextStyle(decoration: TextDecoration.lineThrough),
        underline: const TextStyle(decoration: TextDecoration.underline),
      ),
    );

    return AppFlowyEditor(
      editorState: _editorState,
      editorStyle: editorStyle,
      shrinkWrap: widget.shrinkWrap,
      editable: !widget.readOnly,
      blockComponentBuilders: widget.isCard
          ? {
              ...standardBlockComponentBuilderMap,
              HeadingBlockKeys.type: HeadingBlockComponentBuilder(
                textStyleBuilder: (level) {
                  final fontSizes = [18.0, 16.0, 15.0, 14.0, 14.0, 14.0];
                  return TextStyle(
                    fontSize: fontSizes.elementAtOrNull(level - 1) ?? 14.0,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  );
                },
                configuration: BlockComponentConfiguration(
                  padding: (node) => const EdgeInsets.symmetric(vertical: 2.0),
                ),
              ),
              ParagraphBlockKeys.type: ParagraphBlockComponentBuilder(
                configuration: BlockComponentConfiguration(
                  padding: (node) => const EdgeInsets.symmetric(vertical: 2.0),
                ),
              ),
              TodoListBlockKeys.type: TodoListBlockComponentBuilder(
                configuration: BlockComponentConfiguration(
                  padding: (node) => const EdgeInsets.symmetric(vertical: 2.0),
                ),
              ),
              BulletedListBlockKeys.type: BulletedListBlockComponentBuilder(
                configuration: BlockComponentConfiguration(
                  padding: (node) => const EdgeInsets.symmetric(vertical: 2.0),
                ),
              ),
              NumberedListBlockKeys.type: NumberedListBlockComponentBuilder(
                configuration: BlockComponentConfiguration(
                  padding: (node) => const EdgeInsets.symmetric(vertical: 2.0),
                ),
              ),
            }
          : null,
    );
  }
}
