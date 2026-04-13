import 'package:flutter/material.dart';

class NotesTab extends StatelessWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        const Text(
          'Quick Notes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildNoteCard(
          'Project Ideas',
          'Build a vertical navigation system...',
        ),
        _buildNoteCard('Reminders', 'Buy more coffee, fix the overflow bug...'),
        _buildNoteCard(
          'Meeting Notes',
          'User requested Alt shortcuts for navigation.',
        ),
        _buildNoteCard(
          'Drafts',
          'The quick brown fox jumps over the lazy dog.',
        ),
        _buildNoteCard(
          'Code Snippets',
          'DefaultTabController.of(context).animateTo(index);',
        ),
      ],
    );
  }

  Widget _buildNoteCard(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
