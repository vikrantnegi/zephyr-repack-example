#!/bin/bash

# Build Production App with Zephyr Cloud OTA
# This script builds the production version of the host app that loads remotes from Zephyr Cloud

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if ZE_SECRET_TOKEN is set
if [ -z "$ZE_SECRET_TOKEN" ]; then
    print_error "ZE_SECRET_TOKEN environment variable is not set"
    print_error "Please set your Zephyr authentication token first"
    exit 1
fi

# Default platform
PLATFORM=${1:-"ios"}
BUILD_TYPE=${2:-"bundle"}  # bundle, native, or install
INSTALL_ON_DEVICE=${3:-"false"}  # Optional third parameter to install on device

if [ "$PLATFORM" != "ios" ] && [ "$PLATFORM" != "android" ]; then
    print_error "Invalid platform: $PLATFORM"
    print_error "Usage: $0 [ios|android] [bundle|native|install] [install]"
    print_error "Example: $0 android native"
    print_error "Example: $0 android install (builds and installs directly)"
    exit 1
fi

if [ "$BUILD_TYPE" != "bundle" ] && [ "$BUILD_TYPE" != "native" ] && [ "$BUILD_TYPE" != "install" ]; then
    print_error "Invalid build type: $BUILD_TYPE"
    print_error "Usage: $0 [ios|android] [bundle|native|install] [install]"
    print_error "Example: $0 android native"
    print_error "Example: $0 android install (builds and installs directly)"
    exit 1
fi

# If BUILD_TYPE is "install", set both native build and install flags
if [ "$BUILD_TYPE" == "install" ]; then
    BUILD_TYPE="native"
    INSTALL_ON_DEVICE="true"
fi

# If third parameter is "install", enable installation
if [ "$3" == "install" ]; then
    INSTALL_ON_DEVICE="true"
fi

print_status "Building production app for platform: $PLATFORM"
print_status "Build type: $BUILD_TYPE"
if [ "$INSTALL_ON_DEVICE" == "true" ]; then
    print_status "Will install on connected device after building"
fi

# Navigate to host app
cd apps/mobile-host

# Step 1: Bundle the host app with Zephyr remotes
print_status "Step 1: Bundling host app with Zephyr Cloud remotes..."
ZC=1 pnpm rnef bundle --platform $PLATFORM --dev false --entry-file index.js

if [ $? -eq 0 ]; then
    print_success "Host app bundled successfully with Zephyr remotes"
else
    print_error "Failed to bundle host app"
    exit 1
fi

# Step 2: Build native app if requested
if [ "$BUILD_TYPE" == "native" ]; then
    print_status "Step 2: Building native app..."
    
    if [ "$PLATFORM" == "ios" ]; then
        print_status "Installing iOS dependencies..."
        pnpm pods
        
        print_status "Building iOS app..."
        cd ios
        
        # Check if we can build with xcodebuild
        if command -v xcodebuild &> /dev/null; then
            print_status "Building with xcodebuild..."
            xcodebuild -workspace MobileHost.xcworkspace -scheme MobileHost -configuration Release -destination generic/platform=iOS
            
            if [ $? -eq 0 ]; then
                print_success "iOS app built successfully!"
                print_status "You can find the build in the iOS build directory"
            else
                print_warning "xcodebuild failed. Please open Xcode and build manually:"
                print_status "open MobileHost.xcworkspace"
            fi
        else
            print_warning "xcodebuild not found. Please open Xcode and build manually:"
            print_status "open MobileHost.xcworkspace"
        fi
        
    elif [ "$PLATFORM" == "android" ]; then
        print_status "Building Android app..."
        cd android
        
        # Make gradlew executable
        chmod +x ./gradlew
        
        # Build release APK (or build and install if requested)
        if [ "$INSTALL_ON_DEVICE" == "true" ]; then
            print_status "Building and installing release APK on connected device..."
            ./gradlew installRelease
            
            if [ $? -eq 0 ]; then
                print_success "Android app built and installed successfully!"
                print_status "App has been installed on your connected Android device"
                
                # Show APK info
                APK_PATH="app/build/outputs/apk/release/app-release.apk"
                if [ -f "$APK_PATH" ]; then
                    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
                    print_status "APK size: $APK_SIZE"
                fi
            else
                print_error "Failed to build and install Android app"
                print_error "Make sure your Android device is connected and USB debugging is enabled"
                exit 1
            fi
        else
            ./gradlew assembleRelease
            
            if [ $? -eq 0 ]; then
                print_success "Android app built successfully!"
                print_status "APK location: android/app/build/outputs/apk/release/app-release.apk"
                
                # Show APK info
                APK_PATH="app/build/outputs/apk/release/app-release.apk"
                if [ -f "$APK_PATH" ]; then
                    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
                    print_status "APK size: $APK_SIZE"
                fi
            else
                print_error "Failed to build Android app"
                exit 1
            fi
        fi
    fi
else
    print_status "Skipping native build (bundle only)"
fi

# Final instructions
echo ""
print_success "Production build completed!"
print_status "Platform: $PLATFORM"
print_status "Build type: $BUILD_TYPE"

if [ "$BUILD_TYPE" == "bundle" ]; then
    echo ""
    print_status "Next steps:"
    echo "1. To build the native app, run:"
    echo "   $0 $PLATFORM native"
    echo ""
    echo "2. Or build manually:"
    if [ "$PLATFORM" == "ios" ]; then
        echo "   cd apps/mobile-host && pnpm pods && cd ios && open MobileHost.xcworkspace"
    else
        echo "   cd apps/mobile-host/android && ./gradlew assembleRelease"
        echo "   Or to install directly: cd apps/mobile-host/android && ./gradlew installRelease"
    fi
fi

echo ""
print_status "The app will load micro-frontends from Zephyr Cloud URLs"
print_status "Make sure all remotes are deployed before testing!"

if [ "$INSTALL_ON_DEVICE" == "true" ] && [ "$PLATFORM" == "android" ]; then
    echo ""
    print_success "🚀 Quick command for next time:"
    print_success "   ./build-production.sh android install"
fi