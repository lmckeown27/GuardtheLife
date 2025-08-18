# EAS Workflows

This directory contains EAS Build workflow configurations for automated builds of the GuardtheLife mobile application.

## 📱 Available Workflows

### 1. Production Builds
**File**: `create-production-builds.yml`
- Builds production-ready APK/AAB for Android
- Builds production-ready IPA for iOS
- Runs in parallel for efficiency

### 2. All Platform Builds
**File**: `create-all-platform-builds.yml`
- Builds for Android, iOS, and Web
- Uses production profile
- Non-interactive mode for CI/CD

### 3. Development Builds
**File**: `create-development-builds.yml`
- Development builds for testing
- Internal distribution
- Faster build times

## 🚀 Usage

### Run a Workflow
```bash
# From project root
eas workflow run create-production-builds

# Or from mobile directory
cd frontend/mobile
eas workflow run create-production-builds
```

### List Available Workflows
```bash
eas workflow list
```

### View Workflow Status
```bash
eas workflow view <workflow-id>
```

## ⚙️ Configuration

### Workflow Parameters
- **platform**: Target platform (android, ios, web)
- **profile**: Build profile (development, preview, production)
- **non_interactive**: Set to true for automated builds

### Build Profiles
Configure build profiles in `frontend/mobile/eas.json`:
- **development**: Fast builds for testing
- **preview**: Internal distribution builds
- **production**: App store ready builds

## 🔧 Prerequisites

1. **EAS CLI**: `npm install -g @expo/cli`
2. **EAS Account**: Logged in with `eas login`
3. **Project Setup**: Configured in `frontend/mobile/eas.json`
4. **Build Profiles**: Defined in `frontend/mobile/eas.json`

## 📋 Example Commands

```bash
# Build all platforms for production
eas workflow run create-all-platform-builds

# Build only Android for development
eas workflow run create-development-builds --job build_android_dev

# Build iOS for production
eas workflow run create-production-builds --job build_ios
```

## 🎯 Benefits

- **Automated Builds**: No manual intervention required
- **Parallel Execution**: Multiple platforms build simultaneously
- **CI/CD Integration**: Perfect for automated deployment pipelines
- **Consistent Builds**: Same configuration every time
- **Time Saving**: Automated workflow management 