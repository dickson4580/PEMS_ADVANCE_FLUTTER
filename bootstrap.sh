#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter was not found in PATH. Install/configure Flutter first, then run this script again."
  exit 1
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cp -R "$ROOT/lib" "$TMP/lib"
cp "$ROOT/pubspec.yaml" "$TMP/pubspec.yaml"

cd "$ROOT"

if [ ! -d android ]; then
  flutter create --project-name pems_advanced --platforms=android,linux .
fi

rm -rf "$ROOT/lib"
cp -R "$TMP/lib" "$ROOT/lib"
cp "$TMP/pubspec.yaml" "$ROOT/pubspec.yaml"

MANIFEST="$ROOT/android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  python3 - "$MANIFEST" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
if 'android.permission.INTERNET' not in s:
    s = s.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">', '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    <uses-permission android:name="android.permission.INTERNET" />', 1)
if 'android:usesCleartextTraffic=' not in s:
    s = s.replace('<application\n', '<application\n        android:usesCleartextTraffic="true"\n', 1)
p.write_text(s)
PY
fi

flutter pub get

echo
echo "PEMS Advanced is ready."
echo "Connect the phone to PEMS_DEMO and run: flutter run"
