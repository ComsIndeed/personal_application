import 'package:flutter/material.dart';

class NotesTab extends StatelessWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No notes yet.', style: TextStyle(color: Colors.white30)),
    );
  }
}
