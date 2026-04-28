import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:personal_application/core/widgets/asset_preview_widget.dart';

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
              ImageBlockKeys.type: _AssetImageBlockComponentBuilder(
                configuration: BlockComponentConfiguration(
                  padding: (node) => const EdgeInsets.symmetric(vertical: 8.0),
                ),
              ),
            }
          : {
              ...standardBlockComponentBuilderMap,
              ImageBlockKeys.type: _AssetImageBlockComponentBuilder(
                configuration: BlockComponentConfiguration(
                  padding: (node) => const EdgeInsets.symmetric(vertical: 8.0),
                ),
              ),
            },
    );
  }
}

class _AssetImageBlockComponentBuilder extends ImageBlockComponentBuilder {
  _AssetImageBlockComponentBuilder({super.configuration});

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    final url = node.attributes[ImageBlockKeys.url] as String? ?? '';
    final guidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    if (guidPattern.hasMatch(url)) {
      return _AssetImageBlockComponentWidget(
        node: node,
        configuration: configuration,
      );
    }

    return super.build(blockComponentContext);
  }
}

class _AssetImageBlockComponentWidget extends BlockComponentStatefulWidget {
  const _AssetImageBlockComponentWidget({
    required super.node,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<_AssetImageBlockComponentWidget> createState() =>
      _AssetImageBlockComponentWidgetState();
}

class _AssetImageBlockComponentWidgetState
    extends State<_AssetImageBlockComponentWidget>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  late final editorState = Provider.of<EditorState>(context, listen: false);

  @override
  Widget build(BuildContext context) {
    final url = node.attributes[ImageBlockKeys.url] as String;
    final width = node.attributes[ImageBlockKeys.width]?.toDouble();

    Widget child = Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(maxHeight: 400),
      child: AssetPreviewWidget(assetId: url, cacheWidth: width?.toInt()),
    );

    child = Padding(padding: padding, child: child);

    return BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      remoteSelection: editorState.remoteSelections,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [BlockSelectionType.block],
      child: child,
    );
  }

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({bool shiftWithBaseOffset = false}) {
    return Offset.zero & (context.findRenderObject() as RenderBox).size;
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return Rect.fromLTWH(0, 0, box.size.width, box.size.height);
  }

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return [];
    return [Offset.zero & box.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) =>
      Selection.single(path: widget.node.path, startOffset: 0, endOffset: 1);

  @override
  Offset localToGlobal(Offset offset, {bool shiftWithBaseOffset = false}) {
    return (context.findRenderObject() as RenderBox).localToGlobal(offset);
  }
}
