# Zephyr Cloud OTA Testing Guide

This guide walks you through testing Zephyr Cloud OTA updates for your React Native micro-frontend setup.

## Prerequisites

1. ✅ Zephyr authentication token configured (`ZE_SECRET_TOKEN`)
2. ✅ All rspack configurations updated for Zephyr Cloud
3. ✅ Deployment script created (`deploy-to-zephyr.sh`)
4. ✅ Bundle scripts added to all apps

## Phase 1: Deploy to Zephyr Cloud

### Step 1: Verify Environment Setup

```bash
# Check if token is set
echo $ZE_SECRET_TOKEN

# Should output your token, not empty
```

### Step 2: Deploy All Apps

```bash
# Deploy all apps for iOS (recommended to start with iOS)
./deploy-to-zephyr.sh ios

# Or for Android
./deploy-to-zephyr.sh android
```

**Expected Output:**
```
[INFO] Starting Zephyr Cloud deployment for platform: ios
[INFO] Deployment order: MobileCheckout → MobileCart → MobileInventory → MobileOrders → MobileHost
[INFO] Step 1/5: Deploying MobileCheckout (leaf dependency)
[SUCCESS] MobileCheckout deployed successfully
[INFO] Step 2/5: Deploying MobileCart (depends on MobileCheckout)
[SUCCESS] MobileCart deployed successfully
[INFO] Step 3/5: Deploying MobileInventory (depends on MobileCart)
[SUCCESS] MobileInventory deployed successfully
[INFO] Step 4/5: Deploying MobileOrders (leaf dependency)
[SUCCESS] MobileOrders deployed successfully
[INFO] Step 5/5: Deploying MobileHost (depends on all remotes)
[SUCCESS] MobileHost deployed successfully
[SUCCESS] All applications deployed to Zephyr Cloud successfully!
```

### Step 3: Verify in Zephyr Dashboard

1. Log into [Zephyr Cloud Dashboard](https://zephyr-cloud.io)
2. Navigate to your project
3. Verify all 5 apps are deployed:
   - MobileCheckout
   - MobileCart
   - MobileInventory
   - MobileOrders
   - MobileHost
4. Check that each app shows the correct platform (iOS/Android)
5. Note the deployment URLs for each remote

## Phase 2: Build Production App

### Step 1: Bundle Host App with Zephyr Remotes

```bash
cd apps/mobile-host

# Bundle for iOS with Zephyr Cloud remotes
ZC=1 rnef bundle --platform ios --dev false

# Or for Android
ZC=1 rnef bundle --platform android --dev false
```

**What happens:** The `withZephyr()` wrapper automatically replaces localhost URLs with Zephyr Cloud URLs.

### Step 2: Build Native App

#### For iOS:

```bash
cd apps/mobile-host

# Install pods if needed
pnpm pods

# Build with Xcode
cd ios
xcodebuild -workspace MobileHost.xcworkspace -scheme MobileHost -configuration Release

# Or open in Xcode and build
open MobileHost.xcworkspace
```

#### For Android:

```bash
cd apps/mobile-host/android

# Build release APK
./gradlew assembleRelease

# APK will be at: android/app/build/outputs/apk/release/app-release.apk
```

### Step 3: Install and Test

1. Install the built app on a physical device or simulator
2. **Important:** Ensure the device has internet connectivity
3. Launch the app
4. Verify all screens load correctly:
   - Home screen (from MobileInventory)
   - Cart functionality (from MobileCart)
   - Checkout flow (from MobileCheckout)
   - Orders screen (from MobileOrders)

## Phase 3: Test OTA Updates

### Step 1: Make a Visible Change

Edit one of the remote apps to make a visible change:

```bash
# Example: Update MobileCart
cd apps/mobile-cart/src/screens
# Edit CartScreen.tsx - add a new button or change text
```

### Step 2: Deploy Updated Remote

```bash
# Deploy only the changed app
cd apps/mobile-cart
ZC=1 pnpm bundle:ios  # or bundle:android
```

### Step 3: Test OTA Update

1. **Without rebuilding the native app**, restart the app on your device
2. Navigate to the cart screen
3. **You should see your changes immediately!** 🎉
4. This confirms OTA updates are working

### Step 4: Test Rollback (Optional)

1. In Zephyr Dashboard, find the previous version of MobileCart
2. Click "Rollback" or "Deploy" on the previous version
3. Restart the app
4. Verify the changes are reverted

## Verification Checklist

### ✅ Deployment Verification
- [ ] All 5 apps deployed successfully
- [ ] No deployment errors in console
- [ ] Apps visible in Zephyr Dashboard
- [ ] Correct platform tags (iOS/Android)

### ✅ Production Build Verification
- [ ] Host app bundles without errors with `ZC=1`
- [ ] Native app builds successfully
- [ ] App installs and launches on device
- [ ] All micro-frontends load correctly
- [ ] No network errors in logs

### ✅ OTA Update Verification
- [ ] Changes to remote apps deploy successfully
- [ ] Updates appear in app without native rebuild
- [ ] Rollback functionality works
- [ ] App remains stable during updates

## Troubleshooting

### Common Issues

#### 1. "ZE_SECRET_TOKEN is not set"
```bash
# Fix: Export your token
export ZE_SECRET_TOKEN="your_token_here"
```

#### 2. "Failed to bundle [AppName]"
```bash
# Check for compilation errors
cd apps/[app-name]
pnpm typecheck
pnpm lint
```

#### 3. "Remote not found" in production app
- Ensure remotes were deployed before the host app
- Check network connectivity on device
- Verify Zephyr Dashboard shows successful deployments

#### 4. App crashes on startup
- Check React Native logs: `npx react-native log-ios` or `npx react-native log-android`
- Verify shared dependencies are compatible
- Check for JavaScript errors in remote bundles

### Debug Commands

```bash
# Check bundle output
ls -la apps/*/dist/

# Test individual remote deployment
cd apps/mobile-cart
ZC=1 pnpm bundle:ios --verbose

# Check network requests (add to app)
// In your app, add network logging to see remote fetches
```

## Success Criteria

🎯 **You've successfully set up Zephyr Cloud OTA updates when:**

1. All 5 apps deploy to Zephyr Cloud without errors
2. Production app loads all micro-frontends from Zephyr URLs
3. Changes to remote apps update in the production app without rebuilding
4. Rollback functionality works as expected

## Next Steps

- Set up CI/CD to automatically deploy on code changes
- Configure staging and production environments
- Set up monitoring and error tracking for OTA updates
- Explore advanced Zephyr features like A/B testing and gradual rollouts