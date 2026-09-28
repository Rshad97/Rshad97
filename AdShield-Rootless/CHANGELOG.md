# 1.1.1

- Remove zero-height ad-row override. Keep X's native layout measurements to prevent inconsistent row geometry; an empty ad slot may remain.
- Bind the actual cell-factory item rather than looking it up through a potentially moved index path.
- Enforce hiding through later setHidden requests and layout; track the app's requested visibility separately.
- Clear bindings before prepareForReuse and when reconfigured as an organic/unknown item, including reconfiguration without reuse.
- Refresh existing bound cells when master/X protection switches change; retain cells weakly.
- Add an iOS Simulator harness exercising the production UIKit guard, a legacy one-shot reproduction, 300 reuse cycles, delayed callbacks and neighboring-row geometry. Keep the 48 native parser/X tests and live-list checks.

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

