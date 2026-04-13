import 'package:flutter/material.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
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
        _buildAssignmentCard(
          'HIST101: History',
          'Primary Source Analysis',
          'Due: Wednesday, 11:59 PM',
        ),
        _buildAssignmentCard(
          'PHYS201: Physics',
          'Lab Report #4',
          'Due: Next Tuesday, 10:00 AM',
        ),
        _buildAssignmentCard(
          'ART210: Digital Art',
          'Midterm Portfolio',
          'Due: Last Week (Late)',
        ),
        _buildAssignmentCard(
          'SPAN101: Spanish',
          'Oral Exam Prep',
          'Due: Saturday',
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
