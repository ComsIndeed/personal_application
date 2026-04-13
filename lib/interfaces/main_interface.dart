import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/widgets/interface_container.dart';
import '../theme/app_theme.dart';
import 'tabs/chat_tab.dart';
import 'tabs/todo_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/notes_tab.dart';
import 'widgets/main_nav_tabs.dart';

class TabIntent extends Intent {
  final int index;
  const TabIntent(this.index);
}

class MainInterface extends StatefulWidget {
  final bool isVisible;

  const MainInterface({super.key, required this.isVisible});

  @override
  State<MainInterface> createState() => _MainInterfaceState();
}

class _MainInterfaceState extends State<MainInterface> {
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(MainInterface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: InterfaceContainer(
        isVisible: widget.isVisible,
        outerBuilder: (context, controller, container) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Floating Tab Navigation
              const MainNavTabs(),
              // Main Animated Container
              SizedBox(width: 420, child: container),
            ],
          );
        },
        builder: (context, controller) {
          final tabController = DefaultTabController.of(context);

          return Focus(
            focusNode: _focusNode,
            autofocus: true,
            child: Shortcuts(
              shortcuts: <ShortcutActivator, Intent>{
                const SingleActivator(LogicalKeyboardKey.digit1, alt: true):
                    const TabIntent(0),
                const SingleActivator(LogicalKeyboardKey.digit2, alt: true):
                    const TabIntent(1),
                const SingleActivator(LogicalKeyboardKey.digit3, alt: true):
                    const TabIntent(2),
                const SingleActivator(LogicalKeyboardKey.digit4, alt: true):
                    const TabIntent(3),
                const SingleActivator(LogicalKeyboardKey.digit5, alt: true):
                    const TabIntent(4),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  TabIntent: CallbackAction<TabIntent>(
                    onInvoke: (intent) {
                      tabController.animateTo(intent.index);
                      return null;
                    },
                  ),
                },
                child: Column(
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: ListenableBuilder(
                            listenable: tabController,
                            builder: (context, _) {
                              final titles = [
                                'Assistant',
                                'Sprints',
                                'Notes',
                                'Dashboard',
                                'Settings',
                              ];
                              return Text(
                                titles[tabController.index],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              );
                            },
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
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.05,
                              ),
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
                          NotesTab(),
                          DashboardTab(),
                          SettingsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
