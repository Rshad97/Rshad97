#!/bin/bash
set -euo pipefail
AS_TEST_DIR="$(mktemp -d)"
AS_SIM_ID=""
cleanup() {
  if [ -n "$AS_SIM_ID" ]; then
    xcrun simctl shutdown "$AS_SIM_ID" >/dev/null 2>&1 || true
    xcrun simctl delete "$AS_SIM_ID" >/dev/null 2>&1 || true
  fi
  rm -rf "$AS_TEST_DIR"
}
trap cleanup EXIT
mkdir -p "$AS_TEST_DIR/ASXTests.app"
SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
xcrun --sdk iphonesimulator clang -arch "$(uname -m)" -isysroot "$SDK" \
  -mios-simulator-version-min=15.0 -fobjc-arc -Wall -Wextra -Werror \
  -framework Foundation -framework UIKit -framework CoreGraphics Core/ASXCellGuard.m tests/x-ui-tests.m \
  -o "$AS_TEST_DIR/ASXTests.app/ASXTests"
python3 - "$AS_TEST_DIR" <<'PY'
import json, plistlib, subprocess, sys
from pathlib import Path
p=Path(sys.argv[1])/'ASXTests.app'/'Info.plist'
p.write_bytes(plistlib.dumps({'CFBundleIdentifier':'com.rshad.adshield.uitests', 'CFBundleExecutable':'ASXTests', 'CFBundleName':'ASXTests', 'CFBundlePackageType':'APPL', 'CFBundleVersion':'1', 'CFBundleShortVersionString':'1.0', 'LSRequiresIPhoneOS':True, 'MinimumOSVersion':'15.0', 'UILaunchScreen':{}, 'UIDeviceFamily':[1]}))
available=json.loads(subprocess.check_output(['xcrun','simctl','list','-j']))
runtimes=[r for r in available['runtimes'] if r.get('isAvailable') and r['name'].startswith('iOS')]
assert runtimes, 'No available iOS simulator runtime'
runtime=sorted(runtimes,key=lambda r:tuple(map(int,r['version'].split('.'))))[-1]
devices=[d for d in available['devicetypes'] if d['name'].startswith('iPhone')]
device=next((d for d in devices if d['name']=='iPhone 16'),devices[-1])
(Path(sys.argv[1])/'sim-choice').write_text(device['identifier']+'\n'+runtime['identifier']+'\n')
PY
codesign --force --sign - "$AS_TEST_DIR/ASXTests.app"
AS_SIM_ID="$(xcrun simctl create AdShieldUITests "$(sed -n '1p' "$AS_TEST_DIR/sim-choice")" "$(sed -n '2p' "$AS_TEST_DIR/sim-choice")")"
xcrun simctl boot "$AS_SIM_ID"
xcrun simctl bootstatus "$AS_SIM_ID" -b
xcrun simctl install "$AS_SIM_ID" "$AS_TEST_DIR/ASXTests.app"
xcrun simctl launch "$AS_SIM_ID" com.rshad.adshield.uitests
AS_CONTAINER="$(xcrun simctl get_app_container "$AS_SIM_ID" com.rshad.adshield.uitests data)"
python3 - "$AS_CONTAINER/Documents/result.json" <<'PY'
import sys,time,json
from pathlib import Path
p=Path(sys.argv[1]); deadline=time.monotonic()+60
while not p.exists() and time.monotonic()<deadline: time.sleep(1)
assert p.exists(), 'UI harness timed out (launch failure or crash)'
r=json.loads(p.read_text()); print(r)
assert r['passed'], r
PY
