# คู่มือระบบการแจ้งเตือน

## ภาพรวม
เอกสารนี้อธิบายการทำงานของระบบการแจ้งเตือนทั้งหมด รวมถึงการเชื่อมต่อ Firebase, การสื่อสารผ่าน WebSocket, และการซิงโครไนซ์ระหว่างอุปกรณ์หลายเครื่อง

## โครงสร้างไฟล์และความรับผิดชอบ

### 1. `firebase_messaging_service.dart`
**วัตถุประสงค์**: บริการ Firebase Cloud Messaging (FCM) หลัก จัดการการรับและแสดงการแจ้งเตือนทั้งหมด

#### ส่วนประกอบหลัก:

##### ตัวแปรร่วมกัน (Global Variables)
```dart
typedef NotificationTapCallback = Future<void> Function(String notificationId);
NotificationTapCallback? _globalNotificationTapCallback;
String? _pendingNotificationId; // สำหรับการแจ้งเตือนที่แตะก่อนที่ callback จะพร้อม
```

##### Background Message Handler
```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async
```
- **วัตถุประสงค์**: จัดการการแจ้งเตือนเมื่อแอปอยู่ใน background หรือปิด
- **ถูกเรียกโดย**: ระบบ Android เมื่อมีข้อความ FCM เข้ามา
- **การทำงาน**: 
  - เริ่มต้น Firebase
  - ตั้งค่า local notifications
  - แสดงการแจ้งเตือนพร้อมเสียง

##### Notification Tap Handler
```dart
void onNotificationTap(NotificationResponse response)
```
- **วัตถุประสงค์**: จัดการการแตะ toast notification ของผู้ใช้
- **การทำงาน**:
  - หยุดเสียงทันทีผ่าน `LocalNotificationService.cancelRepeating()`
  - เรียก global callback เพื่อทำเครื่องหมายว่าอ่านแล้ว
  - ทำงานแม้เมื่อแอปปิด

##### FirebaseMessagingService Class
- **initialize()**: ตั้งค่า FCM, ขอสิทธิ์, ลงทะเบียน handlers
- **_handleForegroundMessage()**: จัดการข้อความเมื่อแอปเปิดอยู่
- **_handleMessageOpenedApp()**: จัดการการเปิดแอปจากการแจ้งเตือน

### 2. `notification_provider.dart`
**วัตถุประสงค์**: การจัดการสถานะการแจ้งเตือนโดยใช้ Riverpod, จัดการการสื่อสารผ่าน WebSocket และการอัพเดท UI

#### ส่วนประกอบหลัก:

##### NotificationsNotifier Class
- **_initialize()**: ตั้งค่าการเชื่อมต่อ WebSocket และลงทะเบียน tap callback
- **_connectWebSocket()**: สร้างการเชื่อมต่อ WebSocket สำหรับอัพเดทแบบ real-time
- **_handleNewNotification()**: ประมวลผลการแจ้งเตือนใหม่, เล่นเสียง
- **_handleNotificationRead()**: จัดการสถานะอ่านจากอุปกรณ์อื่น
- **markAsRead()**: ทำเครื่องหมายว่าอ่านแล้วและซิงโครไนซ์ข้ามอุปกรณ์

##### การเชื่อมต่อ WebSocket
```dart
_webSocketService.markAsRead(notificationId); // ส่งไปยังอุปกรณ์อื่น
await _repository.markAsRead(notificationId, _username!); // อัพเดท backend
```

### 3. `notification_service.dart`
**วัตถุประสงค์**: WebSocket client สำหรับการซิงโครไนซ์แบบ real-time ระหว่างอุปกรณ์หลายเครื่อง

#### ส่วนประกอบหลัก:

##### NotificationWebSocketService Class
- **connect()**: สร้างการเชื่อมต่อ WebSocket พร้อมการยืนยันตัวตน
- **markAsRead()**: ส่งสถานะอ่านไปยังอุปกรณ์ที่เชื่อมต่อทั้งหมด
- **markAllAsRead()**: กระจายสถานะอ่านทั้งหมด
- **Event Handlers**: ฟังเหตุการณ์การแจ้งเตือนจากอุปกรณ์อื่น

##### WebSocket Events
- `new_notification`: ได้รับการแจ้งเตือนใหม่
- `notification_read`: การแจ้งเตือนถูกทำเครื่องหมายว่าอ่านแล้วบนอุปกรณ์อื่น
- `all_notifications_read`: การแจ้งเตือนทั้งหมดถูกทำเครื่องหมายว่าอ่านแล้ว

