# AURCM Route Flutter App

## Phase 2 Setup Complete

### Flutter Version
Flutter 3.44.0 | Dart 3.12.0

### Project ID
`com.aurcm.aurcm_route`

### How to Run
```bash
flutter run --dart-define=BASE_URL=http://<your-server-ip>:3000
```

### Google Maps Setup
Add your API key to `android/local.properties`:
```
GOOGLE_MAPS_API_KEY=AIzaSy...
```

### Development Environment
- Backend: http://10.0.2.2:3000 (Android emulator → localhost)
- Socket: http://10.0.2.2:3000
- Physical device: Replace with your machine's LAN IP

### Architecture Notes
- Clean Architecture with feature-based folders
- State: Riverpod 2 (AsyncNotifier pattern)  
- Navigation: GoRouter with auth guards
- HTTP: Dio with JWT interceptor + silent refresh
- Storage: flutter_secure_storage (AES-256, Android Keystore)
- Realtime: socket_io_client
