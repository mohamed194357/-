import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ضبط ألوان وتناسق أشرطة النظام الافتراضية
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppDesign.bgDark,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(const HesbatyMasterApp());
}

/// ثيم التصميم الفاخر (Ultra-Dark Glass & Blue Tech)
class AppDesign {
  static const Color bgDark = Color(0xFF090D16);
  static const Color surfaceDark = Color(0xFF131B2A);
  static const Color surfaceCard = Color(0xFF1B2436);
  static const Color border = Color(0xFF2B384E);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color danger = Color(0xFFEF4444);
  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
}

class HesbatyMasterApp extends StatelessWidget {
  const HesbatyMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حسبتي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppDesign.bgDark,
        fontFamily: 'sans-serif',
      ),
      home: const HesbatyPortalScreen(),
    );
  }
}

class HesbatyPortalScreen extends StatefulWidget {
  const HesbatyPortalScreen({super.key});

  @override
  State<HesbatyPortalScreen> createState() => _HesbatyPortalScreenState();
}

class _HesbatyPortalScreenState extends State<HesbatyPortalScreen> {
  static const String _appUrl = 'https://hesbaty.ct.ws';

  late final WebViewController _controller;
  double _loadProgress = 0.0;
  bool _isPageLoading = true;
  bool _hasConnectionError = false;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  @override
  void initState() {
    super.initState();
    _setupWebEngine();
    _startConnectivityMonitor();
  }

  void _setupWebEngine() {
    final WebViewController controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppDesign.bgDark)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadProgress = progress / 100.0;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isPageLoading = true;
              _hasConnectionError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isPageLoading = false;
              _loadProgress = 0.0;
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame ?? true) {
              setState(() {
                _hasConnectionError = true;
                _isPageLoading = false;
              });
            }
          },
        ),
      );

    // تفعيل التخزين المؤقت المتقدم وذاكرة التخزين المحلية على أجهزة أندرويد
    if (controller.platform is AndroidWebViewController) {
      final AndroidWebViewController androidController =
          controller.platform as AndroidWebViewController;

      androidController.setDomStorageEnabled(true);
      androidController.setCacheMode(AndroidCacheMode.LOAD_DEFAULT);
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadRequest(Uri.parse(_appUrl));
    _controller = controller;
  }

  void _startConnectivityMonitor() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline && _hasConnectionError) {
        _refreshContent();
      }
    });
  }

  void _refreshContent() {
    setState(() {
      _hasConnectionError = false;
      _isPageLoading = true;
    });
    _controller.reload();
  }

  Future<bool> _onBackPressed() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }

    final bool? exitApp = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'إغلاق',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: Container(
          width: MediaQuery.of(ctx).size.width * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppDesign.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppDesign.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppDesign.surfaceCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppDesign.border),
                  ),
                  child: const Icon(Icons.power_settings_new_rounded,
                      color: AppDesign.accentCyan, size: 36),
                ),
                const SizedBox(height: 18),
                const Text(
                  'الخروج من تطبيق حسبتي',
                  style: TextStyle(
                    color: AppDesign.textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'هل أنت متأكد من رغبتك في إغلاق التطبيق؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppDesign.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppDesign.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('إلغاء',
                            style: TextStyle(color: AppDesign.textMuted)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppDesign.danger,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('خروج',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return exitApp ?? false;
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onBackPressed();
        if (shouldExit && mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // طبقة العرض الويب الكاملة مع ميزة Pull To Refresh
              RefreshIndicator(
                onRefresh: () async => _refreshContent(),
                color: AppDesign.accentCyan,
                backgroundColor: AppDesign.surfaceDark,
                child: WebViewWidget(controller: _controller),
              ),

              // مؤشر التقدم العلوي الدقيق
              if (_isPageLoading && _loadProgress > 0 && _loadProgress < 1.0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _loadProgress,
                    minHeight: 3.5,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppDesign.accentCyan),
                  ),
                ),

              // شاشة التحميل الأولية الاحترافية لمنع ظهور الفراغات
              if (_isPageLoading && _loadProgress < 0.25 && !_hasConnectionError)
                _buildSplashLoadingView(),

              // واجهة الخطأ المخصصة عند فقد الاتصال
              if (_hasConnectionError) _buildOfflineErrorView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplashLoadingView() {
    return Container(
      color: AppDesign.bgDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppDesign.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppDesign.border),
                boxShadow: [
                  BoxShadow(
                    color: AppDesign.primaryBlue.withOpacity(0.2),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.calculate_rounded,
                size: 54,
                color: AppDesign.accentCyan,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'حسبتي',
              style: TextStyle(
                color: AppDesign.textMain,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppDesign.accentCyan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineErrorView() {
    return Container(
      color: AppDesign.bgDark,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppDesign.surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppDesign.border),
              boxShadow: [
                BoxShadow(
                  color: AppDesign.danger.withOpacity(0.15),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 58,
              color: AppDesign.danger,
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'تعذّر الاتصال بالخادم',
            style: TextStyle(
              color: AppDesign.textMain,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'يرجى التأكد من تشغيل بيانات الهاتف أو الاتصال بشبكة Wi-Fi والمحاولة مرة أخرى.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppDesign.textMuted,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _refreshContent,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text(
              'إعادة المحاولة الآن',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppDesign.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
