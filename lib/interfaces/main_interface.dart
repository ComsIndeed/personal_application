import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/constants/app_tab_id.dart';
import '../core/widgets/app_tab.dart';
import '../core/widgets/interface_container.dart';
import '../theme/app_theme.dart';
import 'tabs/settings_tab.dart';
import 'tabs/assistant_chat/chat_tab.dart';
import 'tabs/sprints/sprints_tab.dart';
import 'tabs/notes/notes_tab.dart';
import 'tabs/notes/notes_cubit.dart';
import 'tabs/brain_dump/brain_dump_tab.dart';
import 'tabs/brain_dump/brain_dump_cubit.dart';
import '../core/services/sync_service.dart';
import '../core/database/app_database.dart';
import 'package:personal_application/core/widgets/assistant_state.dart';
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

class ToggleAssistantIntent extends Intent {
  const ToggleAssistantIntent();
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
      id: AppTabId.settings,
      initialTitle: 'Settings',
      builder: (context, controller) => const SettingsTab(),
    ),
  ];

  @override
  State<MainInterface> createState() => _MainInterfaceState();
}

class _MainInterfaceState extends State<MainInterface> {
  StreamSubscription<AuthState>? _authSubscription;
  final Set<AppTabId> _assistantOpenTabs = {};

  void _toggleAssistant(AppTabController<AppTabId> tabController) {
    setState(() {
      final currentId = tabController.currentId;
      if (_assistantOpenTabs.contains(currentId)) {
        _assistantOpenTabs.remove(currentId);
      } else {
        _assistantOpenTabs.add(currentId);
      }
    });
  }

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

    return MultiProvider(
      providers: [
        Provider<AssistantState>.value(
          value: AssistantState(
            openIds: _assistantOpenTabs,
            onToggle: () => _toggleAssistant(tabController),
          ),
        ),
      ],
      child: InterfaceContainer(
        layoutBuilder: (context, controller, container) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MainNavTabs(),
              const SizedBox(width: 12),
              container,
            ],
          );
        },
        builder: (context, controller) {
          controller.updateAlignment(Alignment.topRight);

          return Shortcuts(
            shortcuts: controller.isVisible
                ? <ShortcutActivator, Intent>{
                    const SingleActivator(
                      LogicalKeyboardKey.digit1,
                      control: true,
                    ): const TabIntent(
                      0,
                    ),
                    const SingleActivator(
                      LogicalKeyboardKey.digit2,
                      control: true,
                    ): const TabIntent(
                      1,
                    ),
                    const SingleActivator(
                      LogicalKeyboardKey.digit3,
                      control: true,
                    ): const TabIntent(
                      2,
                    ),
                    const SingleActivator(
                      LogicalKeyboardKey.backquote,
                      control: true,
                    ): const ToggleAssistantIntent(),
                    const SingleActivator(
                      LogicalKeyboardKey.arrowUp,
                      control: true,
                    ): const PrevTabIntent(),
                    const SingleActivator(
                      LogicalKeyboardKey.arrowDown,
                      control: true,
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
                ToggleAssistantIntent: CallbackAction<ToggleAssistantIntent>(
                  onInvoke: (intent) {
                    _toggleAssistant(tabController);
                    return null;
                  },
                ),
              },
              child: Focus(
                autofocus: true,
                includeSemantics: false,
                child: AppTab<AppTabId>(
                  controller: tabController,
                  pages: tabController.pages.map((page) {
                    return AppTabPage<AppTabId>(
                      id: page.id,
                      initialTitle: page.initialTitle,
                      builder: (context, controller) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.05),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                          child: _assistantOpenTabs.contains(page.id)
                              ? ChatTab(
                                  key: ValueKey('chat_${page.id}'),
                                  contextTabId: page.id,
                                  onClose: () => _toggleAssistant(controller),
                                )
                              : page.builder(context, controller),
                        );
                      },
                    );
                  }).toList(),
                  trailingHeaderWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer2<ThemeController, AssistantState>(
                        builder: (context, theme, assistant, _) {
                          final isDark = theme.isDarkMode;
                          final isAssistantOpen = assistant.openIds.contains(
                            tabController.currentId,
                          );

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: isAssistantOpen
                                    ? const SizedBox.shrink()
                                    : Tooltip(
                                        message: 'AI Assistant (Ctrl + `)',
                                        child: IconButton(
                                          icon: FaIcon(
                                            FontAwesomeIcons.diamond,
                                            size: 16,
                                            color: isAssistantOpen
                                                ? Colors.white
                                                : (isDark
                                                      ? Colors.white70
                                                      : Colors.black87),
                                          ),
                                          onPressed: assistant.onToggle,
                                          style: IconButton.styleFrom(
                                            backgroundColor: isAssistantOpen
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : (isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.05,
                                                        )
                                                      : Colors.black.withValues(
                                                          alpha: 0.05,
                                                        )),
                                          ),
                                        ),
                                      ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isAssistantOpen ? 0 : 8,
                                child: const SizedBox.shrink(),
                              ),
                              MenuAnchor(
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
                                      backgroundColor: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                    ),
                                  );
                                },
                                menuChildren: [
                                  MenuItemButton(
                                    leadingIcon: Icon(
                                      isDark
                                          ? Icons.light_mode_rounded
                                          : Icons.dark_mode_rounded,
                                      size: 18,
                                    ),
                                    onPressed: theme.toggleTheme,
                                    child: Text(
                                      isDark ? 'Light Mode' : 'Dark Mode',
                                    ),
                                  ),
                                  MenuItemButton(
                                    leadingIcon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      context.read<BrainDumpCubit>().refresh();
                                      context.read<NotesCubit>().refresh();
                                    },
                                    child: const Text('Reload All Data'),
                                  ),
                                  MenuItemButton(
                                    leadingIcon: const Icon(
                                      Icons.settings_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () => tabController.animateToId(
                                      AppTabId.settings,
                                    ),
                                    child: const Text('Settings'),
                                  ),
                                ],
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
                              Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          hoverColor: Colors.red.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
