import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flyer_chat_text_message/flyer_chat_text_message.dart';
import 'package:personal_application/interfaces/tabs/assistant_chat/assistant_chat_cubit.dart';
import 'package:personal_application/core/models/message/enums.dart';
import 'package:personal_application/core/models/message/message_part.dart';
import 'package:flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart'
    as flyer_stream;
import 'package:personal_application/theme/app_theme.dart';
import 'package:personal_application/interfaces/widgets/chat_composer.dart';
import 'package:personal_application/core/models/conversation.dart';
import 'package:personal_application/core/services/llm_service.dart';
import 'package:personal_application/core/services/tab_header_manager.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _chatController = chat_core.InMemoryChatController();
  List<Conversation> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHeader();
      _syncMessages(context.read<AssistantChatCubit>().state);
    });
  }

  Future<void> _loadConversations() async {
    final convos = await context.read<AssistantChatCubit>().getConversations();
    if (mounted) {
      setState(() => _conversations = convos);
      _updateHeader();
    }
  }

  void _updateHeader() {
    if (!mounted) return;
    final cubit = context.read<AssistantChatCubit>();
    final state = cubit.state;
    final header = context.read<TabHeaderManager>();

    final currentConvo = _conversations.firstWhere(
      (c) => c.id == state.currentConversationId,
      orElse: () => Conversation(
        id: state.currentConversationId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deleted: false,
      ),
    );

    header.update(
      title: currentConvo.title ?? 'New Conversation',
      actions: [
        _HeaderActionButton(
          icon: Icons.psychology_rounded,
          onPressed: () => _showModelMenu(context),
          tooltip: 'Select Model',
        ),
        _HeaderActionButton(
          icon: Icons.forum_rounded,
          onPressed: () => _showConversationMenu(context),
          tooltip: 'Conversations',
        ),
      ],
    );
  }

  void _showModelMenu(BuildContext context) async {
    final cubit = context.read<AssistantChatCubit>();
    final llm = LLMService();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<PopupMenuEntry<dynamic>> allItems = [];
    for (final provider in LLMProvider.values) {
      allItems.add(
        PopupMenuItem<dynamic>(
          enabled: false,
          child: Text(
            provider.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
      final items = await _getModelItems(provider, cubit, llm);
      allItems.addAll(items);
    }

    if (!context.mounted) return;

    showMenu<dynamic>(
      context: context,
      constraints: const BoxConstraints(maxHeight: 400, maxWidth: 220),
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200,
        80,
        20,
        0,
      ),
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: allItems,
    );
  }

  Future<List<PopupMenuEntry<dynamic>>> _getModelItems(
    LLMProvider provider,
    AssistantChatCubit cubit,
    LLMService llm,
  ) async {
    if (!llm.hasApiKey(provider)) {
      return [
        const PopupMenuItem<dynamic>(
          enabled: false,
          child: Text('API key missing', style: TextStyle(fontSize: 12)),
        ),
      ];
    }

    try {
      final models = await llm.listModels(provider);
      return models.map((m) {
        return PopupMenuItem<dynamic>(
          onTap: () => cubit.setModel(provider, m),
          child: Text(m, style: const TextStyle(fontSize: 13)),
        );
      }).toList();
    } catch (e) {
      return [
        PopupMenuItem<dynamic>(
          enabled: false,
          child: Text('Error: $e', style: const TextStyle(fontSize: 12)),
        ),
      ];
    }
  }

  void _showConversationMenu(BuildContext context) async {
    final cubit = context.read<AssistantChatCubit>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final convos = await cubit.getConversations();

    if (!context.mounted) return;

    showMenu<dynamic>(
      context: context,
      constraints: const BoxConstraints(maxHeight: 400, maxWidth: 220),
      position: const RelativeRect.fromLTRB(100, 80, 20, 0),
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem<dynamic>(
          onTap: () {
            cubit.startNewChat();
            _loadConversations();
          },
          child: const Row(
            children: [
              Icon(Icons.add_rounded, size: 18),
              SizedBox(width: 8),
              Text('New Chat'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...convos.map((c) {
          return PopupMenuItem<dynamic>(
            onTap: () {
              cubit.selectConversation(c.id);
              _loadConversations();
            },
            child: Text(
              c.title ?? 'Untitled',
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
    );
  }

  void _syncMessages(AssistantChatState state) {
    final uiMessages = state.messages.map<chat_core.Message>((m) {
      final text = m.parts.whereType<TextPart>().map((p) => p.text).join('\n');
      final reasoning = m.parts
          .whereType<ReasoningPart>()
          .map((p) => p.reasoning)
          .join('\n');
      final role = m.role == MessageRole.user ? 'user' : 'assistant';

      return chat_core.TextMessage(
        id: m.id,
        authorId: role,
        text: text,
        createdAt: m.createdAt,
        status: m.role == MessageRole.error
            ? chat_core.MessageStatus.error
            : null,
        metadata: reasoning.isNotEmpty ? {'reasoning': reasoning} : null,
      );
    }).toList();

    if (state.streamingText != null || state.streamingReasoning != null) {
      uiMessages.add(
        chat_core.TextStreamMessage(
          id: 'streaming-msg',
          authorId: 'assistant',
          streamId: 'streaming-msg',
          createdAt: DateTime.now(),
          metadata: state.streamingReasoning != null
              ? {'reasoning': state.streamingReasoning}
              : null,
        ),
      );
    }

    uiMessages.sort(
      (a, b) => (a.createdAt ?? DateTime.now()).compareTo(
        b.createdAt ?? DateTime.now(),
      ),
    );

    _chatController.setMessages(uiMessages, animated: false);
  }

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
      body: BlocListener<AssistantChatCubit, AssistantChatState>(
        listener: (context, state) {
          _syncMessages(state);
          _loadConversations();
        },
        child: BlocBuilder<AssistantChatCubit, AssistantChatState>(
          builder: (context, state) {
            return Chat(
              theme: isDark
                  ? chat_core.ChatTheme.fromThemeData(AppTheme.dark())
                  : chat_core.ChatTheme.fromThemeData(AppTheme.light()),
              currentUserId: 'user',
              chatController: _chatController,
              resolveUser: (id) async {
                return chat_core.User(id: id);
              },
              builders: chat_core.Builders(
                textStreamMessageBuilder:
                    (
                      context,
                      message,
                      index, {
                      required bool isSentByMe,
                      chat_core.MessageGroupStatus? groupStatus,
                    }) {
                      final reasoning =
                          message.metadata?['reasoning'] as String?;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (reasoning != null && reasoning.isNotEmpty)
                            _ReasoningBlock(
                              reasoning: reasoning,
                              isStreaming: message.id == 'streaming-msg',
                            ),
                          flyer_stream.FlyerChatTextStreamMessage(
                            mode: .instantMarkdown,
                            message: message,
                            index: index,
                            streamState: flyer_stream.StreamStateStreaming(
                              context
                                      .read<AssistantChatCubit>()
                                      .state
                                      .streamingText ??
                                  '',
                            ),
                          ),
                        ],
                      );
                    },
                textMessageBuilder:
                    (
                      context,
                      message,
                      index, {
                      required bool isSentByMe,
                      chat_core.MessageGroupStatus? groupStatus,
                    }) {
                      final reasoning =
                          message.metadata?['reasoning'] as String?;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (reasoning != null && reasoning.isNotEmpty)
                            _ReasoningBlock(
                              reasoning: reasoning,
                              isStreaming: message.id == 'streaming-msg',
                            ),
                          FlyerChatTextMessage(message: message, index: index),
                        ],
                      );
                    },
                composerBuilder: (context) => Align(
                  alignment: Alignment.bottomCenter,
                  child: ChatComposer(
                    selectedModel: state.model,
                    isStreaming: state.isStreaming,
                    onStop: () =>
                        context.read<AssistantChatCubit>().stopGeneration(),
                    onSend: (text) {
                      context.read<AssistantChatCubit>().sendMessage(text);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReasoningBlock extends StatefulWidget {
  final String reasoning;
  final bool isStreaming;

  const _ReasoningBlock({required this.reasoning, this.isStreaming = false});

  @override
  State<_ReasoningBlock> createState() => _ReasoningBlockState();
}

class _ReasoningBlockState extends State<_ReasoningBlock> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withAlpha(100)
            : Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thought Process',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (widget.isStreaming)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.blue),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                widget.reasoning,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _HeaderActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 4, top: 12),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          foregroundColor: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }
}
