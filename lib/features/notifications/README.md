# Notification Feature

## Setup Instructions

### 1. Generate Freezed Models

Run this command to generate the required code for the notification models:

```bash
cd account_system_frontend
flutter pub run build_runner build --delete-conflicting-outputs
```

Or if using pnpm:
```bash
cd account_system_frontend
pnpm flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Install Dependencies

```bash
flutter pub get
```

## Files Structure

```
lib/features/notifications/
├── notification_model.dart          # Freezed data models
├── notification_model.freezed.dart # Generated (auto-generated)
├── notification_model.g.dart         # Generated (auto-generated)
├── notification_service.dart         # WebSocket service
├── notification_sound_service.dart   # Sound/Audio service
├── notification_repository.dart      # API repository
├── notification_provider.dart        # Riverpod providers
├── notification_badge.dart           # UI badge widget
├── notifications_page.dart         # Notifications list page
└── README.md                        # This file
```

## Usage

### 1. Add Notification Badge to AppBar

```dart
import 'features/notifications/notification_badge.dart';

AppBar(
  actions: [
    const NotificationBadge(),
  ],
)
```

### 2. Wrap App with NotificationListener

```dart
import 'features/notifications/notification_badge.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      child: MaterialApp(
        // ... your app
      ),
    );
  }
}
```

### 3. Navigate to Notifications Page

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NotificationsPage(),
  ),
);
```

## Features

- ✅ Real-time notifications via WebSocket
- ✅ HTTP polling fallback when WebSocket disconnects
- ✅ Badge showing unread count
- ✅ Mark as read functionality
- ✅ Pull to refresh
- ✅ Swipe to mark as read
- ✅ Test buttons for preview/trigger
- ✅ 🔊 Sound alerts for new notifications (loops until checked)
- ✅ 🔇 Auto-stop sound when opening notifications
- ✅ 🔊 Success sound when marking as read

## WebSocket Events

| Event | Direction | Description |
|-------|-----------|-------------|
| `new_notification` | Server → Client | New notification received |
| `notification_read` | Server → Client | Notification marked as read |
| `mark_as_read` | Client → Server | Mark notification as read |

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/notifications` | GET | Get all notifications |
| `/notifications/unread` | GET | Get unread notifications |
| `/notifications/:id/read` | POST | Mark as read |
| `/notifications/test/preview-meetings` | GET | Preview tomorrow's meetings |
| `/notifications/test/trigger-meeting-reminder` | POST | Trigger cron job manually |

## Sound/Audio Setup

### Adding Sound Files

To use custom notification sounds, add MP3 files to the assets:

1. **Create assets folder:**
   ```bash
   mkdir -p assets/sounds
   ```

2. **Add sound files:**
   - `assets/sounds/notification.mp3` - Main notification sound (loops)
   - `assets/sounds/success.mp3` - Success sound when marking as read

3. **Update pubspec.yaml:**
   ```yaml
   flutter:
     assets:
       - assets/sounds/notification.mp3
       - assets/sounds/success.mp3
   ```

4. **Restart app:**
   ```bash
   flutter pub get
   flutter run
   ```

### Sound Behavior

| Event | Sound Action | Duration |
|-------|--------------|----------|
| New notification arrives | 🔊 Play notification sound | Loops until checked |
| User opens notifications | 🔇 Stop all sounds | Immediate |
| User marks as read | 🔊 Play success sound | Once |
| Swipe to dismiss | 🔇 Stop sound + success sound | Once |

### Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

#### iOS (`ios/Runner/Info.plist`)
Already handled by the audioplayers package.

### Troubleshooting

**No sound playing:**
- Check volume settings
- Verify sound files exist in assets/sounds/
- Run `flutter clean && flutter pub get`
- Check Android/iOS permissions

**Sound doesn't stop:**
- Make sure `stopAllSounds()` is called when opening notifications
- Check if AudioPlayer is properly disposed

**Build errors:**
- Run `flutter pub get` to install audioplayers
- Ensure minimum SDK versions are met
