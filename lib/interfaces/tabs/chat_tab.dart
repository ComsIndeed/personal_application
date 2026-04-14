import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:personal_application/theme/app_theme.dart';
import 'package:uuid/uuid.dart';
import 'package:personal_application/interfaces/widgets/chat_composer.dart';

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Chat(
        theme: isDark
            ? ChatTheme.fromThemeData(AppTheme.dark())
            : ChatTheme.fromThemeData(AppTheme.light()),
        currentUserId: 'user',
        chatController: _chatController,
        resolveUser: (id) async {
          return User(id: id);
        },
        builders: Builders(
          composerBuilder: (context) => Align(
            alignment: Alignment.bottomCenter,
            child: ChatComposer(
              onSend: (text) {
                _chatController.insertMessage(
                  TextMessage(id: Uuid().v4(), authorId: 'user', text: text),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
