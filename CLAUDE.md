# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter business management application called "Mashallah Mobile Center" - a comprehensive system for managing a mobile accessories shop with additional business services like photocopying, printing, etc. The app uses Firebase for backend services and follows clean architecture patterns.

## Development Commands

### Core Flutter Commands
- `flutter run` - Run the app in debug mode on connected device/emulator
- `flutter run --release` - Run the app in release mode
- `flutter hot-reload` - Hot reload changes (press 'r' in terminal or save files)
- `flutter hot-restart` - Hot restart the app (press 'R' in terminal)

### Build Commands
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app (requires macOS and Xcode)
- `flutter build web` - Build for web deployment
- `flutter build macos` - Build macOS desktop app
- `flutter build linux` - Build Linux desktop app
- `flutter build windows` - Build Windows desktop app

### Testing and Quality
- `flutter test` - Run all unit and widget tests
- `flutter test test/widget_test.dart` - Run specific test file
- `flutter analyze` - Run static analysis and linting
- `dart format .` - Format all Dart code in the project

### Dependencies and Cleanup
- `flutter pub get` - Install dependencies from pubspec.yaml
- `flutter pub upgrade` - Upgrade dependencies to latest versions
- `flutter clean` - Clean build cache and artifacts
- `flutter pub deps` - Show dependency tree

### Platform-specific Commands
- `flutter emulators` - List available emulators
- `flutter devices` - List connected devices
- `flutter doctor` - Check Flutter installation and environment

## Architecture

### Project Structure
- `lib/` - Main Dart source code
  - `main.dart` - App entry point with Firebase initialization and providers
  - `core/` - Core application components
    - `constants/` - App constants, routes, and configuration
    - `services/` - Firebase and other service implementations
    - `utils/` - Utility classes (theme, router)
    - `widgets/` - Reusable UI components (main layout)
  - `features/` - Feature-based modules
    - `auth/` - Authentication (login, register, providers)
    - `dashboard/` - Main dashboard screen
    - `inventory/` - Product inventory management
    - `sales/` - Sales transactions
    - `services/` - Service management (photocopying, etc.)
    - `reports/` - Analytics and reporting
- `test/` - Widget and unit tests
- `web/` - Web-specific assets and Firebase config
- Platform folders: `android/`, `ios/`, `macos/`, `linux/`, `windows/`

### Technology Stack
- **State Management**: Provider pattern
- **Navigation**: go_router for declarative routing
- **Backend**: Firebase (Auth, Firestore, Storage)
- **UI**: Material Design 3 with custom theming
- **Forms**: form_field_validator for validation

### Key Dependencies
- firebase_core, firebase_auth, cloud_firestore, firebase_storage
- provider (state management)
- go_router (navigation)
- material_design_icons_flutter (extended icons)
- form_field_validator, image_picker, file_picker

## Platform Support
This project is configured for multi-platform deployment:
- Android (SDK 35.0.0 required)
- iOS (Xcode 16.2+ required)
- Web
- macOS
- Linux  
- Windows

## Firebase Setup Required
Before running the app, you need to:
1. Create a Firebase project at https://console.firebase.google.com
2. Enable Authentication, Firestore, and Storage
3. Add web configuration to `web/firebase-config.js`
4. Update `web/index.html` to include Firebase SDK

## Authentication & User Roles
- Three user roles: admin, manager, employee
- Firebase Authentication with email/password
- User profiles stored in Firestore users collection
- Role-based access control (to be implemented)

## Business Features
- **Inventory**: Mobile accessories and product management
- **Sales**: Point of sale transactions
- **Services**: Additional services (photocopying, printing, etc.)
- **Customers & Suppliers**: Contact management
- **Reports**: Sales analytics and business insights

## Testing
- Widget tests are in `test/widget_test.dart`
- Uses `flutter_test` package for testing framework
- Run individual tests: `flutter test test/widget_test.dart`
- Test coverage: `flutter test --coverage`

## DETAILED FEATURE IMPLEMENTATION

### 1. Authentication System (`features/auth/`)

**Implementation Details:**
- **Files**: `auth_provider.dart`, `login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart`
- **State Management**: Uses Provider pattern with `AuthProvider`
- **Firebase Integration**: Firebase Auth for email/password authentication
- **Features Implemented**:
  - User login with email validation and error handling
  - User registration with form validation
  - Password reset functionality
  - Authentication state management
  - Route guards for authenticated/unauthenticated users

**Key Components:**
- `AuthProvider`: Manages authentication state, sign in/out methods
- `LoginScreen`: Full login form with validation, error display, loading states
- Automatic navigation based on auth state in `app_router.dart`

### 2. Main Layout & Navigation (`core/widgets/main_layout.dart`)

**Implementation Details:**
- **Sidebar Navigation**: Fixed 280px width sidebar with all feature links
- **Top AppBar**: Shows current page title, notifications icon, user profile menu
- **Responsive Design**: Uses Row layout with sidebar + main content area
- **User Profile**: Shows user avatar, name, email in sidebar footer
- **Navigation Items**: Dashboard, Inventory, Sales, Services, Customers, Udhar, Expenses, Reports, Settings

**Key Features:**
- Route-based active state highlighting
- User sign-out confirmation dialog
- Gradient backgrounds and proper Material Design styling

### 3. Dashboard (`features/dashboard/`)