### 4. `notification_repository.dart`
**วัตถุประสงค์**: API client สำหรับการดำเนินการกับ backend ของการแจ้งเตือน

#### เมธอดหลัก:
- `getAllNotifications()`: ดึงการแจ้งเตือนของผู้ใช้พร้อม pagination
- `markAsRead()`: ทำเครื่องหมายการแจ้งเตือนเฉพาะว่าอ่านแล้ว
- `markAllAsRead()`: ทำเครื่องหมายการแจ้งเตือนทั้งหมดว่าอ่านแล้ว
- `updateFcmToken()`: ลงทะเบียน device token กับ backend

### 5. `notification_model.dart`
**วัตถุประสงค์**: โมเดลข้อมูลสำหรับการแจ้งเตือน

#### โมเดลหลัก:
- `MeetingNotification`: การแจ้งเตือนแต่ละรายการพร้อมสถานะการอ่าน
- `NotificationResponse`: การตอบกลับ API พร้อมการแจ้งเตือนและข้อมูลเพิ่มเติม
- `PaginationInfo`: รายละเอียด pagination

### 6. `notifications_page.dart`
**วัตถุประสงค์**: UI สำหรับแสดงและจัดการการแจ้งเตือน

#### คุณสมบัติหลัก:
- มุมมองรายการพร้อมสถานะอ่าน/ยังไม่อ่าน
- หลายวิธีในการทำเครื่องหมายว่าอ่านแล้ว:
  - แตะการแจ้งเตือน
  - คลิกปุ่มเช็ค
  - ปัดเพื่อยกเลิก
- ฟังก์ชันทำเครื่องหมายทั้งหมดว่าอ่านแล้ว
- อัพเดทแบบ real-time ผ่าน WebSocket

### 7. `notification_sound_service.dart`
**วัตถุประสงค์**: จัดการการเล่นและหยุดเสียงการแจ้งเตือน

#### เมธอดหลัก:
- `playNotificationSound()`: เริ่มเล่นเสียงซ้ำ
- `stopNotificationSound()`: หยุดเสียงทันที
- เสียงวนซ้ำจนกว่าจะถูกหยุดอย่างชัดเจน

### 8. `fcm_registration_service.dart`
**วัตถุประสงค์**: จัดการการลงทะเบียน FCM token และการจัดการอุปกรณ์

#### เมธอดหลัก:
- `registerToken()`: ลงทะเบียน device token กับ username
- `deactivateToken()`: ยกเลิก token เมื่อ logout
- `_getDeviceId()`: สร้างตัวระบุอุปกรณ์ที่ไม่ซ้ำกัน

## การเชื่อมต่อ Firebase

### การกำหนดค่า Firebase (`firebase_options.dart`)
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyDM46xhb0oCO34RoRR-BGlFVRuwLryxwfc',
  appId: '1:351785621643:android:ed6db39c8d47c5a4a41c8e',
  messagingSenderId: '351785621643',
  projectId: 'lanxangaap',
  storageBucket: 'lanxangaap.firebasestorage.app',
);
```

### ขั้นตอนการเริ่มต้น Firebase
1. **main.dart**: เริ่มต้น Firebase app
2. **firebase_messaging_service.dart**: ตั้งค่า background handler
3. **ขอสิทธิ์**: รับสิทธิ์การแจ้งเตือน
4. **รับ FCM token**: Token ของอุปกรณ์ที่ไม่ซ้ำกัน
5. **ลงทะเบียน token**: ส่งไปยัง backend พร้อม username

### ขั้นตอนการจัดการข้อความ
```
FCM Message → Android System → Background Handler → Local Notification → User Sees Toast
     ↓
