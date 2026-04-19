import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:personal_application/interfaces/tabs/assistant_chat/assistant_chat_cubit.dart';
import 'package:personal_application/interfaces/tabs/brain_dump/brain_dump_cubit.dart';
import 'package:personal_application/interfaces/tabs/notes/notes_cubit.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/database/app_database.dart';
import 'core/services/app_prefs.dart';
import 'core/services/storage_service.dart';
import 'core/services/item_preview_cubit.dart';
import 'core/widgets/item_preview_widget.dart';
import 'interfaces/main_interface.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await hotKeyManager.unregisterAll();
  await windowManager.ensureInitialized();
  await Window.initialize();
  await AppPrefs().init();

  // Initialize Supabase with hardcoded keys
  try {
    await Supabase.initialize(
      url: 'https://jzxfhtthknwegozofkvg.supabase.co',
      anonKey: 'sb_publishable_B8rQ5TIbXMSCWhDX_P0gnw_S4_JRXeA',
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  final database = AppDatabase();
  StorageService().setDatabase(database);

  // We moved the verification to inside MainApp to avoid startup contention
  // but we keep the instance ready.

  const windowOptions = WindowOptions(
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager
      .waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setAsFrameless();
        await windowManager.setOpacity(0.0);
        await windowManager.maximize();
      })
      .then((_) {
        Window.setEffect(effect: WindowEffect.transparent);
      });

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        BlocProvider(create: (context) => AssistantChatCubit(db: database)),
        BlocProvider(create: (context) => BrainDumpCubit(database)),
        BlocProvider(create: (context) => NotesCubit(database)),
        BlocProvider(create: (context) => ItemPreviewCubit()),
        ChangeNotifierProvider(create: (_) => WindowOverlayState()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: const MainApp(),
    ),
  );
}

class WindowOverlayState extends ChangeNotifier {
  bool _isVisible = false;
  bool get isVisible => _isVisible;

  late AnimationController _controller;
  bool _initialized = false;

  void initAnimation(TickerProvider vsync) {
    if (_initialized) return;
    _initialized = true;

    _controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 220),
    );

    _controller.addListener(() {
      windowManager.setOpacity(_controller.value);
    });

    _registerHotKey();
  }

  Future<void> open() async {
    if (_isVisible) return;
    debugPrint('[Overlay] Opening window...');
    _isVisible = true;
    notifyListeners();

    // Ensure window is frameless, on top, and maximized
    await windowManager.setAsFrameless();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();

    _controller
        .forward()
        .then((_) {
          debugPrint('[Overlay] Animation completed.');
        })
        .catchError((e) {
          debugPrint('[Overlay] Animation failed: $e');
          windowManager.setOpacity(1.0); // Fallback to full visibility
        });

    debugPrint('[Overlay] Window opened and animation triggered.');
  }

  Future<void> close() async {
    if (!_isVisible) return;
    debugPrint('[Overlay] Closing window...');
    _isVisible = false;
    notifyListeners();
    await _controller.reverse();
    await windowManager.hide();
    debugPrint('[Overlay] Window hidden.');
  }

  void toggle() {
    if (_isVisible) {
      close();
    } else {
      open();
    }
  }

  void _registerHotKey() async {
    HotKey hotKey = HotKey(
      key: PhysicalKeyboardKey.space,
      modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
    );

    await hotKeyManager.register(hotKey, keyDownHandler: (_) => toggle());
  }

  @override
  void dispose() {
    if (_initialized) _controller.dispose();
    super.dispose();
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WindowOverlayState>().initAnimation(this);

      // Verification of B2 after UI is ready
      StorageService().verifyCredentials().catchError((e) {
        debugPrint('[Storage] B2 auto-verification failed: $e');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeController.themeMode,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: child!,
        );
      },
      home: const OverlayPage(),
    );
  }
}

class OverlayPage extends StatelessWidget {
  const OverlayPage({super.key});

  static const double panelWidth = 530;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Clickable backdrop → close
          Positioned.fill(
            child: Consumer<WindowOverlayState>(
              builder: (context, state, _) {
                return GestureDetector(
                  onTap: () => state.close(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    color: state.isVisible
                        ? Colors.black.withValues(alpha: 0.15)
                        : Colors.transparent,
                  ),
                );
              },
            ),
          ),

          // Side panel (always in tree, positioning handled by InterfaceContainer)
          const MainInterface(),

          // Root Overlay Preview (Anchored Left of Screen)
          const ItemPreviewWidget(),
        ],
      ),
    );
  }
}
