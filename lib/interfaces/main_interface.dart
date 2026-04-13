import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/widgets/interface_container.dart';
import '../theme/app_theme.dart';
import 'tabs/chat_tab.dart';
import 'tabs/todo_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/settings_tab.dart';

class MainInterface extends StatelessWidget {
  final bool isVisible;

  const MainInterface({super.key, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return InterfaceContainer(
      isVisible: isVisible,
      builder: (context, controller) {
        return DefaultTabController(
          length: 4,
          child: Column(
            children: [
              Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      'Universal Hub',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 4, top: 12),
                    child: Consumer<ThemeController>(
                      builder: (context, theme, _) {
                        return IconButton(
                          icon: Icon(
                            theme.isDarkMode
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            size: 20,
                          ),
                          onPressed: theme.toggleTheme,
                          tooltip: 'Toggle Theme',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.05,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 12),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: controller.close,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        hoverColor: Colors.red.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ],
              ),

              const TabBar(
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(
                    text: 'AI',
                    icon: Icon(Icons.chat_bubble_outline, size: 20),
                  ),
                  Tab(
                    text: 'Tasks',
                    icon: Icon(Icons.check_circle_outline, size: 20),
                  ),
                  Tab(
                    text: 'School',
                    icon: Icon(Icons.school_outlined, size: 20),
                  ),
                  Tab(text: 'User', icon: Icon(Icons.person_outline, size: 20)),
                ],
              ),

              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: Colors.white10,
              ),

              // Main Content Area
              const Expanded(
                child: TabBarView(
                  children: [
                    ChatTab(),
                    TodoTab(),
                    DashboardTab(),
                    SettingsTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
