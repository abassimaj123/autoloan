// ─────────────────────────────────────────────────────────────────────────────
// AutoLoan — Android-first development
// iOS: directory exists (/ios/) but flavors are NOT configured yet.
// TODO: iOS — configure Runner targets per flavor (ca/uk/us)
// TODO: iOS — add GoogleService-Info.plist per flavor
// TODO: iOS — add NSUserTrackingUsageDescription + GADApplicationIdentifier in Info.plist
// TODO: iOS — add flavor scheme scripts (FLAVOR env var via xcconfig)
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async' show Completer, unawaited;
import 'package:intl/date_symbol_data_local.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/firebase/firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcwise_core/calcwise_core.dart'
    show
        themeModeService,
        PaywallSessionService,
        SmartHistoryService,
        CalcwiseAdService,
        CalcwiseAdConfig,
        requestCalcwiseConsent,
        CalcwiseAdFooter,
        CalcwiseRewardAdSheet,
        CalcwiseTax,
        calcwiseTaxRemoteFetch,
        CalcwiseRemoteConfig,
        CalcwiseThemeFactory;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'l10n/app_localizations.dart';
import 'services/crashlytics_service.dart';
import 'services/analytics_service.dart';
import 'widgets/paywall_hard.dart';
import 'widgets/paywall_soft.dart';
import 'core/config/ad_config.dart';
import 'core/locale_notifier.dart';
import 'core/freemium/freemium_service.dart';
import 'core/freemium/iap_service.dart' show IAPService, iapErrorNotifier, iapRestoreResultNotifier;
// AdService removed — using CalcwiseAdService from calcwise_core
import 'services/history_service.dart';
import 'services/autoloan_database_adapter.dart';
import 'country/ca/ca_provider.dart';
import 'country/uk/uk_provider.dart';
import 'country/us/us_provider.dart';
import 'features/cashback_vs_lowapr/cashback_vs_lowapr_screen.dart';
import 'screens/splash_screen.dart';

final paywallSession = PaywallSessionService(
  appKey: 'autoloan',
  hasFullAccess: () => freemiumService.hasFullAccess,
);

// SmartHistoryService — wired to AutoLoan's SharedPreferences-backed HistoryService
// via AutoLoanDatabaseAdapter. Initialized lazily after HistoryService is available.
late final SmartHistoryService smartHistoryService;

// Global locale notifier — initialized in main() before runApp(); used by splash.
late final LocaleNotifier localeNotifier;

// Mirrors localeNotifier.isFrench/isSpanish as ValueNotifier<bool> — the shape
// CalcwiseAdFooter/CalcwiseRewardAdSheet.configure() require for localized copy.
final ValueNotifier<bool> isFrenchNotifier = ValueNotifier<bool>(false);
final ValueNotifier<bool> isSpanishNotifier = ValueNotifier<bool>(false);

// Flavor injected at build time:
//   Android: --dart-define=FLAVOR=CA  (via Gradle productFlavor buildConfigField)
//   TODO: iOS — pass via xcconfig: DART_DEFINES or --dart-define in scheme
const _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'CA');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android 15+ (API 35) forces edge-to-edge; draw under transparent system
  // bars ourselves instead of painting them opaque (deprecated pattern).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('en_CA', null);
  await initializeDateFormatting('en_GB', null);
  await initializeDateFormatting('fr', null);
  await initializeDateFormatting('fr_CA', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  unawaited(CalcwiseRemoteConfig.initialize());
  await CalcwiseTax.init(remoteFetcher: calcwiseTaxRemoteFetch);
  await CrashlyticsService.init();

  // 1. GDPR / PIPEDA consent (UK + CA require it; UMP handles region detection)
  //    Must run BEFORE MobileAds.instance.initialize().
  await requestCalcwiseConsent();

  // 2. AdMob + ads (consent already obtained above)
  final adConfig = AdConfig(_flavor.toLowerCase());
  final adService = CalcwiseAdService(
    config: CalcwiseAdConfig(
      bannerAndroid: adConfig.bannerId,
      interstitialAndroid: adConfig.interId,
      rewardedAndroid: adConfig.rewardedId,
      calcThreshold: 7,
      cooldownMinutes: 5,
    ),
    freemium: freemiumService,
    analytics: AnalyticsService.instance,
  );
  await adService.initialize();
  if (kDebugMode) {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: ['FD16D4616C3A21C3ACE5E48F8DC9C1DC']),
    );
  }

  // 3. App data
  final prefs = await SharedPreferences.getInstance();
  await themeModeService.initialize();
  await freemiumService.initialize();
  await IAPService.instance.initialize();
  await paywallSession.initialize();

  // SmartHistory — backed by the same SharedPreferences HistoryService
  // Note: AutoLoanApp also creates a HistoryService(prefs) — same prefs, same data.
  final histSvcForSmartHistory = HistoryService(prefs);
  smartHistoryService = SmartHistoryService(
    db: AutoLoanDatabaseAdapter(histSvcForSmartHistory),
    freemium: freemiumService,
  );
  AnalyticsService.instance.setUserPremium(freemiumService.hasFullAccess);
  unawaited(AnalyticsService.instance.initialize());
  unawaited(AnalyticsService.instance.logAppOpen(_flavor.toLowerCase()));

  localeNotifier = LocaleNotifier(prefs, _flavor.toLowerCase());
  isFrenchNotifier.value = localeNotifier.isFrench;
  isSpanishNotifier.value = localeNotifier.isSpanish;
  localeNotifier.addListener(() {
    isFrenchNotifier.value = localeNotifier.isFrench;
    isSpanishNotifier.value = localeNotifier.isSpanish;
  });

  // Initial system UI style — brightness-aware update happens in MaterialApp builder
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF8FAFC),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  CalcwiseAdFooter.configure(
    adService: adService,
    freemium: freemiumService,
    isFrenchNotifier: isFrenchNotifier,
    isSpanishNotifier: isSpanishNotifier,
    onGetPremium: () => IAPService.instance.buy(),
    analytics: AnalyticsService.instance,
  );
  CalcwiseRewardAdSheet.configure(
    adService: adService,
    freemium: freemiumService,
    isFrenchNotifier: isFrenchNotifier,
    isSpanishNotifier: isSpanishNotifier,
  );
  PaywallHard.setAnalytics(AnalyticsService.instance);
  PaywallSoft.setAnalytics(AnalyticsService.instance);
  runApp(
    AutoLoanApp(
      prefs: prefs,
      adService: adService,
      flavor: _flavor.toLowerCase(),
      localeNotifier: localeNotifier,
    ),
  );
}

