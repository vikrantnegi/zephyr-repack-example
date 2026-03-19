#!/bin/bash

# Deploy to Zephyr Cloud Script
# This script deploys all React Native micro-frontend apps to Zephyr Cloud
# in the correct dependency order to ensure proper resolution of remotes.

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
    print_error "Please set your Zephyr authentication token:"
    print_error "export ZE_SECRET_TOKEN=your_token_here"
    exit 1
fi

# Default platform
PLATFORM=${1:-"ios"}

if [ "$PLATFORM" != "ios" ] && [ "$PLATFORM" != "android" ]; then
    print_error "Invalid platform: $PLATFORM"
    print_error "Usage: $0 [ios|android]"
    print_error "Example: $0 ios"
    exit 1
fi

print_status "Starting Zephyr Cloud deployment for platform: $PLATFORM"
print_status "Deployment order: MobileCheckout → MobileCart → MobileInventory → MobileOrders → MobileHost"

# Function to deploy an app
deploy_app() {
    local app_name=$1
    local app_path=$2
    
    print_status "Deploying $app_name..."
    
    cd "$app_path"
    
    # Check if bundle script exists
    if ! pnpm run bundle:$PLATFORM > /dev/null 2>&1; then
        print_error "Failed to bundle $app_name for $PLATFORM"
        return 1
    fi
    
    print_success "$app_name deployed successfully"
    cd - > /dev/null
}

# Deploy apps in dependency order
print_status "Step 1/5: Deploying MobileCheckout (leaf dependency)"
ZC=1 deploy_app "MobileCheckout" "apps/mobile-checkout"

print_status "Step 2/5: Deploying MobileCart (depends on MobileCheckout)"
ZC=1 deploy_app "MobileCart" "apps/mobile-cart"

print_status "Step 3/5: Deploying MobileInventory (depends on MobileCart)"
ZC=1 deploy_app "MobileInventory" "apps/mobile-inventory"

print_status "Step 4/5: Deploying MobileOrders (leaf dependency)"
ZC=1 deploy_app "MobileOrders" "apps/mobile-orders"

print_status "Step 5/5: Deploying MobileHost (depends on all remotes)"
ZC=1 deploy_app "MobileHost" "apps/mobile-host"

print_success "All applications deployed to Zephyr Cloud successfully!"
print_status "Platform: $PLATFORM"
print_status "You can now build your production app with ZC=1 to use Zephyr Cloud remotes"

# Instructions for next steps
echo ""
print_status "Next steps:"
echo "1. Build your production app:"
echo "   For iOS: cd apps/mobile-host && ZC=1 rnef bundle --platform ios --dev false"
echo "   For Android: cd apps/mobile-host && ZC=1 rnef bundle --platform android --dev false"
echo ""
echo "2. Build the native app:"
echo "   For iOS: cd apps/mobile-host/ios && xcodebuild -workspace MobileHost.xcworkspace -scheme MobileHost -configuration Release"
echo "   For Android: cd apps/mobile-host/android && ./gradlew assembleRelease"
echo ""
echo "3. Install and test OTA updates on your device"