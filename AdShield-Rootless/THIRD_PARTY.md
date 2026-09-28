# Third-party filter sources

AdShield-Rootless v1.0.0 does not copy third-party filtering engines and does not vendor the following remote lists in its DEB. AdShield implements its own conservative domain-rule parser and downloads enabled subscriptions directly from upstream when the user presses **Update Filter Lists**.

## AdGuard DNS Filter

- Project: `AdguardTeam/AdGuardSDNSFilter`
- Endpoint: `https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt`
- Upstream license: GPL-3.0
- AdShield default: enabled
- Purpose: primary DNS/domain-level advertising and tracking filter.

AdGuard describes this list as a DNS-oriented combination of several AdGuard, mobile-ad, EasyList and EasyPrivacy sources. AdShield supports only a safe domain-oriented subset of its syntax in v1.0.0.

## HaGeZi Multi PRO Mini

- Project: `hagezi/dns-blocklists`
- Endpoint: `https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.mini.txt`
- Upstream license: GPL-3.0
- AdShield default: disabled
- Purpose: optional size-optimized mobile/limited-memory supplementary source.

HaGeZi describes Pro Mini as a size-optimized form of its balanced Pro list intended for browser/mobile blockers and constrained hardware. It is optional because loading multiple large domain sets increases memory usage in each injected application.

## StevenBlack unified hosts

- Project: `StevenBlack/hosts`
- Endpoint: `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts`
- Repository license: MIT for StevenBlack's software/content where applicable.
- AdShield default: disabled
- Purpose: optional hosts-format aggregate.

The generated unified hosts file incorporates multiple upstream data sources. Their individual licenses and attribution requirements remain those documented by the StevenBlack project.

## Distribution model

The remote filter data is not committed to this repository and is not bundled into the AdShield package. Downloaded copies are stored locally on the jailbroken device under:

`/var/jb/Library/Application Support/AdShield/Filters/Runtime`

This keeps filter updates independent from tweak releases and avoids presenting third-party list data as AdShield-owned code.
