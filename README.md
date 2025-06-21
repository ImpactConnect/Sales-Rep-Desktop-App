# Sales Rep App

A Flutter desktop application for sales representatives to manage outlets, stock, and sales operations with offline-first capabilities.

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── database/
│   ├── services/
│   │   └── auth_service.dart
├── models/
│   └── user_profile.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── splash_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── sales/
│   ├── stock/
│   └── utils/
└── widgets/
```

## Features Implemented

### Phase 1: Project Setup
- Basic project structure and folder organization
- Essential dependencies configuration
- Environment variables setup for Supabase

### Phase 2: Authentication Implementation
- Email/password authentication using Supabase
- User profile management
- Authentication flow with splash, login, and dashboard screens
- Route management and navigation

## Setup Instructions

1. Clone the repository
2. Create a `.env` file in the root directory with the following variables:
   ```
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Enable Windows desktop support:
   ```bash
   flutter config --enable-windows-desktop
   ```
5. Run the app:
   ```bash
   flutter run -d windows
   ```

## Dependencies

- `supabase_flutter`: Supabase client for Flutter
- `flutter_dotenv`: Environment variables management
- `provider`: State management
- `sqflite`: SQLite database for offline storage
- `path_provider`: File system access
- `uuid`: Unique identifier generation
- `connectivity_plus`: Network connectivity monitoring
- `intl`: Internationalization and formatting

## Development Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart/introduction)

## Next Steps

- Implement offline data synchronization
- Add outlet management features
- Implement stock management
- Create sales entry functionality
- Develop reporting and analytics dashboard
