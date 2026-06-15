# EcoEcho Flutter Web Vercel Automated Build Script

# 1. Download the stable version of Flutter
echo "Cloning Flutter stable channel..."
git clone https://github.com/flutter/flutter.git -b stable

# 2. Add flutter to path temporarily
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Enable Web and pull dependencies
echo "Configuring Flutter for Web..."
flutter config --enable-web
flutter pub get

# 4. Build the release version of the Web app
echo "Building Flutter Web Release..."
flutter build web --release

echo "Build complete. Output is in build/web."
