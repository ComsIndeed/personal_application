import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desktop_screenshot/desktop_screenshot.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'package:personal_application/interfaces/tabs/assistant_chat/assistant_chat_cubit.dart';
import 'package:personal_application/interfaces/tabs/brain_dump/brain_dump_cubit.dart';
import 'package:personal_application/interfaces/tabs/notes/notes_cubit.dart';
import 'package:personal_application/interfaces/tabs/sprints/sprints_cubit.dart';

import 'core/constants/app_tab_id.dart';
import 'core/database/app_database.dart';
import 'core/services/app_prefs.dart';
import 'core/services/database_browser_cubit.dart';
import 'core/services/item_preview_cubit.dart';
import 'core/services/sprints_service.dart';
import 'core/services/storage_service.dart';
import 'core/widgets/app_tab.dart';
import 'core/widgets/item_preview_widget.dart';
import 'interfaces/main_interface.dart';
import 'interfaces/widgets/database_browser_widget.dart';
import 'theme/app_theme.dart';

void main() async {
  HttpOverrides.global = MyHttpOverrides();
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
  SprintsService().setDatabase(database);

  // Background verification of B2 on launch
  StorageService().verifyCredentials().catchError((e) {
    debugPrint('B2 auto-verification failed: $e');
  });

  const windowOptions = WindowOptions(
    center: true,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    fullScreen: true,
  );

  windowManager
      .waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setOpacity(0.0);
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
        BlocProvider(create: (context) => SprintsCubit()),
        BlocProvider(create: (context) => ItemPreviewCubit()),
        BlocProvider(create: (context) => DatabaseBrowserCubit()),
        ChangeNotifierProvider(
          create: (_) => AppTabController<AppTabId>(pages: MainInterface.pages),
        ),
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

  ui.Image? _blurredBgImage;
  ui.Image? get blurredBgImage => _blurredBgImage;

  Offset _windowOffset = Offset.zero;
  Offset get windowOffset => _windowOffset;

  void toggleDynamicBackdrop() {
    AppPrefs().dynamicBackdropEnabled = !AppPrefs().dynamicBackdropEnabled;
    notifyListeners();
  }

  void toggle() async {
    if (_isVisible) {
      await close();
    } else {
      await open();
    }
  }

  Future<void> _captureScreen() async {
    try {
      final bytes = await DesktopScreenshot().getScreenshot();

      if (bytes != null && bytes.isNotEmpty) {
        final sharpImage = await decodeImageFromList(bytes);

        // Pre-blur the image once to avoid edge artifacts and live BackdropFilter costs
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final paint = Paint()
          ..imageFilter = ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50);

        canvas.drawImage(sharpImage, Offset.zero, paint);
        final picture = recorder.endRecording();

        _blurredBgImage = await picture.toImage(
          sharpImage.width,
          sharpImage.height,
        );
        sharpImage
            .dispose(); // Save memory, we only need the blurred 'glass' version
      } else {
        _blurredBgImage = null;
      }

      _windowOffset = await windowManager.getPosition();
      notifyListeners();
    } catch (e) {
      debugPrint('Screen capture failed: $e');
    }
  }

  Future<void> open() async {
    if (_isVisible) return;

    if (AppPrefs().dynamicBackdropEnabled) {
      await _captureScreen();
    }

    _isVisible = true;
    notifyListeners();
    await windowManager.show();
    await windowManager.focus();
    _controller.forward();
  }

  Future<void> close() async {
    if (!_isVisible) return;
    _isVisible = false;
    notifyListeners();
    await _controller.reverse();
    await windowManager.hide();

    // Clear background to avoid "ghost" frames on next open
    _blurredBgImage?.dispose(); // Proper clean up of image memory
    _blurredBgImage = null;
    notifyListeners();
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

  @override
  Widget build(BuildContext context) {
    final overlayState = context.watch<WindowOverlayState>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => overlayState.close(),
              child: Container(color: Colors.transparent),
            ),
          ),

          const MainInterface(),
          const ItemPreviewWidget(),
          const DatabaseBrowserWidget(),
        ],
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