class AutoLoanApp extends StatelessWidget {
  final SharedPreferences prefs;
  final CalcwiseAdService adService;
  final String flavor;
  final LocaleNotifier localeNotifier;

  const AutoLoanApp({
    super.key,
    required this.prefs,
    required this.adService,
    required this.flavor,
    required this.localeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final historyService = HistoryService(prefs);

    return MultiProvider(
      providers: [
        Provider<CalcwiseAdService>.value(value: adService),
        Provider<HistoryService>.value(value: historyService),
        ChangeNotifierProvider<LocaleNotifier>.value(value: localeNotifier),
        if (flavor == 'ca')
          ChangeNotifierProvider(
            // Smart Auto: pass locale-detected province (QC for French, ON for English CA)
            create: (_) => CAProvider(adService, historyService,
                smartProvince: localeNotifier.isFrench ? 'QC' : 'ON'),
          ),
        if (flavor == 'uk')
          ChangeNotifierProvider(
            create: (_) => UKProvider(adService, historyService),
          ),
        if (flavor == 'us')
          ChangeNotifierProvider(
            create: (_) => USProvider(adService, historyService),
          ),
      ],
      child: Consumer<LocaleNotifier>(
        builder: (_, localeNotifier, _) => ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeService.notifier,
          builder: (_, themeMode, __) => MaterialApp(
            title: _appTitle,
            theme: _theme,
            darkTheme: _darkTheme,
            themeMode: themeMode,
            locale: localeNotifier.locale,
            navigatorObservers: [
              FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
            ],
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: _supportedLocales,
            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle(
                  // Transparent — the app draws under the system nav bar
                  // (edge-to-edge) instead of painting it opaque, per
                  // Android 15's forced behavior.
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                ),
              );
              final wrapped = _IapErrorWrapper(child: child!);
              if (!MediaQuery.of(context).disableAnimations) return wrapped;
              return Theme(
                data: Theme.of(context).copyWith(
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: _NoAnimPageTransitionsBuilder(),
                      TargetPlatform.iOS: _NoAnimPageTransitionsBuilder(),
                    },
                  ),
                ),
                child: wrapped,
              );
            },
            home: const SplashScreen(),
            routes: {
              '/cashback-vs-lowapr': (_) =>
                  CashbackVsLowAprScreen(flavor: flavor),
            },
          ),
        ),
      ),
    );
  }

  // ── Brand colors ──────────────────────────────────────────────────────────
  // All flavors share the same navy-blue primary; accents differ CA/UK vs US.
  static const Color _primary = Color(0xFF0D47A1);
  static const Color _accentCaUk = Color(0xFFC62828);
  static const Color _accentUs = Color(0xFFB71C1C);

  Color get _flavorAccent =>
      flavor == 'us' ? _accentUs : _accentCaUk;

  ThemeData get _theme =>
      CalcwiseThemeFactory.buildLight(primary: _primary, accent: _flavorAccent);

  ThemeData get _darkTheme =>
      CalcwiseThemeFactory.buildDark(primary: _primary, accent: _flavorAccent);

  String get _appTitle {
    switch (flavor) {
      case 'uk':
        return 'Auto Loan UK';
      case 'us':
        return 'Auto Loan USA';
      default:
        return 'Auto Loan Canada';
    }
  }

  List<Locale> get _supportedLocales {
    switch (flavor) {
      case 'us':
        return const [Locale('en'), Locale('es')];
      case 'uk':
        return const [Locale('en')];
      default:
        return const [Locale('fr'), Locale('en')];
    }
  }
}

/// Thin stateful wrapper that listens to [iapErrorNotifier] and shows a
/// SnackBar when an IAP error occurs — without requiring BuildContext in the service.
class _IapErrorWrapper extends StatefulWidget {
  final Widget child;
  const _IapErrorWrapper({required this.child});

  @override
  State<_IapErrorWrapper> createState() => _IapErrorWrapperState();
}

class _IapErrorWrapperState extends State<_IapErrorWrapper> {
  @override
  void initState() {
    super.initState();
    iapErrorNotifier.addListener(_onIapError);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      iapRestoreResultNotifier.addListener(_onRestoreResult);
    });
  }

  @override
  void dispose() {
    iapErrorNotifier.removeListener(_onIapError);
    iapRestoreResultNotifier.removeListener(_onRestoreResult);
    super.dispose();
  }

  void _onIapError() {
    final msg = iapErrorNotifier.value;
    if (msg == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
    iapErrorNotifier.value = null;
  }

  void _onRestoreResult() {
    final result = iapRestoreResultNotifier.value;
    if (result == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final msg = result == 'restored'
          ? 'Premium restored!'
          : 'No purchases to restore.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
      iapRestoreResultNotifier.value = null;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _NoAnimPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
