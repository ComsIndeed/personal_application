import 'package:flutter/cupertino.dart';
import 'package:personal_application/core/ai_integrations/widgets/live_content_box.dart';
import 'package:personal_application/core/models/common_note_item.dart';

enum NoteActionType { fast, vision, fastVision }

class BraindumpAiIntegration {
  String get _interpretNotePrompt {
    return """
    The user is provided a braindump interface where they can submit any text and images.
    The note from the user may or may not be vague, incomplete, or ambiguous. 
    You are to interpret the note based on the provided contexts and form a more complete and structured note.
    Your response must be in JSON:

    - 
    """;
  }

  /// Get the interpretation of the note (supposedly from braindump)
  /// - If image, use any vision
  /// - If smart disabled, use a fast model
  ///
  /// Method would immediately return a displayable widget.
  /// To be used on the braindump notes list.
  /// Would be utilizing LiveContentBox.
  ///
  /// This widget would basically:
  /// - Take the note the user wants to deal with
  /// - Make an LLM generate via the prompt above
  /// - Parse the streaming JSON, display result nicely
  /// - When done, persist
  ///
  /// ! Do not delete this description
  // Widget getInterpretation({
  //   required CommonNoteItem note,
  //   required NoteActionType type,
  // }) {
  //   return const LiveContentBox();
  // }
}
