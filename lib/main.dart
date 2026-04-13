import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await hotKeyManager.unregisterAll();
  await windowManager.ensureInitialized();
  await Window.initialize();

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
        Window.setEffect(effect: WindowEffect.acrylic, color: Colors.black);
      });

  runApp(
    ChangeNotifierProvider(
      create: (_) => WindowOverlayState(),
      child: const MainApp(),
    ),
  );
}

/// Manages the overlay window visibility and animation.
/// Mirrors the coms_inferential WindowBloc pattern but with ChangeNotifier.
class WindowOverlayState extends ChangeNotifier {
  bool _isVisible = false;
  bool get isVisible => _isVisible;

  // Animation progress (0.0 = hidden, 1.0 = visible)
  double _progress = 0.0;
  double get progress => _progress;

  late AnimationController _controller;
  bool _initialized = false;

  void initAnimation(TickerProvider vsync) {
    if (_initialized) return;
    _initialized = true;

    _controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 200),
    );

    _controller.addListener(() async {
      _progress = _controller.value;
      await windowManager.setOpacity(_controller.value);
      notifyListeners();
    });

    _registerHotKey();
  }

  Future<void> open() async {
    if (_isVisible) return;
    _isVisible = true;
    await windowManager.show();
    await windowManager.focus();
    await _controller.forward();
    notifyListeners();
  }

  Future<void> close() async {
    if (!_isVisible) return;
    _isVisible = false;
    notifyListeners(); // Trigger slide-out immediately
    await _controller.reverse();
    await windowManager.hide();
  }

  Future<void> toggle() async {
    if (_isVisible) {
      await close();
    } else {
      await open();
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
    // Initialize the animation controller with this TickerProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WindowOverlayState>().initAnimation(this);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const OverlayPage(),
    );
  }
}

class OverlayPage extends StatelessWidget {
  const OverlayPage({super.key});

  static const double panelWidth = 420;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WindowOverlayState>();
    final isVisible = state.isVisible;

    // Scale content opacity faster than window opacity for snappy feel
    final contentOpacity = (state.progress * 10).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedOpacity(
        opacity: contentOpacity,
        duration: Duration.zero,
        child: Stack(
          children: [
            // Clickable transparent background → close
            if (isVisible)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => context.read<WindowOverlayState>().close(),
                  child: Container(color: Colors.transparent),
                ),
              ),

            // Side panel aligned right
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: panelWidth,
              child: _SidePanel(isVisible: isVisible),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  final bool isVisible;

  const _SidePanel({required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E).withValues(alpha: 0.85),
            border: Border(
              left: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(-10, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 48, 12, 12),
                child: Row(
                  children: [
                    const Icon(Icons.dashboard_rounded, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Quick Panel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () =>
                          context.read<WindowOverlayState>().close(),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),

              // Content area
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.widgets_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Side Panel Content',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ctrl + Shift + Space to toggle',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate(target: isVisible ? 1 : 0)
        .slideX(begin: 1, end: 0, curve: Curves.easeOutCubic, duration: 250.ms)
        .fadeIn(duration: 200.ms);
  }
}
