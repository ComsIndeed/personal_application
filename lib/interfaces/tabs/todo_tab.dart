import 'package:flutter/material.dart';

class TodoTab extends StatelessWidget {
  const TodoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSprintHeader('Current Sprint: Focus Week'),
        _buildTodoItem('Morning Reading', 'Low Energy', Colors.green),
        _buildTodoItem('Code Refactor', 'High Energy', Colors.red),
        _buildTodoItem('Email Cleanup', 'Medium Energy', Colors.orange),
        _buildTodoItem('Bug Hunting', 'High Energy', Colors.red),
        _buildTodoItem('Update Documentation', 'Low Energy', Colors.green),
        const SizedBox(height: 24),
        _buildSprintHeader('Next Sprint: Prep Phase'),
        _buildTodoItem('Design Mockups', 'High Energy', Colors.red),
        _buildTodoItem('Grocery Shopping', 'Medium Energy', Colors.orange),
        _buildTodoItem('Planning Meeting', 'Medium Energy', Colors.orange),
        _buildTodoItem('Exercise', 'High Energy', Colors.red),
        _buildTodoItem('Meditation', 'Low Energy', Colors.green),
        _buildTodoItem('Call Parents', 'Low Energy', Colors.green),
        _buildTodoItem('Clean Desk', 'Medium Energy', Colors.orange),
        _buildTodoItem('Market Research', 'High Energy', Colors.red),
        _buildTodoItem('UI Polishing', 'Medium Energy', Colors.orange),
      ],
    );
  }

  Widget _buildSprintHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTodoItem(String task, String energy, Color energyColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(task),
        subtitle: Text(
          energy,
          style: TextStyle(color: energyColor, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.circle_outlined, size: 20),
      ),
    );
  }
}
