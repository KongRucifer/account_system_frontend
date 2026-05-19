# ระบบ Notification — อธิบาย Flow การทำงาน (ภาษาไทย)

---

## ภาพรวม Architecture

ระบบ Notification ของ app นี้มี **2 ช่องทางรับ notification** พร้อมกัน:

```
Server (NestJS)
    │
    ├── FCM (Firebase Cloud Messaging)  ──→  แจ้งเตือนตอน Background/Terminated
    │
    └── WebSocket (Socket.IO)           ──→  แจ้งเตือนแบบ Real-time ตอน Foreground
```

---

## ไฟล์และหน้าที่ของแต่ละไฟล์

---

### 1. `notification_model.dart` — โครงสร้างข้อมูล

ไฟล์นี้กำหนด **รูปแบบของข้อมูล** ที่ใช้ในระบบ Notification ทั้งหมด

| Class | หน้าที่ |
|-------|---------|
| `MeetingNotification` | ข้อมูลของ notification 1 รายการ — มี `id`, `message`, `meetingDate`, `vbCode`, `isRead`, `createdAt` |
| `PaginationInfo` | ข้อมูลการแบ่งหน้า — มี `page`, `totalPages`, `hasNext`, `hasPrev` |
| `NotificationResponse` | ผลลัพธ์จาก API — รวม `notifications[]`, `unreadCount`, `pagination` |

ใช้ `@freezed` + `json_serializable` → ทำให้ object เป็น immutable และ serialize/deserialize JSON ได้อัตโนมัติ

---

### 2. `notification_repository.dart` — คุยกับ Backend API

ไฟล์นี้เป็น **ชั้นกลางระหว่าง app กับ Backend** โดยใช้ `Dio` ทำ HTTP request

```
notification_repository.dart
    │
    ├── getAllNotifications(username)     → GET /notifications
    ├── getUnreadNotifications(username)  → GET /notifications/unread
    ├── markAsRead(notificationId)        → POST /notifications/:id/read
    ├── markAllAsRead(username)           → PATCH /notifications/mark-all-read
    ├── updateFcmToken(username, deviceId, token)  → PATCH /users/fcm-token
    ├── previewMeetings()                 → GET /notifications/test/preview-meetings
    └── triggerMeetingReminder()          → POST /notifications/test/trigger-meeting-reminder
```

> **สำคัญ:** `updateFcmToken` ถูกเรียกโดย `FcmRegistrationService` หลัง login สำเร็จ เพื่อส่ง FCM token ใหม่ไปเก็บที่ Server

---

### 3. `notification_service.dart` — WebSocket แบบ Real-time

ไฟล์นี้จัดการ **การเชื่อมต่อ WebSocket** กับ Server ผ่าน Socket.IO

**การทำงาน:**

```
app เปิด → connect() → เชื่อมต่อ /notifications namespace
                      → ส่ง JWT token เป็น auth header

Server emit 'new_notification'        → _notificationController.add({type: 'new_notification', data: ...})
Server emit 'notification_read'       → _notificationController.add({type: 'notification_read', ...})
Server emit 'all_notifications_read'  → _notificationController.add({type: 'all_notifications_read', ...})

app ส่ง mark_as_read  → socket.emit('mark_as_read', {notificationId: ...})
```

- รองรับ reconnect อัตโนมัติ 5 ครั้ง (delay 1–5 วินาที)
- Fallback เป็น HTTP polling ถ้า WebSocket ไม่ได้
- เป็น Singleton — ทั้ง app ใช้ instance เดียวกัน

---

### 4. `notification_sound_service.dart` — เล่นเสียงแจ้งเตือน

ไฟล์นี้จัดการ **เสียง** ของ notification ทั้งหมด ผ่าน `audioplayers` package

| Method | หน้าที่ |
|--------|---------|
| `playNotificationSound(id)` | เล่นเสียง `meeting_sound.mp3` แบบ **loop ไม่หยุด** จนกว่าจะกด |
| `stopNotificationSound()` | หยุดเสียงทันที |
| `playSuccessSound()` | เล่นเสียงสั้นๆ ยืนยัน เมื่อ mark as read |
| `playShortNotificationSound()` | เล่นครั้งเดียว ไม่ loop |

