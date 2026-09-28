# 1.1.0

- Fix domain parser broadening and important/exception precedence; support hosts tabs, aliases, comments and IPv6 sink addresses.
- Add runtime-checked experimental X promoted-post adapter and separate controls.
- Add verified Snapchat/X ad endpoints; clearly label Snapchat coverage as partial.
- Validate downloaded rules, preserve previous lists atomically, auto-download missing enabled lists on app launch, show parse counts.
- Cover compatible concrete NSURLSession resume overrides and let cancellation callbacks run normally.
- Add native Objective-C regression tests plus CI checks against three live upstream lists.
- Keep Restart SpringBoard installation action; include GPL notices and corresponding-source link.

# Changelog

## 1.0.0 — Prototype

- Added rootless arm64/arm64e tweak target.
- Added conservative domain-based NSURLSession filtering.
- Added built-in rule seed and exception handling.
- Added AdGuard DNS Filter runtime subscription.
- Added optional HaGeZi Multi PRO Mini subscription.
- Added optional StevenBlack hosts subscription.
- Added standalone AdShield application.
- Added PreferenceLoader Settings pane.
- Added runtime preference/list reload notifications.
- Added Apple/system/package-manager process exclusions.
- Added critical Apple service safety allowlist.
- Added shared rootless runtime filter storage.
- Added Sileo Restart SpringBoard finish action.
- Added black/electric-blue AdShield icon generation.
- Added GitHub Actions DEB build and package validation.

