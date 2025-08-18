# GuardtheLife Frontend

This project supports both **React Web** and **Swift iOS** applications, sharing common business logic and components.

## 🏗️ Project Structure

```
frontend/
├── web/           # React web application
├── ios/           # Swift iOS application  
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

### iOS Development
```bash
npm run ios:open         # Open Swift iOS app in Xcode
npm run ios:build        # Build iOS app (Debug)
npm run ios:build:release # Build iOS app (Release)
```

## 🔧 Development Workflow

1. **Shared Code**: Place common business logic in `src/` directory
2. **Web-Specific**: Platform-specific code goes in `web/src/`
3. **iOS-Specific**: Platform-specific code goes in `ios/GuardtheLife/`
4. **Dependencies**: Use `shared/` for common packages

## 📱 Platforms Supported

- **Web**: React 18 + TypeScript
- **iOS**: Swift 5.9+ + SwiftUI
- **Build**: Xcode for iOS, React Scripts for web
- **Deploy**: Web to any hosting, iOS to App Store

## 🎯 Benefits

- **Code Sharing**: Common business logic across platforms
- **Platform Optimization**: Native features for iOS, web features for browser
- **Unified Development**: Single repository, multiple targets
- **Flexible Deployment**: Choose your target platform 