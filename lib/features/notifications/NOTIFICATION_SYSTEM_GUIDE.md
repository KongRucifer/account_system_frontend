# Notification System Architecture Guide

## Overview
This document explains the complete notification system implementation, including Firebase integration, WebSocket communication, and multi-device synchronization.

## File Structure and Responsibilities

### 1. `firebase_messaging_service.dart`
**Purpose**: Core Firebase Cloud Messaging (FCM) service handling all notification reception and display.

#### Key Components:

##### Global Variables
```dart
typedef NotificationTapCallback = Future<void> Function(String notificationId);
NotificationTapCallback? _globalNotificationTapCallback;
String? _pendingNotificationId; // For notifications tapped before callback is ready
```

##### Background Message Handler
```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async
```
- **Purpose**: Handles notifications when app is in background or terminated
- **Called by**: Android system when FCM message arrives
- **Actions**: 
  - Initializes Firebase
  - Sets up local notifications
  - Shows notification with sound

##### Notification Tap Handler
```dart
void onNotificationTap(NotificationResponse response)
```
- **Purpose**: Handles user taps on toast notifications
- **Actions**:
  - Stops sound immediately via `LocalNotificationService.cancelRepeating()`
  - Calls global callback to mark notification as read
  - Works even when app is closed

##### FirebaseMessagingService Class
- **initialize()**: Sets up FCM, requests permissions, registers handlers
- **_handleForegroundMessage()**: Handles messages when app is active
- **_handleMessageOpenedApp()**: Handles app launches from notifications

### 2. `notification_provider.dart`
**Purpose**: State management for notifications using Riverpod, handles WebSocket communication and UI updates.

#### Key Components:

##### NotificationsNotifier Class
- **_initialize()**: Sets up WebSocket connection and registers tap callback
- **_connectWebSocket()**: Establishes WebSocket connection for real-time updates
- **_handleNewNotification()**: Processes incoming notifications, plays sound
- **_handleNotificationRead()**: Handles read status from other devices
- **markAsRead()**: Marks notification as read and syncs across devices

##### WebSocket Integration
```dart
_webSocketService.markAsRead(notificationId); // Send to other devices
await _repository.markAsRead(notificationId, _username!); // Update backend
```

### 3. `notification_service.dart`
**Purpose**: WebSocket client for real-time multi-device synchronization.

#### Key Components:

##### NotificationWebSocketService Class
- **connect()**: Establishes WebSocket connection with authentication
- **markAsRead()**: Sends read status to all connected devices
- **markAllAsRead()**: Broadcasts read-all status
- **Event Handlers**: Listens for notification events from other devices

##### WebSocket Events
- `new_notification`: New notification received
- `notification_read`: Notification marked as read on another device
- `all_notifications_read`: All notifications marked as read

### 4. `notification_repository.dart`
**Purpose**: API client for backend notification operations.

#### Key Methods:
- `getAllNotifications()`: Fetch user notifications with pagination
- `markAsRead()`: Mark specific notification as read
- `markAllAsRead()`: Mark all notifications as read
- `updateFcmToken()`: Register device token with backend

### 5. `notification_model.dart`
**Purpose**: Data models for notifications.

#### Key Models:
- `MeetingNotification`: Individual notification with read status
- `NotificationResponse`: API response with notifications and metadata
- `PaginationInfo`: Pagination details

### 6. `notifications_page.dart`
**Purpose**: UI for displaying and managing notifications.

#### Key Features:
- List view with read/unread status
- Multiple ways to mark as read:
  - Tap notification
  - Click check button
  - Swipe to dismiss
- Mark all as read functionality
- Real-time updates via WebSocket

### 7. `notification_sound_service.dart`
**Purpose**: Manages notification sound playback and cancellation.

#### Key Methods:
- `playNotificationSound()`: Start repeating sound
- `stopNotificationSound()`: Stop sound immediately
- Sound loops until explicitly stopped

### 8. `fcm_registration_service.dart`
**Purpose**: Manages FCM token registration and device management.

