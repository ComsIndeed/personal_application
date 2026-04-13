import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/widgets/interface_container.dart';
import '../theme/app_theme.dart';

class MainInterface extends StatelessWidget {
  final bool isVisible;

  const MainInterface({super.key, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return InterfaceContainer(
      isVisible: isVisible,
      builder: (context, controller) {
        return Column(
          children: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    'Quick Panel',
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
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
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

            const Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: Colors.white10,
            ),

            // Main Content Area
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildQuickAction(Icons.search_rounded, 'Search Everything'),
                  _buildQuickAction(Icons.settings_suggest_rounded, 'Settings'),
                  _buildQuickAction(Icons.history_rounded, 'Recent Activities'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {},
    );
  }
}
