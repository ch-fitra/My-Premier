# My Premier Mobile Sales App

Flutter mobile application for the My Premier Sales team.

## Features

- **Authentication**: JWT-based login with email and password
- **Dashboard**: Overview of requests and supports with statistics
- **Request Info Management**: View and search client requests
- **Support & Chat**: Manage support tickets and chat with clients
- **Product Catalog**: Browse products (read-only)

## Setup

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Update API base URL in `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:8080'; // Change to your backend URL
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point with auth wrapper
├── services/
│   └── api_service.dart      # API service with JWT interceptor
└── screens/
    ├── login_screen.dart     # Login screen
    ├── dashboard_screen.dart  # Main dashboard with navigation
    ├── requests_screen.dart   # Request info list
    ├── supports_screen.dart   # Support tickets list
    ├── support_chat_screen.dart # Chat interface for support
    ├── products_screen.dart   # Product catalog
    └── profile_screen.dart   # User profile and logout
```

## API Endpoints

All endpoints require JWT authentication (except login).

### Authentication
- `POST /auth/login` - Login with email and password
- `GET /admin/me` - Get current user info

### Dashboard
- `GET /admin/requests` - Get all requests
- `GET /admin/supports` - Get all supports

### Support & Chat
- `GET /admin/supports/{support_id}/messages` - Get messages in a support thread
- `POST /admin/supports/{support_id}/messages` - Reply to a support thread

### Products
- `GET /admin/products` - Get all products (read-only)

## Authentication Flow

1. User logs in with email and password
2. JWT token is stored in SharedPreferences
3. Token is automatically attached to all API requests
4. On 401 response, token is cleared and user is redirected to login

## Notes

- The app uses Material Design 3
- All API requests include automatic JWT token handling
- 401 responses automatically trigger logout and redirect to login
- Product catalog is read-only (no create/update/delete)