> ไฟล์เสียงอยู่ที่ `assets/sounds/meeting_sound.mp3` (ใช้ตอน Foreground)
> ไฟล์เสียงอีกชุดอยู่ที่ `android/app/src/main/res/raw/meeting_sound.mp3` (ใช้ตอน Background/Terminated ผ่าน notification channel)

---

### 5. `notification_provider.dart` — ศูนย์กลางควบคุม State ทั้งหมด

ไฟล์นี้คือ **หัวใจหลักของระบบ** ใช้ Riverpod `StateNotifier` จัดการทุกอย่าง

**Providers ที่ประกาศไว้:**

| Provider | หน้าที่ |
|----------|---------|
| `notificationRepositoryProvider` | สร้าง `NotificationRepository` |
| `webSocketServiceProvider` | สร้าง `NotificationWebSocketService` |
| `soundServiceProvider` | สร้าง `NotificationSoundService` |
| `notificationsProvider` | **หลัก** — `StateNotifier` ควบคุม state ทั้งหมด |
| `unreadCountProvider` | ดึงแค่จำนวน unread (ใช้กับ Badge) |

**NotificationState** เก็บ:
```dart
notifications[]       // รายการ notification ทั้งหมด
unreadCount           // จำนวนที่ยังไม่อ่าน
isLoading             // กำลังโหลดอยู่หรือเปล่า
isWebSocketConnected  // WebSocket เชื่อมอยู่หรือเปล่า
error                 // ข้อความ error ถ้ามี
pagination            // ข้อมูลการแบ่งหน้า
currentPage           // หน้าปัจจุบัน
```

**Flow การทำงานของ `NotificationsNotifier`:**

```
สร้าง instance → _initialize()
                    │
                    ├── ดึง username จาก StorageService
                    │       ถ้า null → รอ 1 วิ แล้ว retry
                    │
                    ├── loadNotifications()  → โหลดข้อมูลจาก API
                    ├── _connectWebSocket()  → เชื่อมต่อ Socket.IO
                    └── _startPolling()      → Polling ทุก 30 วิ (fallback)

เมื่อ WebSocket ส่ง event มา:
    new_notification      → เพิ่ม notification ในรายการ + เพิ่ม unreadCount + เล่นเสียง loop
    notification_read     → อัปเดต isRead = true + ลด unreadCount + หยุดเสียง (ถ้า unread = 0)
    all_notifications_read → ทำทุกรายการเป็น isRead = true + หยุดเสียงทั้งหมด
```

---

### 6. `fcm_registration_service.dart` — ส่ง FCM Token ไป Server

ไฟล์นี้ทำหน้าที่ **ลงทะเบียน FCM token** หลัง user login สำเร็จ

```
user login สำเร็จ → registerToken()
                        │
                        ├── ขอ permission (iOS/Android 13+)
                        ├── ดึง FCM token จาก Firebase
                        ├── สร้าง deviceId (เช่น "android_XXXXX_CPH2127")
                        └── ส่งไป Backend → PATCH /users/fcm-token
                                              body: { username, deviceId, fcmToken }

เมื่อ token refresh → ส่งใหม่อัตโนมัติ
```

> เมื่อ Backend มี token นี้แล้ว → จะใช้ส่ง FCM push notification ถึงอุปกรณ์นั้นโดยตรง

---

### 7. `notification_badge.dart` — ปุ่มกระดิ่งพร้อม Badge

ไฟล์นี้มี **2 Widget:**

**`NotificationBadge`:**
- แสดงไอคอนกระดิ่ง + วงกลมสีแดงแสดงจำนวน unread
- ดึงตัวเลขจาก `unreadCountProvider` (อัปเดต real-time)
- กดแล้ว → ไปหน้า `NotificationsPage` + หยุดเสียงทันที

```
unreadCount = 0  → แสดงแค่ไอคอน
unreadCount = 5  → แสดง "5" บนวงกลมแดง
unreadCount > 99 → แสดง "99+"
```

