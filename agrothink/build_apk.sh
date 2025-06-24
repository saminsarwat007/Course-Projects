#!/bin/bash

# Build APK script for Agrothink
echo "🌱 Starting Agrothink APK build process..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build release APK
echo "🔨 Building release APK..."
flutter build apk --release

# Check if build was successful
if [ $? -eq 0 ]; then
  APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
  
  # Check if APK exists
  if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo "✅ APK built successfully!"
    echo "📱 APK Location: $APK_PATH"
    echo "📊 APK Size: $APK_SIZE"
    
    # Add date to filename for versioning
    DATE=$(date +"%Y%m%d")
    VERSIONED_APK="agrothink_$DATE.apk"
    
    # Copy to distribution folder
    mkdir -p distribution
    cp "$APK_PATH" "distribution/$VERSIONED_APK"
    
    echo "📂 Versioned APK saved to: distribution/$VERSIONED_APK"
    echo ""
    echo "📝 Next steps:"
    echo "1. Upload the APK to your distribution platform"
    echo "2. Update download links in your documentation"
    echo "3. Notify users of the new version"
  else
    echo "❌ Build failed: APK file not found at $APK_PATH"
    exit 1
  fi
else
  echo "❌ Build failed with errors"
  exit 1
fi 