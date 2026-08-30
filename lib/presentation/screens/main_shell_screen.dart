import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../components/floating_island_nav_bar.dart';
import '../providers/scanner_provider.dart';
import 'analytics_screen.dart';
import 'home_dashboard_screen.dart';
import 'quick_verification_screen.dart';
import 'settings_screen.dart';
import 'transaction_history_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;

    // If jumping multiple tabs, jump to adjacent page first to guarantee 60/120fps ultra-smooth slide
    if ((index - _currentIndex).abs() > 1 && _pageController.hasClients) {
      final adjacent = index > _currentIndex ? index - 1 : index + 1;
      _pageController.jumpToPage(adjacent);
    }

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeDashboardScreen(onNavigateTab: _onTabSelected),
      const AnalyticsScreen(),
      const TransactionHistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Stack(
        children: [
          // Full-Screen Carousel PageView with Smooth Spring Physics
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: screens,
          ),

          // Floating Island Navbar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingIslandNavBar(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
              onScanPressed: () => _showScanBottomSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showScanBottomSheet(BuildContext context) {
    final scannerProvider = context.read<ScannerProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Pindai Struk / Nota', style: AppTypography.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Ekstraksi OCR otomatis secara instan di HP Anda',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryLight),
                  title: Text('Ambil Foto Kamera', style: AppTypography.bodyBold),
                  subtitle: Text('Arahkan kamera ke struk belanja', style: AppTypography.caption),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await scannerProvider.pickAndScanReceipt(ImageSource.camera);
                    if (context.mounted && scannerProvider.lastScanResult != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuickVerificationScreen(
                            parsedData: scannerProvider.lastScanResult!,
                            receiptImagePath: scannerProvider.scannedReceiptImagePath,
                          ),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: AppColors.meshCyan),
                  title: Text('Pilih dari Galeri', style: AppTypography.bodyBold),
                  subtitle: Text('Pilih gambar nota dari galeri', style: AppTypography.caption),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await scannerProvider.pickAndScanReceipt(ImageSource.gallery);
                    if (context.mounted && scannerProvider.lastScanResult != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuickVerificationScreen(
                            parsedData: scannerProvider.lastScanResult!,
                            receiptImagePath: scannerProvider.scannedReceiptImagePath,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
