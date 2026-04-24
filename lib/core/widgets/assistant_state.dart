import 'package:flutter/material.dart';
import '../constants/app_tab_id.dart';

class AssistantState {
  final Set<AppTabId> openIds;
  final VoidCallback onToggle;
  AssistantState({required this.openIds, required this.onToggle});
}
