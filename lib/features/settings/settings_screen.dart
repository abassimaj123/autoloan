import 'package:calcwise_core/calcwise_core.dart'
    show
        themeModeService,
        CalcwiseAdFooter,
        CalcwiseRateAppTile,
        CalcwiseSettingsScaffold,
        CalcwiseSettingsSection,
        CalcwiseSettingsTile,
        showCalcwisePrivacyOptions;
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
    return CalcwiseSettingsScaffold(
      title: l10n.settings,
      bottomNavigationBar: const CalcwiseAdFooter(),
      children: [
        // ── Premium ────────────────────────────────────────────────
        ValueListenableBuilder<bool>(
          valueListenable: freemiumService.hasFullAccessNotifier,
          builder: (context, isPremium, _) => CalcwiseSettingsSection(
            title: l10n.settingsPremium,
            children: isPremium
                ? [
                    ListTile(
                      leading: Icon(
                        Icons.verified,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        l10n.settingsPremiumActive,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(l10n.settingsPremiumSubtitle),
                    ),
                  ]
                : [
                    CalcwiseSettingsTile(
                      icon: Icons.star_rounded,
                      label: _premiumLabel(flavor, l10n),
                      subtitle: l10n.settingsPremiumSubtitle,
                      trailing: _premiumPrice(flavor),
                      onTap: () => IAPService.instance.buy(),
                    ),
                    CalcwiseSettingsTile(
                      icon: Icons.restore,
                      label: l10n.restorePurchase,
                      onTap: () => IAPService.instance.restore(),
                    ),
                  ],
          ),
        ),
        const Divider(),

        // ── Language (CA only) ─────────────────────────────────────
        if (flavor == 'ca') ...[
          CalcwiseSettingsSection(
            title: l10n.settingsLanguage,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Consumer<LocaleNotifier>(
                  builder: (context, localeNotifier, _) {
                    final isFrench = localeNotifier.isFrench;
                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              localeNotifier.setLocale(const Locale('fr'));
                              AnalyticsService.instance.logLanguageChanged(
                                'fr',
                              );
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
                              AnalyticsService.instance.logLanguageChanged(
                                'en',
                              );
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
            ],
          ),
          const Divider(),
        ],

        // ── Appearance ────────────────────────────────────────────
        Consumer<LocaleNotifier>(
          builder: (_, ln, __) {
            final isFr = ln.isFrench;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CalcwiseSettingsSection(
                  title: isFr ? 'Apparence' : 'Appearance',
                  children: [
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeModeService.notifier,
                      builder: (_, __, ___) => CalcwiseSettingsTile(
                        icon: themeModeService.icon,
                        label: themeModeService.label(isFrench: isFr),
                        onTap: () => themeModeService.toggle(),
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],
            );
          },
        ),

        // ── Support ────────────────────────────────────────────────
        CalcwiseSettingsSection(
          title: l10n.settingsSupport,
          children: [
            CalcwiseSettingsTile(
              icon: Icons.email_rounded,
              label: l10n.settingsContact,
              onTap: () => launchUrl(
                Uri.parse(
                  'mailto:support@calqwise.com?subject=AutoLoan%20Support',
                ),
              ),
            ),
            CalcwiseSettingsTile(
              icon: Icons.privacy_tip_rounded,
              label: l10n.settingsPrivacy,
              onTap: () => launchUrl(Uri.parse('https://calqwise.com/privacy')),
            ),
            CalcwiseSettingsTile(
              icon: Icons.manage_search_rounded,
              label: l10n.settingsPrivacySettings,
              onTap: showCalcwisePrivacyOptions,
            ),
            const CalcwiseRateAppTile(),
          ],
        ),
        const Divider(),

        // ── About ──────────────────────────────────────────────────
        CalcwiseSettingsSection(
          title: l10n.settingsAbout,
          children: [
            CalcwiseSettingsTile(
              icon: Icons.apps_rounded,
              label: l10n.settingsOtherApps,
              subtitle: 'calqwise.com',
              onTap: () => launchUrl(Uri.parse('https://calqwise.com')),
            ),
            CalcwiseSettingsTile(
              icon: Icons.grid_view_rounded,
              label: Localizations.localeOf(context).languageCode == 'fr'
                  ? 'Plus d\'apps par CalqWise'
                  : 'More apps by CalqWise',
              subtitle: Localizations.localeOf(context).languageCode == 'fr'
                  ? 'Voir tous nos calculateurs'
                  : 'See all our calculators',
              onTap: () => launchUrl(
                Uri.parse(
                  'https://play.google.com/store/apps/developer?id=CalqWise',
                ),
              ),
            ),
          ],
        ),
        Builder(
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${_appName(flavor, l10n)} v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
        Builder(
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                l10n.settingsDisclaimer,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _premiumLabel(String flavor, AppLocalizations l10n) {
    switch (flavor) {
      case 'uk':
        return l10n.getPremiumUK;
      case 'us':
        return l10n.getPremiumUS;
      default:
        return l10n.getPremiumCA;
    }
  }

  String _premiumPrice(String flavor) {
    return IAPService.instance.localizedPrice.value ?? 'Premium';
  }

  String _appName(String flavor, AppLocalizations l10n) {
    switch (flavor) {
      case 'uk':
        return l10n.appNameUK;
      case 'us':
        return l10n.appNameUS;
      default:
        return l10n.appNameCA;
    }
  }
}
