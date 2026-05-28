import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:calcwise_core/calcwise_core.dart' hide SectionCard, ResultTile;
import '../core/theme/app_theme.dart';

// ── Cross-promo: SalaryApp ──────────────────────────────────────────────────
// Shown to free users only. Dismissible, remembers dismissal for 7 days.
class CrossPromoCard extends StatefulWidget {
  final bool isPremium;
  const CrossPromoCard({super.key, required this.isPremium});

  @override
  State<CrossPromoCard> createState() => _CrossPromoCardState();
}

class _CrossPromoCardState extends State<CrossPromoCard> {
  bool _dismissed = false;
  bool _checked = false;

  static const _prefKey = 'cross_promo_dismissed_autoloan';
  static const _targetName = 'Salary Calculator';
  static const _targetTagline = 'Know your real take-home pay';
  static const _targetId = 'com.calcwise.salaryapp';
  static const _accentColor = Color(0xFF0F52B0);

  @override
  void initState() {
    super.initState();
    _checkDismissed();
  }

  Future<void> _checkDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_prefKey) ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (mounted)
      setState(() {
        _dismissed = age < 7 * 24 * 3600 * 1000;
        _checked = true;
      });
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, DateTime.now().millisecondsSinceEpoch);
    if (mounted) setState(() => _dismissed = true);
  }

  Future<void> _open() async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$_targetId',
    );
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || _dismissed || widget.isPremium)
      return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.06),
        border: Border.all(color: _accentColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.mdPlus),
            ),
            child: Icon(Icons.calculate_rounded, color: _accentColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.smPlus),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: const Text(
                        'CalqWise',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppTextSize.xxs,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Also from us',
                      style: TextStyle(
                        fontSize: AppTextSize.xs,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _targetName,
                  style: TextStyle(
                    fontSize: AppTextSize.md,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  _targetTagline,
                  style: TextStyle(
                    fontSize: AppTextSize.xs,
                    color: AppTheme.labelGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            children: [
              InkWell(
                onTap: _dismiss,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: _open,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Text(
                    'Free',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTextSize.xs,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
