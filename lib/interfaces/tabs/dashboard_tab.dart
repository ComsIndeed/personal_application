import 'package:flutter/material.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Canvas LMS - Upcoming',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildAssignmentCard(
          'CS301: Data Structures',
          'Final Project',
          'Due: Friday, 11:59 PM',
        ),
        _buildAssignmentCard(
          'MATH204: Calculus II',
          'Problem Set 8',
          'Due: Monday, 9:00 AM',
        ),
        _buildAssignmentCard(
          'ENG102: Literature',
          'Draft Essay',
          'Due: Tomorrow, 5:00 PM',
        ),
      ],
    );
  }

  Widget _buildAssignmentCard(String course, String title, String due) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course,
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(due, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
