import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:uuid/uuid.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  late final core.InMemoryChatController _chatController;
  final String _currentUserId = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _chatController = core.InMemoryChatController(
      messages: [
        core.Message.text(
          id: const Uuid().v4(),
          authorId: 'user',
          text: 'Hey AI, give me some motivational advice.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        core.Message.text(
          id: const Uuid().v4(),
          authorId: 'ai',
          text:
              'Focus on the process, not just the outcome. Small daily wins build monumental success over time!',
          createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
        core.Message.text(
          id: const Uuid().v4(),
          authorId: 'user',
          text: 'What should I work on next?',
          createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
        core.Message.text(
          id: const Uuid().v4(),
          authorId: 'ai',
          text: 'Your current sprint says "Code Refactor". It has high energy.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
        core.Message.text(
          id: const Uuid().v4(),
          authorId: 'ai',
          text: 'Hello! How can I help you today?',
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chat(
      currentUserId: _currentUserId,
      chatController: _chatController,
      resolveUser: (userId) async {
        if (userId == 'ai') {
          return const core.User(id: 'ai', name: 'AI');
        }
        return core.User(id: userId, name: 'User');
      },
      theme: core.ChatTheme.fromThemeData(theme).copyWith(
        colors: core.ChatColors.fromThemeData(theme).copyWith(
          surface: Colors.transparent,
          surfaceContainer: theme.colorScheme.surfaceContainer,
          surfaceContainerLow: theme.colorScheme.surfaceContainerLow,
          surfaceContainerHigh: theme.colorScheme.surfaceContainerHigh,
        ),
      ),
    );
  }
}
