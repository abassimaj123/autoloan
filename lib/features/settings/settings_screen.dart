import 'package:calcwise_core/calcwise_core.dart' show themeModeService;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../core/freemium/freemium_service.dart';
import '../../core/freemium/iap_service.dart';
import '../../core/locale_notifier.dart';
import '../../services/analytics_service.dart';

class SettingsScreen extends StatelessWidget {
  final String flavor;
  const SettingsScreen({super.key, required this.flavor});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // ── Language (CA only) ─────────────────────────────────────
          if (flavor == 'ca') ...[
            _SectionHeader(l10n.settingsLanguage),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Consumer<LocaleNotifier>(
                builder: (context, localeNotifier, _) {
                  final isFrench = localeNotifier.isFrench;
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            localeNotifier.setLocale(const Locale('fr'));
                            AnalyticsService.instance.logLanguageChanged('fr');
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isFrench
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            foregroundColor: isFrench
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                          child: Text(l10n.langFrench),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            localeNotifier.setLocale(const Locale('en'));
                            AnalyticsService.instance.logLanguageChanged('en');
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: !isFrench
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            foregroundColor: !isFrench
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                          child: Text(l10n.langEnglish),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(),
          ],

          // ── Appearance ────────────────────────────────────────────
          Consumer<LocaleNotifier>(builder: (_, ln, __) {
            final isFr = ln.isFrench;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(isFr ? 'Apparence' : 'Appearance'),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeModeService.notifier,
                  builder: (_, __, ___) => ListTile(
                    leading: Icon(themeModeService.icon,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(themeModeService.label(isFrench: isFr)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => themeModeService.toggle(),
                  ),
                ),
                const Divider(),
              ],
            );
          }),

          // ── Premium ────────────────────────────────────────────────
          _SectionHeader('Premium'),
          ValueListenableBuilder<bool>(
            valueListenable: freemiumService.isPremiumNotifier,
            builder: (context, isPremium, _) {
              if (isPremium) {
                return ListTile(
                  leading: Icon(Icons.verified,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(l10n.settingsPremiumActive,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(l10n.settingsPremiumSubtitle),
                );
              }
              return Column(children: [
                ListTile(
                  leading: Icon(Icons.star_outline,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(_premiumLabel(flavor, l10n),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(l10n.settingsPremiumSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => IAPService.instance.buy(),
                ),
                ListTile(
                  leading: Icon(Icons.restore,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(l10n.restorePurchase),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => IAPService.instance.restore(),
                ),
              ]);
            },
          ),
          const Divider(),

          // ── Support ────────────────────────────────────────────────
          _SectionHeader(l10n.settingsSupport),
          _SettingsTile(
            icon: Icons.email_outlined,
            label: l10n.settingsContact,
            onTap: () => launchUrl(Uri.parse(
                'mailto:support@calqwise.com?subject=AutoLoan%20Support')),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: l10n.settingsPrivacy,
            onTap: () =>
                launchUrl(Uri.parse('https://calqwise.com/privacy')),
          ),
          const Divider(),

          // ── About ──────────────────────────────────────────────────
          _SectionHeader(l10n.settingsAbout),
          _SettingsTile(
            icon: Icons.apps_outlined,
            label: l10n.settingsOtherApps,
            subtitle: 'calqwise.com',
            onTap: () => launchUrl(Uri.parse('https://calqwise.com')),
          ),
          _SettingsTile(
            icon: Icons.grid_view_outlined,
            label: 'More apps by CalqWise',
            subtitle: 'See all our calculators',
            onTap: () => launchUrl(Uri.parse('https://play.google.com/store/apps/developer?id=CalqWise')),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${_appName(flavor, l10n)} v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text(
              l10n.settingsDisclaimer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _premiumLabel(String flavor, AppLocalizations l10n) {
    switch (flavor) {
      case 'uk': return l10n.getPremiumUK;
      case 'us': return l10n.getPremiumUS;
      default:   return l10n.getPremiumCA;
    }
  }

  String _appName(String flavor, AppLocalizations l10n) {
    switch (flavor) {
      case 'uk': return l10n.appNameUK;
      case 'us': return l10n.appNameUS;
      default:   return l10n.appNameCA;
    }
  }
}

// ── Reusable components ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
