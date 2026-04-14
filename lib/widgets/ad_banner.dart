import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Adaptive anchored banner — width matches screen, height auto-calculated.
/// Uses getCurrentOrientationAnchoredAdaptiveBannerAdSize for higher CPM
/// vs fixed AdSize.banner. Shows nothing (SizedBox.shrink) until ad is loaded.
class AdBannerWidget extends StatefulWidget {
  final AdService adService;
  const AdBannerWidget({super.key, required this.adService});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _banner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_banner == null) _loadBanner();
  }

  Future<void> _loadBanner() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final size  = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;

    final banner = BannerAd(
      adUnitId: widget.adService.bannerId,
      size:     size,
      request:  const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded:       (_) { if (mounted) setState(() {}); },
        onAdFailedToLoad: (ad, _) { ad.dispose(); if (mounted) setState(() => _banner = null); },
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
    if (_banner == null) return const SizedBox.shrink();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        width:  _banner!.size.width.toDouble(),
        height: _banner!.size.height.toDouble(),
        child:  AdWidget(ad: _banner!),
      ),
    );
  }
}
