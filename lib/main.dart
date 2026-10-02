import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'presentation/components/app_toast.dart';
import 'presentation/providers/finance_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/scanner_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/main_shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load tema lebih dulu agar palet benar sebelum frame pertama (anti-flash).
  final themeProvider = ThemeProvider();
  await themeProvider.load();

  SystemChrome.setSystemUIOverlayStyle(_systemUiStyle(AppColors.isLight));

  runApp(RecifyApp(themeProvider: themeProvider));
}

SystemUiOverlayStyle _systemUiStyle(bool isLight) => SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      systemNavigationBarColor:
          isLight ? const Color(0xFFF5F6F8) : const Color(0xFF090A0F),
      systemNavigationBarIconBrightness:
          isLight ? Brightness.dark : Brightness.light,
    );

class RecifyApp extends StatefulWidget {
  const RecifyApp({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  State<RecifyApp> createState() => _RecifyAppState();
}

class _RecifyAppState extends State<RecifyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Mode 'system': ikuti brightness perangkat, tanpa rebuild manual —
    // notifyListeners memicu Consumer di bawah membaca ulang palet.
    widget.themeProvider.refreshSystemBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.themeProvider),
        ChangeNotifierProvider(
          create: (_) => FinanceProvider()..loadInitialData(),
        ),
        ChangeNotifierProvider(
          create: (_) => ScannerProvider()..initializeSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider()..load(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          SystemChrome.setSystemUIOverlayStyle(
            _systemUiStyle(AppColors.isLight),
          );
          return MaterialApp(
            title: 'Recify',
            debugShowCheckedModeBanner: false,
            navigatorKey: AppToast.navigatorKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.flutterMode,
            // Consumer DI DALAM route (home dibangun Navigator sekali di
            // awal): saat tema berubah, notify → instance MainShellScreen
            // BARU (non-const) → Element.update cascade ke seluruh layar
            // tanpa remount — state tab & scroll aman. Tanpa ini, ganti
            // tema hanya memperbarui widget yang watch ThemeProvider.
            home: Consumer<ThemeProvider>(
              // ignore: prefer_const_constructors — non-const disengaja, lihat komentar di atas
              builder: (context, theme, _) => MainShellScreen(),
            ),
          );
        },
      ),
    );
  }
}