**Implementation Details:**
- **File**: `dashboard_screen.dart`
- **Features Implemented**:
  - Welcome header with user greeting and business tagline
  - Quick stats cards (Total Sales, Products, Services, Customers) - currently showing placeholder "0" values
  - Quick actions grid with navigation to key features
  - Recent activities section (placeholder with empty state)

**Components:**
- Responsive grid layouts for stats and actions
- Color-coded action cards with icons
- Gradient backgrounds for visual appeal
- Adaptive layout based on screen width

### 4. Inventory Management (`features/inventory/`)

**Implementation Details:**
- **Files**: `inventory_provider.dart`, `inventory_screen.dart`, `product_model.dart`
- **Full CRUD Operations**: Add, read, update, delete products
- **Features Implemented**:
  - Product form with validation (name, category, prices, stock levels)
  - Product listing in DataTable format
  - Category filtering with filter chips
  - Search functionality
  - Stock level monitoring (low stock warnings)
  - Purchase/selling price tracking

**Key Components:**
- `InventoryProvider`: State management for products, CRUD operations
- `Product` model: Complete product data structure
- Form validation with proper error messages
- Auto-calculation of selling price (2x purchase price)
- Status indicators (In Stock, Low Stock, Out of Stock)

**Database Structure:**
- Products stored in Firestore with fields: name, category, purchasePrice, sellingPrice, currentStock, minStockLevel, description, timestamps

### 5. Sales System (`features/sales/`)

**Implementation Details:**
- **Files**: `sales_provider.dart`, `sales_screen.dart`, `sale_model.dart`
- **Features**: Sales transaction management, POS interface structure
- **Data Model**: Sale records with customer info, items, totals, timestamps

### 6. Services Module (`features/services/`)

**Implementation Details:**
- **Files**: `photocopy_provider.dart`, `services_screen.dart`
- **Purpose**: Manage additional business services (photocopying, printing, lamination, etc.)
- **Provider**: PhotocopyProvider for service state management

### 7. Customer Management (`features/customers/`)

**Implementation Details:**
- **Files**: `customer_provider.dart`, `customers_screen.dart`, `customer_model.dart`, `credit_transaction_model.dart`
- **Features**:
  - Customer profiles with contact information
  - Credit transaction tracking ("Udhar" system)
  - Customer detail screens
- **Udhar System**: Separate screen for managing credit/debt transactions

### 8. Expenses Tracking (`features/expenses/`)

**Implementation Details:**
- **Files**: `expense_provider.dart`, `expenses_screen.dart`
- **Purpose**: Track business expenses with categorization
- **State Management**: ExpenseProvider for expense operations

### 9. Categories Management (`features/categories/`)

**Implementation Details:**
- **Files**: `category_provider.dart`
- **Purpose**: Manage product and service categories
- **Constants**: Mobile accessory categories defined in `app_constants.dart`

### 10. Reports & Analytics (`features/reports/`)

**Implementation Details:**
- **Files**: `reports_screen.dart`
- **Purpose**: Business analytics and reporting dashboard
- **Planned Features**: Sales reports, inventory reports, service reports

## FIREBASE CONFIGURATION

**Service Setup** (`core/services/firebase_service.dart`):
- Singleton pattern implementation
- Web and mobile platform configuration
- Authentication state stream management
- Firestore and Storage instance access

**Current Configuration**:
- Project ID: `mashaallahmobileshop-6ef8a`
- Web API keys are hardcoded (should be moved to environment variables)
- Authentication, Firestore, and Storage enabled

## STATE MANAGEMENT ARCHITECTURE

**Provider Pattern Implementation**:
- All feature providers registered in `main.dart` with MultiProvider
- Each provider handles its domain-specific state and operations
- Providers: AuthProvider, InventoryProvider, PhotocopyProvider, SalesProvider, CustomerProvider, ExpenseProvider, CategoryProvider

**Provider Responsibilities**:
- API calls to Firebase services
- Local state management
- Error handling and loading states
- Business logic for CRUD operations

## ROUTING SYSTEM

**go_router Implementation** (`core/utils/app_router.dart`):
- Declarative routing with route guards
- Authentication-based redirects
- Shell routing for main layout
- No-transition pages for smooth navigation

**Route Structure**:
- Auth routes: `/login`, `/register`, `/forgot-password`
- Main routes: `/` (dashboard), `/inventory`, `/sales`, `/services`, `/customers`, `/udhar`, `/expenses`, `/reports`
- Nested routes planned for detail views

## UI/UX IMPLEMENTATION

**Material Design 3**:
- Custom theme implementation in `app_theme.dart`
- Light/dark theme support
- Responsive design patterns
- Consistent color scheme and typography

**Component Patterns**:
- Card-based layouts for data display
- DataTable for list views
- Form validation with proper error states
- Loading indicators and empty states
- Confirmation dialogs for destructive actions

## CURRENT LIMITATIONS & TODO

1. **Dashboard Data**: Stats cards show placeholder "0" values - need integration with real data
2. **Real-time Updates**: Consider adding Firestore listeners for live data updates
3. **Image Support**: Image picker dependency added but not yet implemented in inventory
4. **Role-based Access**: User roles defined but access control not implemented
5. **Testing Coverage**: Limited test coverage, needs expansion
6. **Environment Config**: Firebase keys should be moved to environment variables
7. **Error Handling**: Could be enhanced with better user feedback
8. **Offline Support**: Consider implementing offline capabilities
9. **Performance**: Large lists could benefit from pagination
10. **Security Rules**: Firestore security rules need to be configured