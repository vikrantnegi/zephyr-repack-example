# Zephyr Cloud Setup Guide

This guide will help you configure your environment for Zephyr Cloud OTA updates.

## 1. Get Your Zephyr Authentication Token

1. Visit [Zephyr Cloud](https://zephyr-cloud.io) and sign up/log in
2. Navigate to your project settings or API tokens section
3. Generate a new API token for your project
4. Copy the token - you'll need it for the next step

## 2. Set Environment Variables

### For Local Development

Add the following to your shell profile (`.bashrc`, `.zshrc`, etc.):

```bash
# Zephyr Cloud Configuration
export ZE_SECRET_TOKEN="your_zephyr_token_here"
```

Then reload your shell:
```bash
source ~/.zshrc  # or ~/.bashrc
```

### For CI/CD (GitHub Actions)

The project already has GitHub Actions configured. Add the following secret to your GitHub repository:

1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Add a new repository secret:
   - Name: `ZE_SECRET_TOKEN`
   - Value: Your Zephyr authentication token

## 3. Environment Variables Reference

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `ZE_SECRET_TOKEN` | Zephyr authentication token | Yes | `zephyr_token_abc123...` |
| `ZC` | Enable Zephyr Cloud mode | Yes (for deployment) | `1` |
| `WITH_ZE` | Enable Zephyr Enterprise features | Optional | `1` |

## 4. Verify Setup

Test your configuration by running:

```bash
# Check if token is set
echo $ZE_SECRET_TOKEN

# Test deployment (dry run)
ZC=1 pnpm --filter MobileCheckout bundle:ios
```

## 5. Usage Examples

### Deploy to Zephyr Cloud
```bash
# Deploy all apps for iOS
./deploy-to-zephyr.sh ios

# Deploy all apps for Android
./deploy-to-zephyr.sh android
```

### Build Production App with Zephyr
```bash
# Bundle host app with Zephyr remotes
cd apps/mobile-host
ZC=1 rnef bundle --platform ios --dev false

# Build native iOS app
cd ios
xcodebuild -workspace MobileHost.xcworkspace -scheme MobileHost -configuration Release
```

### Development vs Production

| Mode | Environment | Remote URLs | Usage |
|------|-------------|-------------|-------|
| Development | `ZC=0` or unset | `localhost:900X` | Local development |
| Production | `ZC=1` | Zephyr Cloud URLs | Production builds |

## 6. Troubleshooting

### Common Issues

1. **"ZE_SECRET_TOKEN is not set"**
   - Ensure the environment variable is exported
   - Check spelling and case sensitivity

2. **"Failed to authenticate with Zephyr"**
   - Verify your token is valid
   - Check if your Zephyr account has access to the project

3. **"Remote not found"**
   - Ensure remotes are deployed before the host app
   - Check the deployment order in `deploy-to-zephyr.sh`

### Debug Commands

```bash
# Check environment variables
env | grep ZE

# Test individual app deployment
cd apps/mobile-checkout
ZC=1 pnpm bundle:ios

# Check bundle output
ls -la dist/
```

## 7. Next Steps

After setup is complete:

1. Run `./deploy-to-zephyr.sh ios` to deploy all apps
2. Build your production app with `ZC=1`
3. Test OTA updates by deploying changes to remotes
4. Monitor deployments in the Zephyr Cloud dashboard