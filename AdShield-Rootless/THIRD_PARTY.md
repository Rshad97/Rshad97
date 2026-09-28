# Third-party sources

AdShield-Rootless v1.0.0 does not copy AdGuard or StevenBlack implementation code.

## AdGuard DNS Filter

- Project: AdguardTeam/AdGuardSDNSFilter
- Purpose here: optional runtime filter subscription
- Upstream filter endpoint: https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt
- Upstream project license: GPL-3.0

AdShield implements a small, independent parser for a domain-oriented subset of AdGuard/ABP syntax. Unsupported rules are ignored.

## StevenBlack hosts

- Project: StevenBlack/hosts
- Purpose here: optional runtime hosts-style domain subscription
- Upstream endpoint: https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
- Note: the aggregate file contains data from multiple upstream sources with different licenses; see the upstream repository for per-source licensing.

No third-party list is redistributed in this repository or bundled into the package.
