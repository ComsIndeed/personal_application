import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:personal_application/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _chatController = InMemoryChatController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Chat(
      theme: isDark
          ? ChatTheme.fromThemeData(AppTheme.dark())
          : ChatTheme.fromThemeData(AppTheme.light()),
      currentUserId: 'user',
      chatController: _chatController,
      resolveUser: (id) async {
        return User(id: id);
      },
      onMessageSend: (text) {
        _chatController.insertMessage(
          TextMessage(id: Uuid().v4(), authorId: 'user', text: text),
        );
      },
    );
  }
}
