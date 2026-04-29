enum NoteActionType { fast, vision, fastVision }

class BraindumpAiIntegration {
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
