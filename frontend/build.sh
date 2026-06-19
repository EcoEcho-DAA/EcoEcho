#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Build the Web App
flutter clean
flutter pub get

# Default to your specific Backend URL if the Vercel environment variable isn't set
BACKEND_URL=${API_URL:-"https://eco-echo-smoky.vercel.app"}

flutter build web --release --dart-define=API_URL=$BACKEND_URL
