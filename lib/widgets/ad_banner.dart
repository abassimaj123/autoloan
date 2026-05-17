import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:calcwise_core/calcwise_core.dart'
    show CalcwiseAdService
    hide SectionCard, ResultTile;
import '../services/analytics_service.dart';
import '../core/freemium/freemium_service.dart';

class AdBannerWidget extends StatefulWidget {
  final CalcwiseAdService adService;
  const AdBannerWidget({super.key, required this.adService});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _banner;
  bool _loaded = false;
  bool _retried = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_banner == null && !_loaded) _loadBanner();
  }

  Future<void> _loadBanner() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (size == null || !mounted) return;

    final banner = BannerAd(
      adUnitId: widget.adService.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _banner = null;
            _loaded = false;
          });
          AnalyticsService.instance.logBannerFailed();
          if (!_retried) {
            _retried = true;
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) _loadBanner();
            });
          }
        },
      ),
    );
    await banner.load();
    if (mounted) setState(() => _banner = banner);
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: freemiumService.isPremiumNotifier,
      builder: (_, isPremium, child) {
        if (isPremium) return const SizedBox.shrink();
        if (!_loaded || _banner == null) return const SizedBox(height: 50);
        final bottomInset = MediaQuery.of(context).padding.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            width: _banner!.size.width.toDouble(),
            height: _banner!.size.height.toDouble(),
            child: AdWidget(ad: _banner!),
          ),
        );
      },
    );
  }
}
