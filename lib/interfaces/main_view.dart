import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // To access WindowOverlayState

class MainView extends StatelessWidget {
  final bool isVisible;

  const MainView({super.key, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child:
          Container(
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
                ),
                child: _buildContent(),
              )
              .animate(target: isVisible ? 1 : 0)
              .slideX(
                begin: 1,
                end: 0,
                curve: Curves.easeOutCubic,
                duration: 280.ms,
              ),
    );
  }

  Widget _buildContent() {
    return Column(children: [
                ],
              );
  }
}
