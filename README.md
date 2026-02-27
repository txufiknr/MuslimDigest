# Muslim Digest Mobile App

![Flutter](https://img.shields.io/badge/flutter-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/dart-0175C2?logo=dart)
![Android](https://img.shields.io/badge/android-3DDC84?logo=android)
![iOS](https://img.shields.io/badge/ios-000000?logo=ios)
![License](https://img.shields.io/badge/license-proprietary-red)

## Overview

<div align="left">
  <img src="assets/images/icons/icon.png" align="left" alt="MuslimDigest Icon" width="150" height="150" style="float: left; margin-right: 20px; margin-bottom: 20px; max-width: 50%; object-fit: contain; aspect-ratio: 1/1;">
  <strong>Muslim Digest</strong> is a mobile application that aims to provide Muslims with a one-stop platform for news and information. The app offers a clean and organized collection of Muslim-related articles, summarized to cater to the busy lifestyle of Muslim individuals. With its intuitive interface, the app offers a seamless user experience, making it an essential tool for those seeking to stay updated on the latest happenings in the Muslim community. Built with Flutter, a framework that allows for cross-platform development, the app is designed to provide a consistent and engaging experience across Android and iOS devices. The app showcases the latest design techniques, ensuring a visually appealing and user-friendly interface that caters to the needs of Muslims worldwide.
</div>
<div style="clear: both;"></div>

## Core Stack

| Choice | Why |
| ------ | --- |
| 📱 **Flutter** (Framework) | Cross-platform, fast development, beautiful UI |
| 🎯 **Dart** (Language) | Type-safe, optimized for Flutter |
| 🗺️ **Go Router** (Navigation) | Declarative routing, deep linking support |
| 🌙 **Theme Provider** (Theming) | Runtime theme switching, persistence |
| 💾 **Shared Preferences** (Storage) | User preferences and settings persistence |
| 🔐 **Flutter Secure Storage** (Cache) | Secure feed caching with dynamic keys |
| 🌐 **HTTP** (API Client) | RESTful API communication |
| 🔗 **URL Launcher** (External Links) | In-app browser and external links |
| 🆔 **UUID** (User IDs) | Standard unique identifier generation |
| ⚙️ **Flutter Dotenv** (Environment) | Environment variable management |

## Core Principles

### 🎨 Modern UI/UX Design
- **Material 3 Design** - Following Google's latest design system
- **Theme Support** - Light and dark themes with runtime switching
- **Responsive Layout** - Optimized for various screen sizes
- **Smooth Animations** - Engaging micro-interactions and transitions

### 🚀 Performance Optimizations
- **Route Preloading** - Faster navigation with preloaded routes
- **Efficient State Management** - Minimal rebuilds and optimal performance
- **Image Caching** - Optimized image loading and caching
- **Lazy Loading** - Load content as needed for better performance

### 🔒 Security & Privacy
- **Environment Variables** - Secure API endpoint configuration
- **Platform-Native Secure Storage** - Feed caching using iOS Keychain and Android Keystore
- **Dynamic Cache Keys** - Flexible caching without storage restrictions
- **Encrypted Local Storage** - User preferences and settings protection
- **Privacy Controls** - User consent and data management
- **Secure Communication** - HTTPS API communication

## Key Features

### 👤 User Onboarding
- **Welcome Wizard** - Step-by-step user registration
- **Personalization** - Name, gender, and age group preferences
- **Skip Options** - Privacy-respecting optional information
- **UUID v7** - Modern, unique user identification

### 🎨 Theme System
- **Dynamic Theming** - Runtime theme switching
- **Persistent Preferences** - Theme selection saved locally
- **Consistent Design** - Unified color palette and typography
- **Accessibility** - High contrast and readable text

### 🧭 Navigation System
- **Declarative Routing** - Clean, maintainable navigation
- **Deep Linking** - Direct access to specific screens
- **Route Preloading** - Faster page transitions
- **Splash Screen** - Engaging app initialization

### 🌐 API Integration
- **HTTP Client** - Robust API communication
- **Error Handling** - Graceful error management
- **Environment Config** - Development and production endpoints
- **Secure Feed Caching** - Dynamic cache with expiration and metadata

### 📝 Content Management
- **Smart Feed Filtering** - "Not interested" and content reporting
- **Dynamic Placeholders** - Context-aware UI for filtered content
- **Undo Functionality** - Restore filtered content with one tap
- **Feedback System** - Categorized content reporting with follow-up actions

## Available Scripts

### Development
- `flutter run` - Run app in development mode
- `flutter run --debug` - Debug mode with hot reload
- `flutter run --profile` - Profile mode for performance testing
- `flutter run --release` - Release mode testing

### Build & Quality
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build apk --release` - Production Android build
- `flutter analyze` - Run static analysis
- `flutter test` - Run unit and widget tests

### Code Generation
- `flutter packages pub run build_runner build` - Generate code
- `flutter packages pub run build_runner watch` - Watch for changes

## Environment Configuration

### Setup Environment Variables
1. Copy `.env.example` to `.env`
2. Configure your environment variables:
   ```bash
   # API Configuration
   APP_URL_API=your-production-api-url-here
   APP_URL_API_DEV=http://localhost:3000/api
   ```

### Required Environment Variables
- `APP_URL_API` - Production API endpoint
- `APP_URL_API_DEV` - Development API endpoint

## Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK
- Android Studio / Xcode
- Git

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/txufiknr/MuslimDigest.git
   cd MuslimDigest/frontend
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure environment:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. Run the app:
   ```bash
   flutter run
   ```

### Development Setup
1. Set up your development environment
2. Configure `.env` file with development endpoints
3. Run `flutter run` to start development server
4. Use `flutter hot-reload` for fast iteration

## Project Structure

```
lib/
├── config/           # Configuration files
├── screens/          # Screen widgets
├── services/         # API and business logic
├── utils/            # Utility functions
├── widgets/          # Reusable components
│   ├── components/   # UI components
│   └── animations/   # Animation widgets
└── main.dart         # App entry point
```

## Architecture Patterns

### 🏗️ Clean Architecture
- **Separation of Concerns** - UI, business logic, and data layers
- **Dependency Injection** - Loose coupling and testability
- **Single Responsibility** - Each component has one clear purpose
- **Testable Code** - Easy unit and integration testing

### 🎯 Widget Organization
- **Screen Widgets** - Full-screen components
- **Component Widgets** - Reusable UI elements
- **Animation Widgets** - Custom animations
- **Utility Widgets** - Helper widgets and extensions

## Testing Strategy

### 🧪 Test Types
- **Unit Tests** - Business logic and utility functions
- **Widget Tests** - UI component testing
- **Integration Tests** - End-to-end user flows
- **Performance Tests** - App performance benchmarks

### 📊 Coverage Goals
- **80%+ Code Coverage** - Comprehensive test coverage
- **Critical Path Testing** - Essential user flows
- **Error Scenarios** - Edge cases and error handling
- **Performance Testing** - Memory and CPU usage

## Deployment

### 📱 Android Deployment
1. Configure signing keys
2. Build release APK: `flutter build apk --release`
3. Upload to Google Play Console
4. Configure store listing and screenshots

### 🍎 iOS Deployment
1. Configure App Store Connect
2. Build iOS app: `flutter build ios`
3. Upload to App Store Connect
4. Submit for review

### 🔧 CI/CD Pipeline
- **GitHub Actions** - Automated testing and building
- **Fastlane** - Automated deployment
- **Code Quality** - Automated analysis and linting
- **Security Scanning** - Dependency vulnerability checks

## Useful Links

| Link | Description |
|------|-------------|
| 💻 [GitHub Repo](https://github.com/txufiknr/MuslimDigest) (Source Code) | Main project repository |
| 📱 [Google Play Store](https://play.google.com/store/apps/details?id=com.tarra.muslimdigest) (Android) | Android app distribution |
| 🍎 [App Store](https://apps.apple.com/app/muslim-digest) (iOS) | iOS app distribution |
| 🌐 [Backend Service](https://muslim-digest-backend.vercel.app/) (API) | Production API endpoint |
| 📚 [Flutter Documentation](https://docs.flutter.dev/) (Docs) | Flutter framework documentation |

## License

**Proprietary Software - All Rights Reserved**

### Copyright & Credits
- **Author**: Taufik Nur Rahmanda
- **Copyright**: ©2026 Taufik Nur Rahmanda
- **All rights reserved**

### Usage Terms
This software is proprietary and may not be:
- Redistributed or resold
- Modified or reverse engineered
- Used for commercial purposes without explicit permission
- Included in other software packages without consent

### Technology Stack Licenses
This application is built using open-source technologies with their respective licenses:
- **Flutter** - BSD 3-Clause License
- **Dart** - BSD 3-Clause License
- **Other dependencies** - See individual package licenses

### Contact
For licensing inquiries or permission requests, please contact [flias.test@gmail.com](mailto:flias.test@gmail.com).

---

*This license section applies to the Muslim Digest mobile app codebase only. Third-party dependencies are subject to their own licensing terms as specified in their respective documentation.*
