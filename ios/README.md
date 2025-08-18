# GuardtheLife iOS App

Native iOS application built with Swift and SwiftUI for the GuardtheLife platform.

## 🍎 Features

- **Native iOS Experience**: Built with Swift and SwiftUI for optimal performance
- **Modern UI/UX**: Clean, intuitive interface following iOS design guidelines
- **Tab-Based Navigation**: Easy access to all app features
- **Authentication System**: Secure login and user management
- **Lifeguard Booking**: Find and book available lifeguards
- **Emergency Features**: Quick access to emergency services
- **Location Services**: GPS integration for finding nearby services
- **Push Notifications**: Real-time updates and alerts

## 🛠️ Technical Stack

- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **iOS Target**: iOS 17.0+
- **Architecture**: MVVM (Model-View-ViewModel)
- **Dependencies**: Swift Package Manager
- **Build System**: Xcode 15.0+

## 📱 App Structure

```
GuardtheLife/
├── AppDelegate.swift          # App lifecycle management
├── SceneDelegate.swift        # UI scene management
├── ContentView.swift          # Main app view with tab navigation
├── Views/                     # Individual view components
│   ├── HomeView.swift         # Home screen with main actions
│   ├── LifeguardView.swift    # Lifeguard listing and booking
│   ├── BookingView.swift      # User's booking history
│   └── ProfileView.swift      # User profile and settings
├── Models/                    # Data models
├── ViewModels/                # Business logic and state management
├── Services/                  # API and external service integration
├── Utilities/                 # Helper functions and extensions
└── Resources/                 # Assets, localization, and configuration
```

## 🚀 Getting Started

### Prerequisites

- **Xcode 15.0+** (Download from App Store)
- **iOS 17.0+** device or simulator
- **Apple Developer Account** (for device testing and App Store deployment)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/lmckeown27/GuardtheLife.git
   cd GuardtheLife/frontend/ios
   ```

2. **Open in Xcode**
   ```bash
   open GuardtheLife.xcodeproj
   ```

3. **Configure signing**
   - Select your team in project settings
   - Update bundle identifier if needed
   - Configure provisioning profiles

4. **Build and Run**
   - Select target device/simulator
   - Press ⌘+R to build and run

### Development Workflow

1. **Open Xcode Project**
   ```bash
   open GuardtheLife.xcodeproj
   ```

2. **Select Target Device**
   - iOS Simulator for development
   - Physical device for testing

3. **Build and Test**
   - ⌘+B to build
   - ⌘+R to run
   - ⌘+U to run tests

## 🏗️ Project Configuration

### Bundle Identifier
```
com.guardthelife.app
```

### Deployment Target
- **Minimum**: iOS 17.0
- **Target**: iOS 17.0+

### Supported Devices
- iPhone (all models)
- iPad (all models)

### Orientation Support
- **iPhone**: Portrait, Landscape Left, Landscape Right
- **iPad**: All orientations

## 📋 Key Features Implementation

### Authentication
- Login/logout functionality
- User session management
- Secure credential storage

### Navigation
- Tab-based main navigation
- Stack navigation for detail views
- Modal presentations for forms

### Data Management
- Local data persistence
- API integration with backend
- Real-time updates via WebSocket

### Location Services
- GPS integration
- Location permissions
- Geofencing capabilities

### Push Notifications
- Firebase Cloud Messaging
- Local notifications
- Background app refresh

## 🔧 Development Guidelines

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for code quality
- Implement proper error handling

### Architecture
- MVVM pattern for view logic
- Protocol-oriented programming
- Dependency injection for services

### Testing
- Unit tests for business logic
- UI tests for user interactions
- Integration tests for API calls

## 📦 Dependencies

### Core Frameworks
- **SwiftUI**: Modern UI framework
- **Foundation**: Basic iOS functionality
- **CoreLocation**: Location services
- **UserNotifications**: Push notifications

### Third-Party Libraries
- **Alamofire**: HTTP networking
- **SwiftyJSON**: JSON parsing
- **KeychainAccess**: Secure storage
- **Realm**: Local database

## 🚀 Deployment

### Development Build
```bash
# Build for development
xcodebuild -project GuardtheLife.xcodeproj -scheme GuardtheLife -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Production Build
```bash
# Build for production
xcodebuild -project GuardtheLife.xcodeproj -scheme GuardtheLife -configuration Release -destination 'generic/platform=iOS'
```

### App Store Deployment
1. Archive the project in Xcode
2. Upload to App Store Connect
3. Configure app metadata
4. Submit for review

## 🐛 Troubleshooting

### Common Issues

1. **Build Errors**
   - Clean build folder (⌘+Shift+K)
   - Reset package caches
   - Check Swift version compatibility

2. **Simulator Issues**
   - Reset simulator content
   - Update Xcode to latest version
   - Check device compatibility

3. **Signing Issues**
   - Verify team selection
   - Check provisioning profiles
   - Update bundle identifier

## 📚 Resources

- [Swift Documentation](https://swift.org/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

---

**Built with ❤️ using Swift and SwiftUI** 