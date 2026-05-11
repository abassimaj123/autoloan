import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../services/ad_service.dart';
import '../theme/theme_ca.dart';
import '../locale_notifier.dart';
import '../freemium/freemium_service.dart';
import '../freemium/iap_service.dart';
import '../../main.dart' show paywallSession;
import '../../services/analytics_service.dart';

/// Universal monetization footer — replaces BannerAdWidget in every screen.
///
/// Premium  → nothing
/// Rewarded → green ad-free timer only (no banner)
/// Free     → "Watch ad" button + banner ad
///
/// NOTE: _FreeTierRow is intentionally inlined here (no nested StatefulWidget).
/// A nested StatefulWidget + ValueListenableBuilder mounted 5× simultaneously
/// (IndexedStack) caused Impeller (OpenGLES) to blank the entire render layer.
class AdFooter extends StatefulWidget {
  const AdFooter({super.key});
  @override
  State<AdFooter> createState() => _AdFooterState();
}

class _AdFooterState extends State<AdFooter> {
  BannerAd? _banner;
  bool      _bannerLoaded   = false;
  bool      _bannerRetried  = false;
  bool      _listenersAdded = false;
  bool      _watchLoading   = false; // merged from deleted _FreeTierRowState
  Timer?    _tick;

  @override
  void initState() {
    super.initState();
    // Defer ALL side-effects to after the first frame.
    // When IndexedStack mounts all 5 screens simultaneously, running
    // addListener / Timer / BannerAd.load() inside initState causes
    // Impeller (OpenGLES) to blank the entire render layer on Android.
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupAfterFrame());
  }

  void _setupAfterFrame() {
    if (!mounted) return;
    _listenersAdded = true;
    freemiumService.isPremiumNotifier.addListener(_rebuild);
    freemiumService.isRewardedNotifier.addListener(_rebuild);
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    if (freemiumService.showAds) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _loadBanner();
      });
    }
  }

  @override
  void dispose() {
    if (_listenersAdded) {
      freemiumService.isPremiumNotifier.removeListener(_rebuild);
      freemiumService.isRewardedNotifier.removeListener(_rebuild);
    }
    _tick?.cancel();
    _banner?.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
    // Load banner lazily when user loses premium/rewarded
    if (freemiumService.showAds && _banner == null) _loadBanner();
  }

  void _loadBanner() {
    final adService = context.read<AdService>();
    _banner = BannerAd(
      adUnitId: adService.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() { _banner = ad as BannerAd; _bannerLoaded = true; });
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!mounted) return;
          setState(() { _banner = null; _bannerLoaded = false; });
          AnalyticsService.instance.logBannerFailed();
          if (!_bannerRetried) {
            _bannerRetried = true;
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) _loadBanner();
            });
          }
        },
      ),
    )..load();
  }

  Future<void> _watch() async {
    final adService = context.read<AdService>();
    setState(() => _watchLoading = true);
    final earned = await adService.showRewarded();
    if (earned) await freemiumService.activateRewarded();
    if (mounted) setState(() => _watchLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final localeNotifier = context.watch<LocaleNotifier>();
    final isFrench = localeNotifier.isFrench;

    // ── Premium: no ads, no UI ──────────────────────────────────────────────
    if (freemiumService.isPremium) return const SizedBox.shrink();

    // ── Rewarded active: timer banner only ──────────────────────────────────
    if (freemiumService.isRewarded) {
      final mins  = freemiumService.rewardedRemaining?.inMinutes ?? 0;
      final label = isFrench
          ? 'Sans annonces — $mins min restantes'
          : 'Ad-free — $mins min remaining';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: ThemeCA.accentPos.withValues(alpha: 0.08),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.timer_outlined, size: 15, color: ThemeCA.accentPos),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: ThemeCA.accentPos,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      );
    }

    // ── Free tier: watch-ad (session 2+) + premium button + banner ──────────
    final showRewarded = paywallSession.sessionCount >= 2;
    final watchLabel = 'Watch ad for 1 min free';
    final premiumLabel = 'Get Premium';

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        color: const Color(0xFFF8FAFC),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          // Watch ad — only session 2+
          if (showRewarded)
            GestureDetector(
              onTap: _watchLoading ? null : _watch,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _watchLoading
                      ? const SizedBox(
                          width: 13, height: 13,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_circle_outline,
                          size: 15, color: ThemeCA.primary),
                  const SizedBox(width: 4),
                  Text(
                    _watchLoading ? 'Loading...' : watchLabel,
                    style: const TextStyle(fontSize: 11, color: ThemeCA.primary),
                  ),
                ]),
              ),
            ),
          const Spacer(),
          // Get Premium button
          GestureDetector(
            onTap: () => IAPService.instance.buy(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ThemeCA.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.workspace_premium, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(premiumLabel,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ]),
            ),
          ),
          const SizedBox(width: 4),
        ]),
      ),
      if (_bannerLoaded && _banner != null)
        SizedBox(
          width: double.infinity,
          height: _banner!.size.height.toDouble(),
          child: AdWidget(ad: _banner!),
        )
      else
        const SizedBox(height: 50),
    ]);
  }
}
