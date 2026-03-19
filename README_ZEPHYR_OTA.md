# Zephyr Cloud OTA Updates - Complete Setup

This project is now configured for Zephyr Cloud Over-The-Air (OTA) updates! 🚀

## 📁 What's Been Added/Modified

### Modified Files
- **`apps/mobile-host/rspack.config.mjs`** - Updated to handle Zephyr vs localhost URLs
- **`apps/mobile-cart/rspack.config.mjs`** - Added conditional remote configuration  
- **`apps/mobile-inventory/rspack.config.mjs`** - Added conditional remote configuration
- **`apps/mobile-host/package.json`** - Added bundle script

### New Files
- **`deploy-to-zephyr.sh`** - Automated deployment script
- **`build-production.sh`** - Production build script
- **`ZEPHYR_SETUP.md`** - Environment setup guide
- **`TESTING_GUIDE.md`** - Complete testing instructions
- **`README_ZEPHYR_OTA.md`** - This summary file

## 🚀 Quick Start

### 1. Setup Environment
```bash
# Set your Zephyr token
export ZE_SECRET_TOKEN="your_zephyr_token_here"
```

### 2. Deploy to Zephyr Cloud
```bash
# Deploy all apps (iOS)
./deploy-to-zephyr.sh ios

# Deploy all apps (Android)  
./deploy-to-zephyr.sh android
```

### 3. Build Production App
```bash
# Bundle only
./build-production.sh ios bundle

# Bundle + build native app
./build-production.sh ios native
```

### 4. Test OTA Updates
1. Make changes to any remote app (MobileCart, MobileInventory, etc.)
2. Deploy just that app: `cd apps/mobile-cart && ZC=1 pnpm bundle:ios`
3. Restart your production app - changes appear instantly! ✨

## 🏗️ Architecture Overview

```
MobileHost (Host App)
├── Consumes remotes from Zephyr Cloud in production
├── Uses localhost in development
└── Automatically switches based on ZC=1 environment variable

Remote Apps (Micro-frontends)
├── MobileCart (port 9000) → depends on MobileCheckout
├── MobileInventory (port 9001) → depends on MobileCart  
├── MobileCheckout (port 9002) → leaf dependency
└── MobileOrders (port 9003) → leaf dependency
```

## 🔄 Deployment Flow

The deployment script follows the correct dependency order:

1. **MobileCheckout** (no dependencies)
2. **MobileCart** (depends on MobileCheckout)
3. **MobileInventory** (depends on MobileCart)
4. **MobileOrders** (no dependencies)
5. **MobileHost** (depends on all remotes)

## 🎯 Key Benefits

- **Instant Updates**: Update micro-frontends without app store releases
- **Selective Updates**: Update individual features independently
- **Rollback Safety**: Instant rollback if issues occur
- **Production Testing**: Test real OTA behavior before release

## 📱 Development vs Production

| Mode | Environment | Remote URLs | Usage |
|------|-------------|-------------|-------|
| **Development** | `ZC=0` or unset | `localhost:900X` | Local development |
| **Production** | `ZC=1` | Zephyr Cloud URLs | Production builds |

## 🛠️ Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `deploy-to-zephyr.sh` | Deploy all apps to Zephyr | `./deploy-to-zephyr.sh ios` |
| `build-production.sh` | Build production app | `./build-production.sh ios native` |

## 📚 Documentation

- **`ZEPHYR_SETUP.md`** - Detailed environment setup
- **`TESTING_GUIDE.md`** - Step-by-step testing instructions
- **[Zephyr Docs](https://docs.zephyr-cloud.io/integrations/react-native-repack)** - Official documentation

## ✅ Verification Checklist

Before going to production, verify:

- [ ] All 5 apps deploy successfully to Zephyr Cloud
- [ ] Production app loads all micro-frontends from Zephyr URLs
- [ ] OTA updates work (changes appear without native rebuild)
- [ ] Rollback functionality works
- [ ] App remains stable during updates

## 🔧 Troubleshooting

### Common Issues

1. **"ZE_SECRET_TOKEN is not set"**
   - Export your Zephyr token: `export ZE_SECRET_TOKEN="your_token"`

2. **"Remote not found"**
   - Ensure remotes are deployed before host app
   - Check deployment order in script

3. **App crashes on startup**
   - Check React Native logs for JavaScript errors
   - Verify network connectivity on device

### Debug Commands

```bash
# Test individual app deployment
cd apps/mobile-cart
ZC=1 pnpm bundle:ios

# Check bundle output
ls -la apps/*/dist/

# Verify environment
env | grep ZE
```

## 🎉 Success!

Your React Native micro-frontend setup is now ready for Zephyr Cloud OTA updates! 

**Next Steps:**
1. Follow `ZEPHYR_SETUP.md` to configure your environment
2. Use `TESTING_GUIDE.md` for detailed testing instructions
3. Deploy and test your first OTA update

Happy coding! 🚀