**`NotificationListener`:**
- Widget ที่ครอบหน้าจอหลัก
- ฟัง WebSocket stream → เมื่อมี `new_notification` → แสดง Snackbar ด้านล่างหน้าจอ
- Snackbar มีปุ่ม "ເບິ່ງ" (ดู) → กดแล้วไปหน้า Notifications + หยุดเสียง

---

### 8. `notifications_page.dart` — หน้าแสดงรายการ Notification

หน้า UI สำหรับ **ดูและจัดการ notification ทั้งหมด**

**Features:**
- Pull-to-refresh → โหลดใหม่จาก API
- แสดงรายการ notification แบบ list
  - notification ยังไม่อ่าน → พื้นหลังสีฟ้า + ตัวหนา
  - notification อ่านแล้ว → พื้นหลังปกติ
- **Swipe ซ้าย** → mark as read ทันที
- กดปุ่ม ✓ → mark as read
- ปุ่ม "ອ່ານເເລ້ວ (N)" → mark ทั้งหมดเป็น read + เล่นเสียงยืนยัน
- ปุ่ม 🔧 (FAB) → dialog test เครื่องมือ developer

---

## Flow รวมทั้งหมด ตั้งแต่ต้นจนจบ

### กรณีที่ 1: App เปิดอยู่ (Foreground)

```
Server ส่ง FCM data-only
    ↓
FirebaseMessaging.onMessage.listen()
    ↓
LocalNotificationService.showNotification()  → แสดง toast notification + เล่น meeting_sound
    ↓
WebSocket ส่ง 'new_notification' event (เกือบพร้อมกัน)
    ↓
NotificationsNotifier._handleNewNotification()
    ↓
state อัปเดต → unreadCount++ → NotificationBadge แสดงตัวเลขใหม่
    ↓
NotificationSoundService.playNotificationSound() → เล่นเสียง loop
    ↓
NotificationListener แสดง Snackbar "มีการแจ้งเตือนใหม่"
```

### กรณีที่ 2: App ถูก Swipe ออก (Terminated)

```
Server ส่ง FCM data-only
    ↓
Android ปลุก Dart background isolate แยกต่างหาก
    ↓
firebaseMessagingBackgroundHandler()
    ↓
Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)  ← สำคัญมาก!
    ↓
LocalNotificationService.initializeForBackground()  → สร้าง channel "meeting_notifications_v3"
    ↓
message.notification == null? → YES → showNotification()
    ↓
แสดง notification toast + เล่น meeting_sound.mp3 จาก /res/raw/
```

### กรณีที่ 3: User กด Mark as Read

```
User กด ✓ หรือ swipe ซ้าย
    ↓
NotificationsNotifier.markAsRead(id)
    ↓
├── WebSocket: socket.emit('mark_as_read', {notificationId})
├── API: POST /notifications/:id/read
└── Local state: isRead = true, unreadCount--
    ↓
NotificationSoundService.stopNotificationSound()  ← หยุดเสียง loop
    ↓
NotificationSoundService.playSuccessSound()       ← เสียงยืนยันสั้นๆ
    ↓
Server broadcast 'notification_read' → client อื่นๆ อัปเดตด้วย (real-time sync)
```

---

## สรุปความสัมพันธ์ระหว่างไฟล์

```
notifications_page.dart          ← UI หลัก
    └── ใช้ notificationsProvider (notification_provider.dart)
            ├── ใช้ NotificationRepository (notification_repository.dart)
            │       └── ใช้ Dio → HTTP API
            ├── ใช้ NotificationWebSocketService (notification_service.dart)
            │       └── ใช้ Socket.IO → WebSocket
            └── ใช้ NotificationSoundService (notification_sound_service.dart)
                    └── ใช้ AudioPlayer → assets/sounds/

notification_badge.dart          ← Widget กระดิ่ง
    └── ใช้ unreadCountProvider (ดึงจาก notificationsProvider)

fcm_registration_service.dart    ← ส่ง token ให้ Server
    └── ใช้ NotificationRepository.updateFcmToken()
```
