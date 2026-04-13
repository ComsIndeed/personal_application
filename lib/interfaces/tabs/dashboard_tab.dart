import 'package:flutter/material.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No active dashboard widgets.',
        style: TextStyle(color: Colors.white30),
      ),
    );
  }
}