User Taps → onNotificationTap → Stop Sound → Mark as Read → WebSocket Sync → Other Devices Update
```

## การซิงโครไนซ์ระหว่างอุปกรณ์หลายเครื่อง

### การสื่อสารผ่าน WebSocket
1. **อุปกรณ์ A** ทำเครื่องหมายว่าอ่านแล้ว
2. **WebSocket** ส่ง event `notification_read`
3. **อุปกรณ์ B** รับ event ผ่าน WebSocket
4. **อุปกรณ์ B** หยุดเสียงและอัพเดท UI
5. **ทั้งสองอุปกรณ์** แสดงสถานะที่สอดคล้องกัน

### การซิงโครไนซ์เสียง
- แต่ละอุปกรณ์จัดการเสียงของตัวเอง
- WebSocket events ทริกเกอร์การยกเลิกเสียง
- `LocalNotificationService.cancelRepeating()` หยุด timer
- `NotificationSoundService.stopNotificationSound()` หยุดเสียง

## การกำหนดค่า Android Manifest

### สิทธิ์ที่จำเป็น
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

## ตัวอย่างการทำงานของการแจ้งเตือน

### 1. ได้รับการแจ้งเตือนใหม่
```
Backend → FCM → อุปกรณ์ A/อุปกรณ์ B → Background Handler → Local Notification → เริ่มเสียง
```

### 2. ผู้ใช้แตะ Toast บนอุปกรณ์ A
```
อุปกรณ์ A: แตะ → หยุดเสียง → ทำเครื่องหมายว่าอ่านแล้ว → WebSocket → อัพเดท API
อุปกรณ์ B: WebSocket Event → หยุดเสียง → อัพเดท UI → แสดงว่าอ่านแล้ว
```

### 3. แอปปิด, มีการแจ้งเตือนเข้ามา
```
FCM → Background Handler → แสดงการแจ้งเตือน → ผู้ใช้แตะ → เปิดแอป → หยุดเสียง → ทำเครื่องหมายว่าอ่านแล้ว
```

## การแก้ไขปัญหา

### ข้อความ Log หลัก
- `🔔 BACKGROUND HANDLER TRIGGERED`: ได้รับข้อความ background
- `📩 FOREGROUND HANDLER`: ได้รับข้อความ foreground
- `👆 NOTIFICATION TAPPED`: ผู้ใช้แตะ toast notification
- `🔇 CANCEL REPEATING STARTED`: เริ่มการยกเลิกเสียง
- `📨 NOTIFICATION READ RECEIVED FROM OTHER DEVICE`: ซิงโครไนซ์ระหว่างอุปกรณ์

### การใช้ Log Viewer
1. เปิด Dashboard → คลิก "App Logs"
2. ใช้ตัวกรอง: "Notifications", "Sound", "WebSocket"
3. ค้นหา notification IDs หรือข้อผิดพลาดเฉพาะ

## การแก้ไขปัญหาทั่วไป

### การแจ้งเตือนใน Background ไม่ทำงาน
- ตรวจสอบการตั้งค่าการประหยัดแบตเตอรี่ของ Android
- ยืนยันว่า FCM token ถูกลงทะเบียนกับ backend
- ให้แน่ใจว่า background handler ถูกลงทะเบียนอย่างถูกต้อง

### เสียงไม่หยุด
- ตรวจสอบว่า `cancelRepeating()` ถูกเรียก
- ตรวจสอบการเชื่อมต่อ WebSocket สำหรับซิงโครไนซ์ระหว่างอุปกรณ์
- ให้แน่ใจว่า notification tap callback ถูกลงทะเบียน

### ปัญหาการซิงโครไนซ์ระหว่างอุปกรณ์
- ตรวจสอบสถานะการเชื่อมต่อ WebSocket
- ยืนยันว่าทั้งสองอุปกรณ์ใช้บัญชีเดียวกัน
- มองหา WebSocket event logs

## การปรับปรุงประสิทธิภาพ

### การตรวจจับ Background แบบทันที
- ลดความซับซ้อนของการตรวจสอบสถานะ lifecycle
- ลดการหน่วงเวลาที่ไม่จำเป็น
- การประมวลผลการแจ้งเตือนทันที

### การจัดการเสียงที่มีประสิทธิภาพ
- เสียงซ้ำตาม timer
- การยกเลิกทันทีเมื่อผู้ใช้ดำเนินการ
- การจัดการ session token สำหรับการแจ้งเตือนหลายรายการ

### การปรับปรุง WebSocket
- การเชื่อมต่อใหม่อัตโนมัติ
- การตรวจสอบสถานะการเชื่อมต่อ
- การอัพเดตแบบ event-driven เท่านั้น

## การพิจารณาด้านความปลอดภัย

### การจัดการ Token
- ตัวระบุอุปกรณ์ที่ไม่ซ้ำกันต่อการติดตั้ง
- การยกเลิก token เมื่อ logout
- การส่ง token ไปยัง backend อย่างปลอดภัย

### การยืนยันตัวตน WebSocket
- การยืนยันตัวตนโดยใช้ JWT token
- การรีเฟรช token อัตโนมัติ
- การเชื่อมต่อที่ปลอดภัย (WSS)

สถาปัตยกรรมนี้ช่วยให้มั่นใจได้ว่าการส่งมอบการแจ้งเตือนที่เชื่อถือได้แบบ real-time ระหว่างอุปกรณ์หลายเครื่อง พร้อมการจัดการเสียงและการจัดการการโต้ตอบของผู้ใช้ที่เหมาะสม
