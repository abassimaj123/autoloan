import 'package:flutter/material.dart';
import 'package:calcwise_core/calcwise_core.dart';
import '../core/theme/app_theme.dart';
import '../country/ca/ca_screen.dart';
import '../country/uk/uk_screen.dart';
import '../country/us/us_screen.dart';
import '../features/onboarding/onboarding_screen.dart';

const _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'CA');

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => CalcwiseSplash(
    appName:     'Auto Loan',
    tagline:     'Drive away with the best deal',
    chips:       ['Monthly Payment', 'Total Interest', 'Trade-In'],
    badgeSymbol: r'A%',
    badgeIcon: Icons.directions_car_rounded,
    backgroundColor: AppTheme.primary,
    onComplete: () async {
      if (!mounted) return;

      final Widget homeScreen = switch (_flavor.toLowerCase()) {
        'uk' => const UKScreen(),
        'us' => const USScreen(),
        _    => const CAScreen(),
      };

      void fadeTo(Widget screen) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder:           (context, animation, _) => screen,
            transitionsBuilder:    (context, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration:        const Duration(milliseconds: 250),
            reverseTransitionDuration: const Duration(milliseconds: 200),
          ),
        );
      }

      final onboardingDone = await isOnboardingComplete('autoloan');
      if (!mounted) return;

      if (onboardingDone) {
        fadeTo(homeScreen);
      } else {
        fadeTo(OnboardingScreen(nextScreen: homeScreen));
      }
    },
  );
}
