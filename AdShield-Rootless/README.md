# AdShield-Rootless v1.0.0

AdShield-Rootless is a modular ad/tracker filtering prototype for rootless jailbreaks on iOS 15+, designed for Dopamine/ElleKit.

## v1.0.0 prototype

- Rootless Theos tweak with arm64 + arm64e slices.
- Intercepts third-party app `NSURLSessionTask` requests.
- Apple/system processes, package managers, app extensions and AdShield itself are excluded from injection.
- Independent parser for a conservative DNS/domain subset:
  - `||example.com^`
  - `@@||example.com^`
  - `0.0.0.0 example.com`
  - `127.0.0.1 example.com`
  - plain domains
- Unsupported AdGuard modifiers are skipped rather than guessed.
- Hard safety allowlist for critical Apple/iCloud domains.
- Built-in seed list.
- Optional runtime filter subscriptions:
  - AdGuard DNS Filter (enabled by default)
  - HaGeZi Multi PRO Mini (optional)
  - StevenBlack unified hosts (optional)
- Standalone AdShield app for protection controls and list updates.
- PreferenceLoader pane in iOS Settings.
- Darwin notification reload so rule changes propagate to already-running apps.
- Downloaded lists live in the shared rootless support path:
  `/var/jb/Library/Application Support/AdShield/Filters/Runtime`.
- Sileo-compatible `finish:restart` action so installation/removal presents **Restart SpringBoard**.

## Why these sources?

AdGuard DNS Filter is the default primary source because it is designed specifically for DNS-level ad blocking and already combines major AdGuard/mobile/tracking lists. HaGeZi Pro Mini is a size-optimized optional list intended for browser/mobile or limited-memory blockers. StevenBlack provides a mature hosts-format aggregate and is kept optional.

AdShield does not vendor these lists into the source tree or DEB. The standalone app downloads enabled lists directly from their upstream endpoints.

## Architecture

```text
Third-party app
     │
     ▼
AdShield.dylib
     │
     ├── ASPreferences
     ├── ASRuleEngine
     │     ├── built-in seed rules
     │     └── /var/jb/.../Filters/Runtime
     │
     └── NSURLSessionTask hook
             │
             ├── allow rule → pass through
             └── block rule → cancel request

Settings.app ── PreferenceLoader ── AdShieldPrefs.bundle

AdShield.app
     ├── master/network switches
     ├── filter-source switches
     └── safe upstream list updater
```

## Important v1.0.0 limitation

This first version is a domain/network layer, not a complete YouTube/TikTok/X-specific blocker.

YouTube, TikTok and X can serve promotions and playback ads through first-party APIs/CDNs. Blocking those entire domains would also break legitimate video/timeline traffic. Dedicated app adapters are therefore planned as separate modules after the generic engine is stable.

Planned adapters:

- YouTube feed / Shorts / playback ad-state adapter
- TikTok sponsored feed-object adapter
- X promoted timeline/card adapter
- Google Mobile Ads SDK
- AppLovin
- Unity Ads
- ironSource / LevelPlay
- Mintegral

## Build

Requires Theos and a usable iOS SDK.

```sh
export THEOS=~/theos
make clean package FINALPACKAGE=1
```

Package:
- Identifier: `com.rshad.adshieldrootless`
- Version: `1.0.0`
- Architecture: `iphoneos-arm64`
- Minimum iOS: 15.0
- Injection: ElleKit
- Settings: PreferenceLoader

GitHub Actions builds the DEB and validates package metadata, Settings resources, the standalone app, bundled seed rules and the `finish:restart` maintainer action.

## After installation

1. In Sileo, use **Restart SpringBoard** when prompted.
2. Open **Settings → AdShield-Rootless** or the **AdShield** app.
3. Leave **AdGuard DNS Filter** enabled.
4. Optionally enable **HaGeZi Pro Mini** or **StevenBlack Hosts**.
5. Tap **Update Filter Lists**.
6. Test normal browsing/apps first before enabling extra sources.

## Project icon

The visual identity is a black/deep-navy shield with electric-blue protection/ad-blocking elements. The build includes generated iPhone and PreferenceLoader icon sizes from the project asset generator.

## Third-party licenses

See `THIRD_PARTY.md`. AdShield's own source is MIT licensed. Third-party lists remain governed by their upstream licenses and are downloaded from upstream rather than redistributed inside this package.
