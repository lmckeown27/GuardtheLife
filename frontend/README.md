# GuardtheLife Frontend

This project supports both **React Web** and **Expo Mobile** applications, sharing common business logic and components.

## 🏗️ Project Structure

```
frontend/
├── web/           # React web application
├── mobile/        # Expo mobile application  
├── shared/        # Shared dependencies
└── src/           # Common source code (to be moved)
```

## 🚀 Quick Start

### Install All Dependencies
```bash
npm run install:all
```

### Web Development
```bash
npm run web:start      # Start React dev server
npm run web:build      # Build for production
```

### Mobile Development
```bash
npm run mobile:start      # Start Expo dev server
npm run mobile:android    # Run on Android
npm run mobile:ios        # Run on iOS
npm run mobile:web        # Run on web via Expo
```

### Mobile Builds (EAS)
```bash
npm run mobile:build:all      # Build for all platforms
npm run mobile:build:android  # Build Android APK/AAB
npm run mobile:build:ios      # Build iOS IPA
npm run mobile:build:web      # Build web version
```

## 🔧 Development Workflow

1. **Shared Code**: Place common business logic in `src/` directory
2. **Web-Specific**: Platform-specific code goes in `web/src/`
3. **Mobile-Specific**: Platform-specific code goes in `mobile/src/`
4. **Dependencies**: Use `shared/` for common packages

## 📱 Platforms Supported

- **Web**: React 18 + TypeScript
- **Mobile**: Expo SDK 49 + React Native
- **Build**: EAS Build for cloud-based compilation
- **Deploy**: Web to any hosting, Mobile to app stores

## 🎯 Benefits

- **Code Sharing**: Common business logic across platforms
- **Platform Optimization**: Native features for mobile, web features for browser
- **Unified Development**: Single repository, multiple targets
- **Flexible Deployment**: Choose your target platform 