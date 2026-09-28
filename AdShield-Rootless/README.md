# AdShield-Rootless v1.1.1

Rootless iOS 15+ tweak for Dopamine/ElleKit. This update improves filtering correctness and adds an **experimental X promoted-post adapter**. Version 1.1.1 removes zero-height collapsing to address ad reappearance and overlapping rows. It does not promise complete Snapchat, YouTube or TikTok ad removal.

## Coverage

| Target | Implemented | Limit |
|---|---|---|
| X / Twitter | App-scoped lifecycle guard for cells bound to `isPromoted` items | Requires matching runtime methods; skips unknown signatures. No on-device version is certified. |
| Snapchat | Dedicated ad domains in the seed and subscribed lists | Partial network coverage; stories, Spotlight and sponsored chat are not guaranteed. |
| Games / other apps | AdGuard DNS, optional HaGeZi Pro Mini / StevenBlack | Only covered NSURLSession paths; custom networking, WebKit subprocesses and shared first-party ads may bypass it. |

The adapter checks actual installed classes and method signatures rather than assuming an App Store version is installed. Startup logs include the local app version. App Store listings cannot reveal the version on a particular phone.

## Changes

- Strict domain parser: rejects paths, wildcard rules, cosmetic rules and unsupported modifiers instead of widening their scope.
- `$important` priority: important allow > important block > ordinary allow > ordinary block.
- Hosts parsing supports tabs, aliases, comments and IPv6 sink addresses. Hosts records match exact names; domain rules also match subdomains.
- Small seed loaded synchronously. Full subscriptions parsed off the request thread.
- Missing enabled lists download when AdShield opens or a source is enabled in the app.
- Downloads validated with the same parser, replaced atomically, and retain previous files on failure. UI reports accepted and skipped rules.
- Additional concrete NSURLSession task interception when the class owns a compatible `resume` method. No claim of covering all networking stacks.
- X adapter validates method signatures and binds the actual item supplied to the cell factory. It enforces hiding after late visibility requests and layout, clears state before reuse and handles reconfiguration without reuse. Native row heights remain unchanged; empty ad space can remain.
- Block logging records hostnames, not full URLs or query tokens.

## Install / verify

1. Upgrade `com.rshad.adshieldrootless` to 1.1.1 in Sileo and select Restart SpringBoard.
2. Open AdShield. Keep AdGuard DNS enabled; missing lists download automatically. For existing lists, tap Update Filter Lists.
3. Close and reopen X and Snapchat. X Promoted Posts is enabled by default and has a separate switch in both the app and Settings.
4. Optionally enable Log Blocked Requests in Settings. Check device console output:
   - `NETWORK_HOOK_ACTIVE bundle=... appVersion=...`: network interception installed.
   - `FILTERS_LOADED accepted=N skipped=N`: parsed runtime snapshot.
   - `FILTER_UNAVAILABLE filename code=N`: missing/unreadable subscription.
   - `X_ADAPTER ACTIVE`: supported controller signatures found, **not** proof an ad was removed.
   - `X_ADAPTER UNSUPPORTED_SIGNATURE`: adapter skipped; domain filtering remains.
   - `X_PROMOTED_HIDDEN`: an actual promoted timeline item was hidden (logging enabled).
5. Verify normal posts, scrolling/reused cells, video, messages and app launch on the device. Disable X Promoted Posts if its adapter causes a regression.

## Build and tests

Theos + iOS SDK: `make clean package FINALPACKAGE=1`.
On macOS: `sh scripts/test-core.sh`.
With an installed iOS Simulator runtime: `bash scripts/test-x-ui.sh` (real UIKit cells, 300 reuse cycles, delayed unhide attempts, reconfiguration, protection toggles and native table geometry).
With current upstream lists: `AS_TEST_UPSTREAM=1 sh scripts/test-core.sh`.
CI runs the actual Objective-C parser and X compatibility helper, plus the production cell guard in iOS Simulator, then builds arm64/arm64e and validates the package. These tests do not simulate logged-in X/Snapchat or prove live ad removal.

## License

Combined tweak and XAdapter: GPL-3.0-or-later; original MIT components retain LICENSE. See COPYING and THIRD_PARTY.md. Complete source and build instructions are published here.
