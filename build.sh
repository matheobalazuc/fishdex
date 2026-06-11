#!/bin/bash
set -e
git clone https://github.com/flutter/flutter.git --depth 1 -b stable /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"
flutter config --enable-web
flutter pub get
flutter build web --release --pwa-strategy=none
echo "{\"v\":\"$(date +%s)\"}" > build/web/version.json
