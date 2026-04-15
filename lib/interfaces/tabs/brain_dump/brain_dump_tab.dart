import 'package:flutter/material.dart';
import 'brain_dump_input.dart';

class BrainDumpTab extends StatefulWidget {
  const BrainDumpTab({super.key});

  @override
  State<BrainDumpTab> createState() => _BrainDumpTabState();
}

class _BrainDumpTabState extends State<BrainDumpTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Content Area (Clean)
        const Expanded(
          child: Center(
            child: Opacity(
              opacity: 0.2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology_outlined, size: 64),
                  SizedBox(height: 16),
                  Text('Ready for a brain dump?'),
                ],
              ),
            ),
          ),
        ),
        // Input Interface
        const BrainDumpInput(),
      ],
    );
  }
}
