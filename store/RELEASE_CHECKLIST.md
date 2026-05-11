# AutoLoan — Release Checklist

App: Auto Loan Calculator (CA / US / UK)
Target: Google Play (multi-flavor AAB)
Date: April 30, 2026

---

## 1. Code & Build

- [ ] `flutter analyze` — zero errors, zero warnings
- [ ] All `// ignore:` comments justified and documented
- [ ] `flutter test` — all tests pass
- [ ] `flutter build appbundle --flavor ca --release`
- [ ] `flutter build appbundle --flavor us --release`
- [ ] `flutter build appbundle --flavor uk --release`
- [ ] AAB size < 30 MB per flavor (check with bundletool)
- [ ] `debugUnlockPremium()` is guarded by `kDebugMode` — verify it does NOT fire in release
- [ ] ProGuard / R8 rules tested — no runtime crashes from minification

## 2. Freemium & IAP

- [ ] Free tier: exactly 5 history saves, then soft paywall
- [ ] Hard paywall triggers at correct action count
- [ ] Rewarded ad: daily cap = 3, 60-minute session confirmed
- [ ] `rewardedRemaining` getter returns correct Duration
- [ ] Premium unlock persists after app restart (SharedPreferences)
- [ ] IAP product IDs match Play Console (`premium_autoloan_onetime`)
- [ ] Restore purchase works on reinstall
- [ ] ReviewService: triggers on 3rd save, 90-day cooldown confirmed

## 3. Ads

- [ ] AdMob App ID set in `gradle.properties` / `AndroidManifest.xml` (not hardcoded)
- [ ] Test ad IDs replaced with production IDs for release build
- [ ] Banner ad not shown to Premium users
- [ ] Interstitial threshold = 8 calculations, 5-minute cooldown
- [ ] Rewarded ad loads and plays correctly on physical device

## 4. Localization

- [ ] CA flavor: English + French — all strings translated, no missing keys
- [ ] US flavor: English + Spanish — all strings translated, no missing keys
- [ ] UK flavor: English only — all strings present
- [ ] Date/number formats correct per locale
- [ ] RTL layout not broken (test with pseudo-RTL)

## 5. Android Security (OWASP)

- [ ] `network_security_config.xml` present — cleartext blocked except localhost
- [ ] `android:allowBackup="false"` confirmed in AndroidManifest
- [ ] No hardcoded API keys, secrets, or AdMob IDs in source
- [ ] ProGuard obfuscation enabled for release
- [ ] `android:debuggable` not set to true in release manifest

## 6. Splash & Icons

- [ ] `ic_launcher_round.xml` present in `mipmap-anydpi-v26/`
- [ ] `values-v31/styles.xml` present — Android 12+ splash screen correct color (#0D47A1)
- [ ] `values-night-v31/styles.xml` present — dark mode splash correct
- [ ] Launcher icons present for all densities (mdpi / hdpi / xhdpi / xxhdpi / xxxhdpi)
- [ ] Splash screen tested on Android 12+ physical device or emulator

## 7. Store Listing

- [ ] Screenshots uploaded (phone + 7-inch tablet) for each flavor/locale
- [ ] Feature graphic uploaded (1024×500 px)
- [ ] Short description ≤ 80 characters per locale
- [ ] Full description reviewed for spelling/grammar
- [ ] App name correct per flavor (US / CA / UK suffix)
- [ ] Privacy policy URL live and accessible: store/privacy/index.html
- [ ] Content rating questionnaire completed (Finance category)
- [ ] Target audience: 18+

## 8. Play Console

- [ ] Data safety form completed:
  - No personal data collected
  - Ad identifiers disclosed (AdMob)
  - No data shared with third parties (except ad partners)
- [ ] App signing enrolled (Play App Signing)
- [ ] Release track: Internal → Closed testing → Production
- [ ] Rollout: 20% initial, monitor crash-free rate before 100%
- [ ] In-app product published and active in Play Console
- [ ] Price tiers set: US $2.99 / CA $3.99 CAD / UK £2.99

## 9. Post-Release Monitoring (first 7 days)

- [ ] Firebase Crashlytics: crash-free rate > 99.5%
- [ ] ANR rate < 0.47% (Play Console threshold)
- [ ] IAP conversion funnel reviewed in Analytics
- [ ] Rewarded ad fill rate checked in AdMob dashboard
- [ ] First reviews responded to within 24h
