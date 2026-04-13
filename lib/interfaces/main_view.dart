import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // To access WindowOverlayState

class MainView extends StatelessWidget {
  final bool isVisible;

  const MainView({super.key, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E).withValues(alpha: 0.92),
            border: Border(
              left: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(-10, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 48, 12, 12),
                child: Row(
                  children: [
                    const Icon(Icons.dashboard_rounded, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Quick Panel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () =>
                          context.read<WindowOverlayState>().close(),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),

              // Content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.widgets_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Side Panel Content',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ctrl + Shift + Space to toggle',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate(target: isVisible ? 1 : 0)
        .slideX(begin: 1, end: 0, curve: Curves.easeOutCubic, duration: 280.ms);
  }
}
