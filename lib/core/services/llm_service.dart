import 'package:openai_dart/openai_dart.dart' as openai;
import 'package:personal_application/core/database/app_database.dart';
import 'package:personal_application/core/models/message/enums.dart';
import 'package:personal_application/core/models/message/message_part.dart';
import 'package:personal_application/core/services/app_prefs.dart';

class LLMService {
  final AppPrefs _prefs = AppPrefs();

  openai.OpenAIClient _getClient(LLMProvider provider) {
    String baseUrl;
    String apiKey;

    switch (provider) {
      case LLMProvider.groq:
        baseUrl = 'https://api.groq.com/openai/v1';
        apiKey = _prefs.groqApiKey;
        break;
      case LLMProvider.gemini:
        baseUrl = 'https://generativelanguage.googleapis.com/v1beta/openai/';
        apiKey = _prefs.geminiApiKey;
        break;
      case LLMProvider.deepseek:
        baseUrl = 'https://api.deepseek.com';
        apiKey = _prefs.deepSeekApiKey;
        break;
    }

    return openai.OpenAIClient(
      config: openai.OpenAIConfig(
        authProvider: openai.ApiKeyProvider(apiKey),
        baseUrl: baseUrl,
      ),
    );
  }

  openai.ChatMessage _mapToOpenAI(Message message) {
    final text = message.parts
        .whereType<TextPart>()
        .map((p) => p.text)
        .join('\n');

    final parts = message.parts.map((part) {
      if (part is TextPart) {
        return openai.ContentPart.text(part.text);
      } else if (part is AssetPart) {
        // TODO: Fetch real URL or base64 from asset_items table
        return openai.ContentPart.text('[Asset: ${part.assetId}]');
      }
      return openai.ContentPart.text('');
    }).toList();

    return switch (message.role) {
      MessageRole.user => openai.ChatMessage.user(parts),
      MessageRole.model => openai.ChatMessage.assistant(content: text),
      MessageRole.system => openai.ChatMessage.system(text),
    };
  }

  Future<String> generateContent({
    required List<Message> history,
    required LLMProvider provider,
    required String model,
  }) async {
    final client = _getClient(provider);
    try {
      final response = await client.chat.completions.create(
        openai.ChatCompletionCreateRequest(
          model: model,
          messages: history.map(_mapToOpenAI).toList(),
        ),
      );
      return response.text ?? '';
    } finally {
      client.close();
    }
  }

  Stream<String> generateContentStream({
    required List<Message> history,
    required LLMProvider provider,
    required String model,
  }) async* {
    final client = _getClient(provider);
    try {
      final stream = client.chat.completions.createStream(
        openai.ChatCompletionCreateRequest(
          model: model,
          messages: history.map(_mapToOpenAI).toList(),
        ),
      );
      yield* stream.textDeltas();
    } finally {
      client.close();
    }
  }

  Future<List<String>> listModels(LLMProvider provider) async {
    final client = _getClient(provider);
    try {
      final models = await client.models.list();
      return models.data.map((m) => m.id).toList();
    } finally {
      client.close();
    }
  }
}
