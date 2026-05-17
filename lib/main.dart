// ─────────────────────────────────────────────────────────────────────────────
// AutoLoan — Android-first development
// iOS: directory exists (/ios/) but flavors are NOT configured yet.
// TODO: iOS — configure Runner targets per flavor (ca/uk/us)
// TODO: iOS — add GoogleService-Info.plist per flavor
// TODO: iOS — add NSUserTrackingUsageDescription + GADApplicationIdentifier in Info.plist
// TODO: iOS — add flavor scheme scripts (FLAVOR env var via xcconfig)
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async' show Completer, unawaited;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcwise_core/calcwise_core.dart'
    show
        themeModeService,
        PaywallSessionService,
        CalcwiseAdService,
        CalcwiseAdConfig,
        requestCalcwiseConsent,
        CalcwiseAdFooter,
        CalcwiseRewardAdSheet;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'l10n/app_localizations.dart';
import 'services/crashlytics_service.dart';
import 'services/analytics_service.dart';
import 'core/config/ad_config.dart';
import 'core/locale_notifier.dart';
import 'core/freemium/freemium_service.dart';
import 'core/freemium/iap_service.dart' show IAPService, iapErrorNotifier;
import 'core/theme/theme_ca.dart';
import 'core/theme/theme_uk.dart';
import 'core/theme/theme_us.dart';
// AdService removed — using CalcwiseAdService from calcwise_core
import 'services/history_service.dart';
import 'country/ca/ca_provider.dart';
import 'country/uk/uk_provider.dart';
import 'country/us/us_provider.dart';
import 'features/cashback_vs_lowapr/cashback_vs_lowapr_screen.dart';
import 'screens/splash_screen.dart';

final paywallSession = PaywallSessionService(appKey: 'autoloan');

// Flavor injected at build time:
//   Android: --dart-define=FLAVOR=CA  (via Gradle productFlavor buildConfigField)
//   TODO: iOS — pass via xcconfig: DART_DEFINES or --dart-define in scheme
const _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'CA');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
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
      calcThreshold: AdConfig.calcThreshold,
      cooldownMinutes: AdConfig.cooldownMinutes,
    ),
    freemium: freemiumService,
    analytics: AnalyticsService.instance,
  );
  await adService.initialize();

  // 3. App data
  final prefs = await SharedPreferences.getInstance();
  await themeModeService.initialize();
  await freemiumService.initialize();
  await IAPService.instance.initialize();
  await paywallSession.initialize();
  await paywallSession.recordSession();
  AnalyticsService.instance.setUserPremium(freemiumService.hasFullAccess);
  unawaited(AnalyticsService.instance.logAppOpen(_flavor.toLowerCase()));

  final localeNotifier = LocaleNotifier(prefs, _flavor.toLowerCase());

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0B1E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  CalcwiseAdFooter.configure(
    adService: adService,
    freemium: freemiumService,
    onGetPremium: () => IAPService.instance.buy(),
  );
  CalcwiseRewardAdSheet.configure(
    adService: adService,
    freemium: freemiumService,
  );
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
            create: (_) => CAProvider(adService, historyService),
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
                  systemNavigationBarColor: Theme.of(
                    context,
                  ).scaffoldBackgroundColor,
                  systemNavigationBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                ),
              );
              return child!;
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

  ThemeData get _theme {
    switch (flavor) {
      case 'uk':
        return ThemeUK.theme;
      case 'us':
        return ThemeUS.theme;
      default:
        return ThemeCA.theme;
    }
  }

  ThemeData get _darkTheme {
    switch (flavor) {
      case 'uk':
        return ThemeUK.dark;
      case 'us':
        return ThemeUS.dark;
      default:
        return ThemeCA.dark;
    }
  }

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
  }

  @override
  void dispose() {
    iapErrorNotifier.removeListener(_onIapError);
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

  @override
  Widget build(BuildContext context) => widget.child;
}
