# AdShield-Rootless v1.0.0

AdShield-Rootless is a prototype system-wide ad/tracker filter for rootless jailbreaks (iOS 15+), designed first for Dopamine/ElleKit.

## What v1.0.0 contains

- Rootless Theos tweak that intercepts app `NSURLSessionTask` requests.
- Small built-in seed domain list.
- AdGuard DNS Filter compatibility for basic domain rules (`||domain^`, `@@||domain^`).
- Hosts-file parsing for StevenBlack-style `0.0.0.0 domain` and `127.0.0.1 domain` entries.
- Settings pane under iOS Settings via PreferenceLoader.
- Standalone AdShield app with master switch and filter-list updater.
- Sileo `finish:restart` maintainer action so installation/removal requests **Restart SpringBoard** after dpkg completes.
- Rootless paths handled by Theos (`THEOS_PACKAGE_SCHEME=rootless`).

## Filter sources

AdShield does **not** vendor third-party lists inside the source tree or DEB. The standalone app downloads enabled lists directly from their upstream endpoints:

- AdGuard DNS Filter: `https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt`
- StevenBlack hosts: `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts`

The current parser intentionally supports only the domain-oriented subset required by this prototype. Cosmetic filtering, scriptlets, regex rules, redirect rules, and app-specific first-party ad models are not implemented in v1.0.0.

## Important limitation

YouTube, TikTok and X can deliver ads from first-party APIs/CDNs. Domain filtering alone cannot reliably remove every in-feed or playback ad without risking legitimate media. Dedicated app adapters are planned after the generic engine is stable.

## Build

```bash
export THEOS=~/theos
make clean package FINALPACKAGE=1
```

The package targets rootless iOS 15+ and includes an arm64/arm64e tweak/preferences component plus an arm64 jailbreak app. The CI build uses Theos' patched iPhoneOS 16.5 SDK so the private Preferences framework can be linked correctly.

## Install

Open the generated `.deb` in Sileo. At the end of installation Sileo should present **Restart SpringBoard**. After respring:

1. Open **Settings → AdShield-Rootless** or launch the **AdShield** app.
2. Keep AdGuard enabled.
3. Optionally enable StevenBlack.
4. Tap **Update Filter Lists** in the app.

## Safety/stability

The constructor explicitly excludes Apple/system processes and common jailbreak package-manager processes even though the Substrate filter is broad enough to reach UIKit apps. The AdShield app itself is excluded so filter updates cannot block their own download path.

## License

AdShield source code is MIT licensed. Third-party filter lists remain under their respective upstream licenses and are downloaded directly from upstream at the user's request.
