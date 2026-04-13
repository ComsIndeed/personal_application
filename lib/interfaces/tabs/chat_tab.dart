import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ChatMessage {
  final String id;
  final String text;
  final String authorId;
  final DateTime createdAt;
  final List<ToolCall>? toolCalls;

  ChatMessage({
    required this.id,
    required this.text,
    required this.authorId,
    required this.createdAt,
    this.toolCalls,
  });
}

class ToolCall {
  final String name;
  final String status; // 'running', 'done', 'error'
  ToolCall({required this.name, required this.status});
}

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      authorId: 'ai',
      text: 'Analyzing your workflow...',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      toolCalls: [
        ToolCall(name: 'list_dir', status: 'done'),
        ToolCall(name: 'grep_search', status: 'running'),
      ],
    ),
    ChatMessage(
      id: '2',
      authorId: 'user',
      text: 'Hey, can you help me with the new sprint?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _MessageBubble(message: message);
            },
          ),
        ),
        _buildInputArea(theme),
      ],
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: () {},
              color: theme.primaryColor,
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded),
              onPressed: () {},
              color: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAI = message.authorId == 'ai';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isAI
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) _Avatar(isAI: true),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: isAI
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isAI ? theme.cardColor : theme.primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isAI ? 0 : 16),
                      bottomRight: Radius.circular(isAI ? 16 : 0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isAI ? Colors.white : Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      if (message.toolCalls != null) ...[
                        const SizedBox(height: 12),
                        ...message.toolCalls!.map(
                          (tc) => _ToolCallChip(toolCall: tc),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: const TextStyle(fontSize: 10, color: Colors.white30),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!isAI) _Avatar(isAI: false),
        ],
      ),
    );
  }
}

class _ToolCallChip extends StatelessWidget {
  final ToolCall toolCall;
  const _ToolCallChip({required this.toolCall});

  @override
  Widget build(BuildContext context) {
    final isRunning = toolCall.status == 'running';
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: isRunning
                ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.blue),
                  )
                : const Icon(Icons.check_circle, size: 12, color: Colors.green),
          ),
          const SizedBox(width: 8),
          Text(
            toolCall.name,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isAI;
  const _Avatar({required this.isAI});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isAI ? Colors.indigo : Colors.white12,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isAI ? Icons.auto_awesome_rounded : Icons.person_rounded,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}
