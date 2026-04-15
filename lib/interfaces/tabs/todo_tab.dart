import 'package:flutter/material.dart';

class TodoTab extends StatelessWidget {
  const TodoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No active sprints.',
        style: TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}
