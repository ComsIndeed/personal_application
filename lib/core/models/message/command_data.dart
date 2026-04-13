abstract class CommandData {
  Map<String, dynamic> toJson();

  static CommandData fromJson(Map<String, dynamic> json) {
    // Current implementation has no specific command data types
    return EmptyCommandData.fromJson(json);
  }
}

class EmptyCommandData extends CommandData {
  @override
  Map<String, dynamic> toJson() => {};

  static EmptyCommandData fromJson(Map<String, dynamic> json) =>
      EmptyCommandData();
}
