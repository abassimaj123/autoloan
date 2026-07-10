import 'package:flutter/material.dart';
import 'package:calcwise_core/calcwise_core.dart';

class OnboardingScreen extends StatelessWidget {
  final Widget nextScreen;
  final String flavor;

  const OnboardingScreen({
    super.key,
    required this.nextScreen,
    required this.flavor,
  });

  @override
  Widget build(BuildContext context) {
    return CalcwiseOnboarding(
      appKey: 'autoloan',
      nextScreen: nextScreen,
      pages: _buildPages(flavor),
    );
  }
}

List<OnboardingPage> _buildPages(String flavor) {
  final pills1 = switch (flavor) {
    'uk' => const ['PCP Calculator', 'HP Finance UK', 'VED 2026/27', 'Rule of 78'],
    'ca' => const ['Km Overage Calc', 'Lease vs Finance', 'Province Tax', 'Français/English'],
    _ => const ['Car Affordability', 'Lease vs Finance', 'Credit Score Rates', '50 State Tax'],
  };

  return [
    OnboardingPage(
      icon: Icons.directions_car_rounded,
      title: 'Calculate Your\nAuto Loan',
      subtitle:
          'Monthly payment, total interest and full loan cost — all calculated instantly.',
      titleFr: 'Calculez votre\nprêt auto',
      subtitleFr:
          'Paiement mensuel, intérêts totaux et coût total — tout calculé instantanément.',
      pills: pills1,
    ),
    const OnboardingPage(
      icon: Icons.compare_arrows_rounded,
      title: 'Compare Scenarios',
      subtitle:
          'Different terms, rates or down payments — see which deal saves you the most.',
      titleFr: 'Comparez les scénarios',
      subtitleFr:
          'Durées, taux ou mises de fonds différents — voyez quelle offre vous fait économiser le plus.',
      pills: ['60 mo · 6.5%', '48 mo · 5.9%', 'Lease vs Finance'],
      pillsFr: ['60 mois · 6,5 %', '48 mois · 5,9 %', 'Location vs Achat'],
    ),
    const OnboardingPage(
      icon: Icons.history_rounded,
      title: 'Save Your\nCalculations',
      subtitle:
          'Your loan calculations are saved automatically. Revisit and compare anytime.',
      titleFr: 'Sauvegardez vos\ncalculs',
      subtitleFr:
          'Vos calculs de prêt sont sauvegardés automatiquement. Comparez vos scénarios en tout temps.',
      pills: ['History', 'PDF Export', 'Amortization'],
      pillsFr: ['Historique', 'Export PDF', 'Amortissement'],
    ),
  ];
}
