import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/widgets/interface_container.dart';
import '../theme/app_theme.dart';
import 'tabs/assistant_chat/chat_tab.dart';
import 'tabs/todo_tab.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/notes_tab.dart';
import 'tabs/brain_dump/brain_dump_tab.dart';
import 'tabs/utilities_tab.dart';
import 'widgets/main_nav_tabs.dart';
import '../core/services/tab_header_manager.dart';
import '../core/services/sync_service.dart';
import '../core/database/app_database.dart';

class TabIntent extends Intent {
  final int index;
  const TabIntent(this.index);
}

class HideIntent extends Intent {
  const HideIntent();
}

class MainInterface extends StatefulWidget {
  final bool isVisible;

  const MainInterface({super.key, required this.isVisible});

  @override
  State<MainInterface> createState() => _MainInterfaceState();
}

class _MainInterfaceState extends State<MainInterface> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Start listening for auth changes to manage SyncService
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn || session != null) {
        SyncService().start(context.read<AppDatabase>());
      } else if (event == AuthChangeEvent.signedOut) {
        SyncService().stop();
      }
    });

    // Check initial state
    if (Supabase.instance.client.auth.currentSession != null) {
      SyncService().start(context.read<AppDatabase>());
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabHeaderManager()),
        ChangeNotifierProvider(create: (_) => ComposerHeightNotifier()),
      ],
      child: DefaultTabController(
        length: 7, // Increased to 7 for Utilities
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

            return Shortcuts(
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
                const SingleActivator(LogicalKeyboardKey.digit6, alt: true):
                    const TabIntent(5),
                const SingleActivator(LogicalKeyboardKey.digit7, alt: true):
                    const TabIntent(6),
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
                child: Focus(
                  autofocus: true,
                  includeSemantics: false,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20, // Restored right padding for consistent gap
                                10,
                              ),
                              child: Consumer<TabHeaderManager>(
                                builder: (context, header, _) {
                                  return ListenableBuilder(
                                    listenable: tabController,
                                    builder: (context, _) {
                                      final defaultTitles = [
                                        'Assistant',
                                        'Brain Dump',
                                        'Sprints',
                                        'Notes',
                                        'Dashboard',
                                        'Settings',
                                        'Utilities',
                                      ];
                                      return Text(
                                        header.title ??
                                            defaultTitles[tabController.index],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          Consumer<TabHeaderManager>(
                            builder: (context, header, _) {
                              if (header.actions != null &&
                                  header.actions!.isNotEmpty) {
                                return Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: header.actions!,
                                  ),
                                );
                              }
                              return const Spacer();
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 4, top: 12),
                            child: Consumer<ThemeController>(
                              builder: (context, theme, _) {
                                return MenuAnchor(
                                  builder: (context, controller, child) {
                                    return IconButton(
                                      icon: const Icon(
                                        Icons.menu_rounded,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        if (controller.isOpen) {
                                          controller.close();
                                        } else {
                                          controller.open();
                                        }
                                      },
                                      tooltip: 'Options',
                                      style: IconButton.styleFrom(
                                        backgroundColor: theme.isDarkMode
                                            ? Colors.white.withValues(
                                                alpha: 0.05,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                      ),
                                    );
                                  },
                                  menuChildren: [
                                    MenuItemButton(
                                      leadingIcon: Icon(
                                        theme.isDarkMode
                                            ? Icons.light_mode_rounded
                                            : Icons.dark_mode_rounded,
                                        size: 18,
                                      ),
                                      onPressed: theme.toggleTheme,
                                      child: Text(
                                        theme.isDarkMode
                                            ? 'Light Mode'
                                            : 'Dark Mode',
                                      ),
                                    ),
                                    MenuItemButton(
                                      leadingIcon: const Icon(
                                        Icons.settings_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        tabController.animateTo(5); // Settings
                                      },
                                      child: const Text('Settings'),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12, top: 12),
                            child: IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                              onPressed: controller.close,
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05),
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
                            BrainDumpTab(),
                            TodoTab(),
                            NotesTab(),
                            DashboardTab(),
                            SettingsTab(),
                            UtilitiesTab(),
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
