import 'package:flutter/material.dart';
import 'package:calcwise_core/calcwise_core.dart' show isOnboardingComplete, markOnboardingComplete;
import '../../l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  /// The screen to navigate to after onboarding completes.
  /// [OnboardingScreen] will do a fade-replacement to this widget.
  final Widget nextScreen;

  const OnboardingScreen({super.key, required this.nextScreen});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  void _next() {
    if (_page < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    await markOnboardingComplete('autoloan');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:        (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration:        const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n       = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Page indicator dots ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // ── Pages ────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Page1(l10n: l10n),
                  _Page2(l10n: l10n),
                  _Page3(l10n: l10n),
                ],
              ),
            ),

            // ── Navigation buttons ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  // Back button — visible on pages 2 and 3
                  if (_page > 0) ...[
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _back,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colorScheme.outline),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Next / Get started button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          _page == 2 ? l10n.onboardingStart : l10n.onboardingNext,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 1 — Calculate your auto loan
// ─────────────────────────────────────────────────────────────────────────────

class _Page1 extends StatelessWidget {
  final AppLocalizations l10n;
  const _Page1({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Center(
              child: Text('\u{1F697}',
                  style: TextStyle(fontSize: 56)),
            ),
          ),

          const SizedBox(height: 40),

          Text(
            l10n.onboardingTitle1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            l10n.onboardingSubtitle1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Feature pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _FeaturePill(label: l10n.onboardingFeaturePayment),
              _FeaturePill(label: l10n.onboardingFeatureInterest),
              _FeaturePill(label: l10n.onboardingFeatureCost),
              _FeaturePill(label: 'CA · UK · US'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 2 — Compare scenarios
// ─────────────────────────────────────────────────────────────────────────────

class _Page2 extends StatelessWidget {
  final AppLocalizations l10n;
  const _Page2({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Center(
              child: Text('\u{1F4CA}',
                  style: TextStyle(fontSize: 56)),
            ),
          ),

          const SizedBox(height: 40),

          Text(
            l10n.onboardingTitle2,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            l10n.onboardingSubtitle2,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Comparison visual
          _CompareCard(colorScheme: colorScheme, l10n: l10n),
        ],
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final AppLocalizations l10n;
  const _CompareCard({required this.colorScheme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ScenarioColumn(
              label: '${l10n.scenario} A',
              detail: '60 mo · 6.5%',
              colorScheme: colorScheme,
              highlight: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('vs',
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _ScenarioColumn(
              label: '${l10n.scenario} B',
              detail: '48 mo · 5.9%',
              colorScheme: colorScheme,
              highlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioColumn extends StatelessWidget {
  final String label;
  final String detail;
  final ColorScheme colorScheme;
  final bool highlight;
  const _ScenarioColumn({
    required this.label,
    required this.detail,
    required this.colorScheme,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: highlight
            ? Border.all(color: colorScheme.primary, width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: highlight
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(detail,
              style: TextStyle(
                  fontSize: 11,
                  color: highlight
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 3 — Go premium
// ─────────────────────────────────────────────────────────────────────────────

class _Page3 extends StatelessWidget {
  final AppLocalizations l10n;
  const _Page3({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('\u{2B50}', style: TextStyle(fontSize: 72)),

          const SizedBox(height: 24),

          Text(
            l10n.onboardingTitle3,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            l10n.onboardingSubtitle3,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Premium features card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BulletRow(
                    label: l10n.onboardingPremiumBullet1,
                    colorScheme: colorScheme),
                const SizedBox(height: 12),
                _BulletRow(
                    label: l10n.onboardingPremiumBullet2,
                    colorScheme: colorScheme),
                const SizedBox(height: 12),
                _BulletRow(
                    label: l10n.onboardingPremiumBullet3,
                    colorScheme: colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;
  const _BulletRow({required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded,
            color: colorScheme.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: feature pill chip
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final String label;
  const _FeaturePill({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}
