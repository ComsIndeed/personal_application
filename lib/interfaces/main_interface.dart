import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tabs/utilities_tab.dart';
import '../core/constants/app_tab_id.dart';
import '../core/widgets/app_tab.dart';
import '../core/widgets/interface_container.dart';
import '../theme/app_theme.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/assistant_chat/chat_tab.dart';
import 'tabs/sprints/sprints_tab.dart';
import 'tabs/notes/notes_tab.dart';
import 'tabs/notes/notes_cubit.dart';
import 'tabs/brain_dump/brain_dump_tab.dart';
import 'tabs/brain_dump/brain_dump_cubit.dart';
import '../core/services/sync_service.dart';
import '../core/database/app_database.dart';
import 'widgets/main_nav_tabs.dart';

class TabIntent extends Intent {
  final int index;
  const TabIntent(this.index);
}

class NextTabIntent extends Intent {
  const NextTabIntent();
}

class PrevTabIntent extends Intent {
  const PrevTabIntent();
}

class HideIntent extends Intent {
  const HideIntent();
}

class MainInterface extends StatefulWidget {
  const MainInterface({super.key});

  static List<AppTabPage<AppTabId>> get pages => [
    AppTabPage(
      id: AppTabId.brainDump,
      initialTitle: 'Brain Dump',
      builder: (context, controller) => const BrainDumpTab(),
    ),
    AppTabPage(
      id: AppTabId.notes,
      initialTitle: 'Notes',
      builder: (context, controller) => const NotesTab(),
    ),
    AppTabPage(
      id: AppTabId.sprints,
      initialTitle: 'Sprints',
      builder: (context, controller) => const SprintsTab(),
    ),
    AppTabPage(
      id: AppTabId.dashboard,
      initialTitle: 'Dashboard',
      builder: (context, controller) => const DashboardTab(),
    ),
    AppTabPage(
      id: AppTabId.utilities,
      initialTitle: 'Utilities',
      builder: (context, controller) => const UtilitiesTab(),
    ),
    AppTabPage(
      id: AppTabId.settings,
      initialTitle: 'Settings',
      builder: (context, controller) => const SettingsTab(),
    ),
    AppTabPage(
      id: AppTabId.assistant,
      initialTitle: 'Assistant',
      builder: (context, controller) => const ChatTab(),
    ),
  ];

  @override
  State<MainInterface> createState() => _MainInterfaceState();
}

class _MainInterfaceState extends State<MainInterface> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      if (event == AuthChangeEvent.signedIn || session != null) {
        if (mounted) SyncService().start(context.read<AppDatabase>());
      } else if (event == AuthChangeEvent.signedOut) {
        SyncService().stop();
      }
    });

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
    final tabController = context.watch<AppTabController<AppTabId>>();

    return ChangeNotifierProvider(
      create: (_) => ComposerHeightNotifier(),
      child: InterfaceContainer(
        builder: (context, controller) {
          controller.updateAlignment(Alignment.topRight);

          return Shortcuts(
            shortcuts: controller.isVisible
                ? <ShortcutActivator, Intent>{
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
                    const SingleActivator(
                      LogicalKeyboardKey.backquote,
                      alt: true,
                    ): const TabIntent(
                      6,
                    ),
                    const SingleActivator(
                      LogicalKeyboardKey.arrowUp,
                      alt: true,
                    ): const PrevTabIntent(),
                    const SingleActivator(
                      LogicalKeyboardKey.arrowDown,
                      alt: true,
                    ): const NextTabIntent(),
                  }
                : <ShortcutActivator, Intent>{},
            child: Actions(
              actions: <Type, Action<Intent>>{
                TabIntent: CallbackAction<TabIntent>(
                  onInvoke: (intent) {
                    tabController.animateToIndex(intent.index);
                    return null;
                  },
                ),
                NextTabIntent: CallbackAction<NextTabIntent>(
                  onInvoke: (intent) {
                    final nextIndex =
                        (tabController.currentIndex + 1) %
                        tabController.pages.length;
                    tabController.animateToIndex(nextIndex);
                    return null;
                  },
                ),
                PrevTabIntent: CallbackAction<PrevTabIntent>(
                  onInvoke: (intent) {
                    final prevIndex =
                        (tabController.currentIndex -
                            1 +
                            tabController.pages.length) %
                        tabController.pages.length;
                    tabController.animateToIndex(prevIndex);
                    return null;
                  },
                ),
              },
              child: Focus(
                autofocus: true,
                includeSemantics: false,
                child: Row(
                  children: [
                    const MainNavTabs(),
                    Expanded(
                      child: AppTab<AppTabId>(
                        controller: tabController,
                        pages: tabController.pages,
                        trailingHeaderWidget: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Consumer<ThemeController>(
                              builder: (context, theme, _) {
                                return MenuAnchor(
                                  builder: (context, menuController, child) {
                                    return IconButton(
                                      icon: const Icon(
                                        Icons.menu_rounded,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        if (menuController.isOpen) {
                                          menuController.close();
                                        } else {
                                          menuController.open();
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
                                        Icons.refresh_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        context
                                            .read<BrainDumpCubit>()
                                            .refresh();
                                        context.read<NotesCubit>().refresh();
                                      },
                                      child: const Text('Reload All Data'),
                                    ),
                                    MenuItemButton(
                                      leadingIcon: const Icon(
                                        Icons.settings_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () => tabController
                                          .animateToId(AppTabId.settings),
                                      child: const Text('Settings'),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            IconButton(
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
                          ],
                        ),
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

class ComposerHeightNotifier extends ChangeNotifier {
  double _height = 0;
  double get height => _height;
  set height(double value) {
    if (_height == value) return;
    _height = value;
    notifyListeners();
  }
}
