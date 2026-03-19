#!/bin/bash

# Debug Production Build Issues
# This script helps identify and debug production build problems

set -e

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

PLATFORM=${1:-"android"}

if [ "$PLATFORM" != "ios" ] && [ "$PLATFORM" != "android" ]; then
    print_error "Invalid platform: $PLATFORM"
    print_error "Usage: $0 [ios|android]"
    exit 1
fi

print_status "Debug Production Build for platform: $PLATFORM"

# Check if ZE_SECRET_TOKEN is set
if [ -z "$ZE_SECRET_TOKEN" ]; then
    print_warning "ZE_SECRET_TOKEN environment variable is not set"
    print_warning "Production builds with Zephyr Cloud require authentication"
    print_status "You can still test local production builds without ZC=1"
fi

# Step 1: Check if remotes are deployed to Zephyr Cloud
print_status "Step 1: Checking Zephyr Cloud deployment status..."
if [ -n "$ZE_SECRET_TOKEN" ]; then
    print_status "Zephyr Cloud authentication available"
    # Here you could add actual Zephyr Cloud API calls to check deployment status
else
    print_warning "Cannot check Zephyr Cloud status without ZE_SECRET_TOKEN"
fi

# Step 2: Build production bundle for host app
print_status "Step 2: Building production bundle for mobile-host..."
cd apps/mobile-host

# Try building without Zephyr Cloud first (local production test)
print_status "Building local production bundle (without ZC=1)..."
if rnef bundle --platform $PLATFORM --dev false --entry-file index.js; then
    print_success "Local production bundle built successfully"
else
    print_error "Failed to build local production bundle"
    print_error "This indicates a fundamental issue with the production configuration"
    exit 1
fi

# If ZE_SECRET_TOKEN is available, try with Zephyr Cloud
if [ -n "$ZE_SECRET_TOKEN" ]; then
    print_status "Building Zephyr Cloud production bundle (with ZC=1)..."
    if ZC=1 rnef bundle --platform $PLATFORM --dev false --entry-file index.js; then
        print_success "Zephyr Cloud production bundle built successfully"
    else
        print_error "Failed to build Zephyr Cloud production bundle"
        print_error "This could indicate issues with remote module URLs or authentication"
    fi
fi

cd ../..

# Step 3: Check bundle outputs
print_status "Step 3: Checking bundle outputs..."
BUNDLE_DIR="apps/mobile-host/dist/$PLATFORM"
if [ -d "$BUNDLE_DIR" ]; then
    print_success "Bundle directory exists: $BUNDLE_DIR"
    
    # List bundle files
    print_status "Bundle files:"
    ls -la "$BUNDLE_DIR"
    
    # Check for main bundle
    if [ -f "$BUNDLE_DIR/index.bundle" ]; then
        BUNDLE_SIZE=$(du -h "$BUNDLE_DIR/index.bundle" | cut -f1)
        print_success "Main bundle found (size: $BUNDLE_SIZE)"
    else
        print_error "Main bundle not found!"
    fi
    
    # Check for source maps
    if [ -f "$BUNDLE_DIR/index.bundle.map" ]; then
        print_success "Source map found"
    else
        print_warning "Source map not found (this is normal for production)"
    fi
else
    print_error "Bundle directory not found: $BUNDLE_DIR"
fi

# Step 4: Provide debugging instructions
print_status "Step 4: Debugging instructions"
echo ""
print_status "To debug production build issues:"
echo "1. Check the console logs when running the production app"
echo "2. Look for module loading errors in the ErrorBoundary components"
echo "3. Verify that all remote modules are properly deployed"
echo "4. Check network connectivity to remote module URLs"
echo ""

print_status "To test the production build:"
echo "1. Install the production APK/IPA on a device"
echo "2. Monitor the logs using:"
if [ "$PLATFORM" == "android" ]; then
    echo "   adb logcat | grep -E '(ReactNativeJS|ErrorBoundary|LazyLoaded|CartScreen)'"
else
    echo "   Use Xcode console or device logs to monitor React Native logs"
fi
echo ""

print_success "Debug script completed!"
print_status "If issues persist, check the mobile-core moduleCache.ts fixes and rspack configurations"