#### Key Methods:
- `registerToken()`: Register device token with username
- `deactivateToken()`: Deactivate token on logout
- `_getDeviceId()`: Generate unique device identifier

## Firebase Integration

### Firebase Configuration (`firebase_options.dart`)
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyDM46xhb0oCO34RoRR-BGlFVRuwLryxwfc',
  appId: '1:351785621643:android:ed6db39c8d47c5a4a41c8e',
  messagingSenderId: '351785621643',
  projectId: 'lanxangaap',
  storageBucket: 'lanxangaap.firebasestorage.app',
);
```

### Firebase Initialization Flow
1. **main.dart**: Initialize Firebase app
2. **firebase_messaging_service.dart**: Set up background handler
3. **Request permissions**: Get notification permissions
4. **Get FCM token**: Unique device token
5. **Register token**: Send to backend with username

### Message Handling Flow
```
FCM Message → Android System → Background Handler → Local Notification → User Sees Toast
     ↓
User Taps → onNotificationTap → Stop Sound → Mark as Read → WebSocket Sync → Other Devices Update
```

## Multi-Device Synchronization

### WebSocket Communication
1. **Device A** marks notification as read
2. **WebSocket** sends `notification_read` event
3. **Device B** receives event via WebSocket
4. **Device B** stops sound and updates UI
5. **Both devices** show consistent state

### Sound Synchronization
- Each device manages its own sound
- WebSocket events trigger sound cancellation
- `LocalNotificationService.cancelRepeating()` stops timer
- `NotificationSoundService.stopNotificationSound()` stops audio

## Android Manifest Configuration

### Required Permissions
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### Services
```xml
<service android:name="com.google.firebase.messaging.FirebaseMessagingService">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

## Notification Flow Examples

### 1. New Notification Received
```
Backend → FCM → Device A/Device B → Background Handler → Local Notification → Sound Starts
```

### 2. User Taps Toast on Device A
```
Device A: Tap → Stop Sound → Mark as Read → WebSocket → API Update
Device B: WebSocket Event → Stop Sound → Update UI → Show as Read
```

### 3. App Closed, Notification Arrives
```
FCM → Background Handler → Show Notification → User Taps → App Opens → Stop Sound → Mark as Read
```

## Debug Logging

### Key Log Messages
- `🔔 BACKGROUND HANDLER TRIGGERED`: Background message received
- `📩 FOREGROUND HANDLER`: Foreground message received
- `👆 NOTIFICATION TAPPED`: User tapped toast notification
- `🔇 CANCEL REPEATING STARTED`: Sound cancellation initiated
- `📨 NOTIFICATION READ RECEIVED FROM OTHER DEVICE`: Multi-device sync

### Using the Log Viewer
1. Open Dashboard → Click "App Logs"
2. Use filters: "Notifications", "Sound", "WebSocket"
3. Search for specific notification IDs or errors

## Troubleshooting Common Issues

### Background Notifications Not Working
- Check Android battery optimization settings
- Verify FCM token is registered with backend
- Ensure background handler is properly registered

### Sound Not Stopping
- Verify `cancelRepeating()` is called
- Check WebSocket connection for multi-device sync
- Ensure notification tap callback is registered

### Multi-Device Sync Issues
- Check WebSocket connection status
- Verify both devices use same account
- Look for WebSocket event logs

## Performance Optimizations

### Immediate Background Detection
- Simplified lifecycle state checking
- Removed artificial delays
- Instant notification processing

### Efficient Sound Management
- Timer-based sound repetition
- Immediate cancellation on user action
- Session token management for multiple notifications

### WebSocket Optimization
- Automatic reconnection
- Connection status monitoring
- Event-driven updates only

## Security Considerations

### Token Management
- Unique device IDs per installation
- Token deactivation on logout
- Secure token transmission to backend

### WebSocket Authentication
- JWT token-based authentication
- Automatic token refresh
- Secure connection (WSS)

This architecture ensures reliable, real-time notification delivery across multiple devices with proper sound management and user interaction handling.
