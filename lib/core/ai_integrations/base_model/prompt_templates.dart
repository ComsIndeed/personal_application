class PromptTemplates {
  static String fullCapability(String extra) {
    return """
    $extra
    """;
  }

  static String readOnlyCapability(String extra) {
    return """
    $extra
    """;
  }
}
