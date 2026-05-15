# Firebase Cloud Messaging (FCM) Setup Guide

## 📋 Overview

Firebase Cloud Messaging (FCM) ช่วยให้แอปของคุณสามารถรับ Push Notification ได้แม้จะปิด App หรืออยู่ใน Background

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────┐     ┌─────────────┐
│   Backend       │────▶│  FCM Server  │────▶│  Google/    │────▶│   Phone     │
│   (NestJS)      │     │  (Firebase)  │     │  Apple Push │     │  (Flutter)  │
└─────────────────┘     └──────────────┘     └─────────────┘     └─────────────┘
       │                                                            │
       │  WebSocket (เมื่อ App เปิด)                                  │
       └────────────────────────────────────────────────────────────┘
```

---

## 🔥 Step 1: สร้าง Firebase Project

### 1.1 ไปที่ Firebase Console
- URL: https://console.firebase.google.com/
- Sign in ด้วย Google Account

### 1.2 สร้าง Project ใหม่
1. กด "Create Project"
2. ใส่ชื่อโปรเจค: `account-system-notifications`
3. Disable Google Analytics (ไม่จำเป็นต้องใช้)
4. กด "Create Project"
5. รอสร้างเสร็จ แล้วกด "Continue"

---

## 📱 Step 2: ตั้งค่า Android App

### 2.1 เพิ่ม Android App ใน Firebase
1. ใน Firebase Console กดไอคอน Android (เพิ่ม App)
2. **Package name**: ใส่ package name ของ Flutter app (ดูจาก `android/app/build.gradle`)
   - ตัวอย่าง: `com.example.account_system`
3. **App nickname**: (optional) `Account System Android`
4. กด "Register app"

### 2.2 ดาวน์โหลด `google-services.json`
1. กด "Download google-services.json"
2. ย้ายไฟล์ไปที่: `android/app/google-services.json`

### 2.3 ตั้งค่า Gradle Files

**แก้ไข `android/build.gradle`** (root level):
```gradle
buildscript {
    dependencies {
        // ... existing dependencies
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**แก้ไข `android/app/build.gradle`**:
```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"  // <-- เพิ่มบรรทัดนี้
}

android {
    // ... existing config
    
    defaultConfig {
        // ... 
        minSdkVersion 21  // <-- ต้องเป็น 21 ขึ้นไป
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

### 2.4 Android Permissions

**แก้ไข `android/app/src/main/AndroidManifest.xml`**:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    
    <application
        android:label="account_system"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <activity ...>
            ...
        </activity>
        
        <!-- Add Firebase Messaging Service -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT"/>
            </intent-filter>
        </service>
        
        <!-- Set default notification channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="meeting_notifications" />
            
    </application>
</manifest>
```

---

## 🍎 Step 3: ตั้งค่า iOS App (ถ้าใช้ iPhone)

### 3.1 เพิ่ม iOS App ใน Firebase
1. ใน Firebase Console กด "Add app" → เลือก iOS
2. **Bundle ID**: ใส่ bundle ID ของ iOS app
   - ตัวอย่าง: `com.example.accountSystem`
3. **App nickname**: (optional) `Account System iOS`
4. กด "Register app"

### 3.2 ดาวน์โหลด `GoogleService-Info.plist`
1. กด "Download GoogleService-Info.plist"
2. ย้ายไฟล์ไปที่: `ios/Runner/GoogleService-Info.plist`
3. ใน Xcode: คลิกขวาที่ Runner → Add Files to "Runner" → เลือกไฟล์

### 3.3 ตั้งค่า Xcode

1. เปิด `ios/Runner.xcworkspace` ใน Xcode
2. Select Runner → Signing & Capabilities
3. กด "+ Capability" → เพิ่ม:
   - **Push Notifications**
   - **Background Modes** → Check "Remote notifications"

### 3.4 ติดตั้ง CocoaPods
```bash
cd ios
pod install --repo-update
```

---

## 🔧 Step 4: ตั้งค่า Backend (NestJS)

### 4.1 สร้าง Service Account ใน Firebase
1. Firebase Console → Project Settings → Service Accounts
2. กด "Generate new private key"
3. ดาวน์โหลด JSON file
4. เปิดไฟล์ JSON แล้วหาค่าเหล่านี้:
   - `project_id`
   - `private_key`
   - `client_email`

### 4.2 เพิ่ม Environment Variables

**Backend `.env`**:
```env
# Firebase Admin SDK
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
```

⚠️ **สำคัญ**: `FIREBASE_PRIVATE_KEY` ต้องมี `\n` แทนการขึ้นบรรทัดใหม่

---

## 📦 Step 5: Install Dependencies

### Flutter
```bash
cd account_system_frontend
flutter pub get
```

### Backend
```bash
cd account_system
pnpm install  # หรือ npm install
```

---

## 🚀 Step 6: รัน Database Migration

```bash
cd account_system
npx prisma migrate dev --name add_fcm_token
npx prisma generate
```

---

## 🧪 Step 7: ทดสอบ FCM

### 7.1 ทดสอบจาก Firebase Console
1. Firebase Console → Cloud Messaging
2. กด "Send your first message"
3. ใส่ Notification title และ text
4. เลือก App ที่ต้องการส่ง
5. กด "Send test message"
6. ใส่ FCM token (ดูจาก log ของ Flutter app)
7. กด "Test"

### 7.2 ทดสอบจาก Backend
```bash
# Trigger cron job
curl -X POST http://localhost:4000/api/v1/notifications/test/trigger-meeting-reminder
```

---

## 📱 สิ่งที่จะเห็นบน Phone

### เมื่อ App เปิดอยู่ (Foreground):
- ✅ WebSocket: แสดง snackbar + เล่นเสียง
- ✅ FCM: แสดง local notification ด้วย

### เมื่อ App ใน Background:
- ❌ WebSocket: ไม่ทำงาน
- ✅ FCM: แสดง notification ใน status bar

### เมื่อ App ปิด (Terminated):
- ❌ WebSocket: ไม่ทำงาน
- ✅ FCM: แสดง notification ใน status bar (เมื่อกดเปิด App)

---

## 🔧 Troubleshooting

### ไม่ได้รับ Push Notification
| ปัญหา | วิธีแก้ |
|-------|--------|
| Android: ไม่มี notification | ตรวจสอบ `google-services.json` ถูกต้อง |
| iOS: ไม่มี notification | ตรวจสอบ Certificate และ Capabilities |
| FCM token ไม่ถูกส่ง | ตรวจสอบ API call ส่ง token ไป backend |
| Backend error | ตรวจสอบ Firebase credentials ใน `.env` |

### Debug Commands
```bash
# ดู FCM token ใน Flutter
flutter run
# ดู log: "📱 FCM Token: xxx"

# ทดสอบส่งจาก Backend
npm run start:dev
# ดู log: "📱 Push notification sent: xxx"
```

---

## 📚 Files ที่เกี่ยวข้อง

| File | คำอธิบาย |
|------|----------|
| `lib/core/services/firebase_messaging_service.dart` | FCM service ใน Flutter |
| `lib/main.dart` | เริ่มต้น Firebase |
| `android/app/google-services.json` | Android config |
| `ios/Runner/GoogleService-Info.plist` | iOS config |
| `src/modules/notifications/services/firebase.service.ts` | FCM service ใน Backend |
| `src/modules/notifications/notifications.service.ts` | ส่ง notification |

---

## ✅ Checklist

- [ ] สร้าง Firebase Project
- [ ] ดาวน์โหลด `google-services.json` (Android)
- [ ] ดาวน์โหลด `GoogleService-Info.plist` (iOS)
- [ ] แก้ไข AndroidManifest.xml
- [ ] ตั้งค่า Xcode capabilities (iOS)
- [ ] เพิ่ม Firebase credentials ใน Backend `.env`
- [ ] รัน `flutter pub get`
- [ ] รัน `pnpm install` (backend)
- [ ] รัน `prisma migrate dev`
- [ ] ทดสอบส่ง notification

---

## 🎉 เสร็จสมบูรณ์!

ตอนนี้แอปของคุณสามารถรับ Push Notification ได้ทั้ง:
- ✅ เมื่อ App เปิดอยู่ (พร้อม WebSocket)
- ✅ เมื่อ App อยู่ใน Background
- ✅ เมื่อ App ถูกปิด (Kill)
