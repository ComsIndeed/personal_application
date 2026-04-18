import 'package:flutter/material.dart';
import 'package:personal_application/core/models/message/enums.dart';

class RecommendedModel {
  final String name;
  final String description;
  final String modelId;
  final LLMProvider provider;
  final IconData icon;
  final Color color;

  RecommendedModel({
    required this.name,
    required this.description,
    required this.modelId,
    required this.provider,
    required this.icon,
    required this.color,
  });
}

class ModelRecommendationGrid extends StatelessWidget {
  final Function(LLMProvider, String) onModelSelected;
  final String? currentModelId;

  ModelRecommendationGrid({
    super.key,
    required this.onModelSelected,
    this.currentModelId,
  });

  final List<RecommendedModel> recommendedModels = [
    RecommendedModel(
      name: 'DeepSeek Chat',
      description: 'Versatile and snappy',
      modelId: 'deepseek-chat',
      provider: LLMProvider.deepseek,
      icon: Icons.chat_bubble_outline_rounded,
      color: const Color(0xFF60A5FA),
    ),
    RecommendedModel(
      name: 'DeepSeek Reasoner',
      description: 'Deep thought and logic',
      modelId: 'deepseek-reasoner',
      provider: LLMProvider.deepseek,
      icon: Icons.psychology_outlined,
      color: const Color(0xFF818CF8),
    ),
    RecommendedModel(
      name: 'GPT-OSS 120B',
      description: 'Massive open intelligence',
      modelId: 'openai/gpt-oss-120b',
      provider: LLMProvider.groq,
      icon: Icons.auto_awesome_outlined,
      color: const Color(0xFF2DD4BF),
    ),
    RecommendedModel(
      name: 'Kimi K2',
      description: 'Long-context specialist',
      modelId: 'moonshotai/kimi-k2',
      provider: LLMProvider.groq,
      icon: Icons.history_edu_rounded,
      color: const Color(0xFFFB923C),
    ),
    RecommendedModel(
      name: 'Llama 4 Scout',
      description: 'Strong multi-modal strength',
      modelId: 'meta-llama/llama-4-scout-17b-16e-instruct',
      provider: LLMProvider.groq,
      icon: Icons.visibility_outlined,
      color: const Color(0xFFA78BFA),
    ),

    RecommendedModel(
      name: 'Llama 8B',
      description: 'Ultra-fast efficiency',
      modelId: 'llama-3.1-8b-instant',
      provider: LLMProvider.groq,
      icon: Icons.bolt_rounded,
      color: const Color(0xFF4ADE80),
    ),
    RecommendedModel(
      name: 'Gemini 3 Flash',
      description: 'Instant frontier speed',
      modelId: 'gemini-3-flash',
      provider: LLMProvider.gemini,
      icon: Icons.flash_on_rounded,
      color: const Color(0xFFFBBF24),
    ),
    RecommendedModel(
      name: 'Compound',
      description: 'Groq\'s agentic MoE system',
      modelId: 'groq/compound',
      provider: LLMProvider.groq,
      icon: Icons.layers_outlined,
      color: const Color(0xFFF87171),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF60A5FA),
                    Color(0xFFA78BFA),
                    Color(0xFFF472B6),
                  ],
                ).createShader(bounds),
                child: Text(
                  'How can I help you today?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a specialized model to start a conversation',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),

                itemCount: recommendedModels.length,
                itemBuilder: (context, index) {
                  final model = recommendedModels[index];
                  final isSelected = currentModelId == model.modelId;

                  return _ModelCard(
                    model: model,
                    isSelected: isSelected,
                    onTap: () => onModelSelected(model.provider, model.modelId),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelCard extends StatefulWidget {
  final RecommendedModel model;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModelCard({
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ModelCard> createState() => _ModelCardState();
}

class _ModelCardState extends State<_ModelCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.model.color.withAlpha(isDark ? 40 : 20)
                : _isHovered
                ? (isDark ? Colors.white10 : Colors.black.withAlpha(10))
                : (isDark
                      ? Colors.white.withAlpha(5)
                      : Colors.black.withAlpha(5)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? widget.model.color
                  : _isHovered
                  ? widget.model.color.withAlpha(100)
                  : (isDark ? Colors.white10 : Colors.black12),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (_isHovered || widget.isSelected)
                BoxShadow(
                  color: widget.model.color.withAlpha(isDark ? 30 : 20),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.model.color.withAlpha(isDark ? 30 : 40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.model.icon,
                  size: 20,
                  color: widget.model.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.model.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.model.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
