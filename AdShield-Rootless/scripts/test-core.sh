#!/bin/sh
set -eu
TEST_BINARY="${TMPDIR:-/tmp}/adshield-core-tests"
clang -fobjc-arc -Wall -Wextra -Werror -framework Foundation \
  Core/ASDomainRules.m Core/ASXSupport.m tests/core-tests.m -o "$TEST_BINARY"
"$TEST_BINARY"
if [ "${AS_TEST_UPSTREAM:-0}" = 1 ]; then
  curl -fL --retry 2 https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt -o "${TMPDIR:-/tmp}/adshield-adguard.txt"
  "$TEST_BINARY" "${TMPDIR:-/tmp}/adshield-adguard.txt"
  curl -fL --retry 2 https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.mini.txt -o "${TMPDIR:-/tmp}/adshield-hagezi.txt"
  "$TEST_BINARY" "${TMPDIR:-/tmp}/adshield-hagezi.txt"
  curl -fL --retry 2 https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts -o "${TMPDIR:-/tmp}/adshield-stevenblack.txt"
  "$TEST_BINARY" "${TMPDIR:-/tmp}/adshield-stevenblack.txt"
fi
