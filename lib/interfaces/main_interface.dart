import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/widgets/interface_container.dart';
import '../theme/app_theme.dart';
import 'tabs/chat_tab.dart';
import 'tabs/todo_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/settings_tab.dart';
import 'widgets/main_nav_tabs.dart';

class MainInterface extends StatelessWidget {
  final bool isVisible;

  const MainInterface({super.key, required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: InterfaceContainer(
        isVisible: isVisible,
        outerBuilder: (context, controller, container) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Floating Tab Navigation (Now within hit-test bounds)
              const MainNavTabs(),
              // Main Animated Container (Fixed width to avoid jumping)
              SizedBox(width: 420, child: container),
            ],
          );
        },
        builder: (context, controller) {
          return Column(
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

              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: Colors.white10,
              ),

              // Main Content Area
              const Expanded(
                child: VerticalTabBarView(
                  children: [
                    ChatTab(),
                    TodoTab(),
                    DashboardTab(),
                    SettingsTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class VerticalTabBarView extends StatefulWidget {
  final List<Widget> children;
  const VerticalTabBarView({super.key, required this.children});

  @override
  State<VerticalTabBarView> createState() => _VerticalTabBarViewState();
}

class _VerticalTabBarViewState extends State<VerticalTabBarView> {
  late PageController _pageController;
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newTabController = DefaultTabController.of(context);
    if (newTabController != _tabController) {
      _tabController?.removeListener(_handleTabSelection);
      _tabController = newTabController;
      _tabController?.addListener(_handleTabSelection);
      _pageController = PageController(initialPage: _tabController?.index ?? 0);
    }
  }

  void _handleTabSelection() {
    if (_tabController != null && _tabController!.indexIsChanging) {
      _pageController.animateToPage(
        _tabController!.index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabSelection);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: const NeverScrollableScrollPhysics(),
      children: widget.children,
    );
  }
}
