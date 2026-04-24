import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';

/// DO NOT DELETE
///
/// For displaiying the current LLM work. Not necessarily message, but more like their output anad progress, multipurpose.
/// - No text given yet, must indicate via placeholder text (see common.dart)
/// - Running actions, must show with indicators (but toggleable)
/// - Thinking, must show (but toggleable)
/// - Errors, must be shown
/// - Any streaming text, must be streamed
/// - Must have indication if generating (something with the box)
/// - Must have indication if done generating (static box)
///
/// This is basically a multipurpose widget for displaying:
/// - The result of interpretations in brain dump
/// - Model comments on whatever
///

class LiveContentBox extends StatefulWidget {
  const LiveContentBox({
    super.key,
    required this.llmStream,
    this.width,
    this.height,
  });

  final Stream<String> llmStream;
  final double? width;
  final double? height;

  @override
  State<LiveContentBox> createState() => _LiveContentBoxState();
}

class _LiveContentBoxState extends State<LiveContentBox> {
  late final JsonStreamParser jsonStream;

  @override
  void initState() {
    super.initState();
    jsonStream = JsonStreamParser(widget.llmStream);
  }

  @override
  Widget build(BuildContext context) {
    return _buildContainerWrapper(
      providedWidth: widget.width,
      providedHeight: widget.height,
      child: const Placeholder(),
    );
  }

  Widget _buildContainerWrapper({
    required double? providedWidth,
    required double? providedHeight,
    required Widget child,
  }) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: SizedBox(
          width: providedWidth,
          height: providedHeight,
          child: child,
        ),
      ),
    );
  }
}
