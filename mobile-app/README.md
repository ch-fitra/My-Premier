# My Premier Mobile App

A Flutter mobile application for PT Premier Engineering Indonesia with multi-role support (Client, Sales, Engineer).

## Architecture

```
lib/
├─ auth/
│  ├─ login_screen.dart
│  └─ auth_service.dart
├─ core/
│  ├─ api_client.dart
│  ├─ models/
│  │  └─ user_model.dart
│  └─ guards/
│     └─ auth_guard.dart
├─ client/
│  └─ screens/
│     └─ client_home_screen.dart
├─ sales/
│  └─ screens/
│     └─ sales_dashboard_screen.dart
├─ engineer/
│  └─ screens/
│     └─ engineer_dashboard_screen.dart
├─ shared/
│  └─ widgets/
└─ main.dart
```

## Features

### Authentication
- JWT-based authentication
- Secure token storage using SharedPreferences
- Automatic token attachment to API requests
- 401 handling with automatic logout

### Role-Based Routing
After login, users are automatically routed based on their role:
- **Client** → `ClientHomeScreen`
- **Sales** → `SalesDashboardScreen`
- **Engineer** → `EngineerDashboardScreen`

### API Client
- Centralized API client with JWT interceptor
- Base URL: `http://localhost:8080`
- Automatic 401 handling

## Setup

1. Install dependencies:
```bash
flutter pub get
```

2. Update API base URL in `lib/core/api_client.dart` if needed

3. Run the app:
```bash
flutter run
```

## API Endpoints

### Authentication
- `POST /auth/login` - Login with email and password
- `GET /admin/me` - Get current user info

## Next Steps

1. Implement Sales screens (Dashboard, Requests, Supports, Products)
2. Implement Client screens (Product Catalog, Request Info, Support)
3. Implement Engineer screens (Daily Reports)

