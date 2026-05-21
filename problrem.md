## Context & Tech Stack
* **Framework:** Flutter (Android)
* **Services:** Firebase Cloud Messaging (FCM), Android Local Notifications
* **Issue:** Inconsistent notification toasts, loops, and tap handler state updates across different app lifecycle states.

---

## The Issues

### 1. Foreground State Issue
* **Behavior:** When the app is actively open and in the foreground, notifications are received in the logs, but **no visual toast notification shows and no sound plays**.
* **Relevant Log:** 
  > `I/flutter (28999): 📨 New notification received: ...`
  > `I/flutter (28999): 🔊 Sound handled by Android Notification Channel` (But nothing actually plays or displays)

### 2. App Killed (Background Loop & State Sync Issue)
* **Scenario A (App in background, not killed):** Tapping the notification displays perfectly and plays audio.
* **Scenario B (App killed from recent apps):** If a notification is active and the app is hard-killed, the visual toast and looping sound abruptly cut off.
* **Scenario C (App killed *before* notification arrives):** If the app is already killed and a notification comes in, the notification and sound show up. **However**, tapping the notification fails to update its status to "read" on the backend. Even after opening the app manually and clicking an "Update all to read" button, the background notification sound continues to loop and will not stop.

---

## Relevant Logs

### Log A: App is Open / Foreground (No Toast/Sound)
```text
I/flutter (28999): 📨 New notification received: {type: meeting_reminder, data: {id: 69d549fe-c641-4549-af74-6063b4457f73, message: ທົດສອບການແຈ້ງເຕືອນok...}}
I/flutter (28999): 🔔 Handling new notification: ...
I/flutter (28999): 🔔 Added new notification, unread count: 1
I/flutter (28999): 🔊 Sound handled by Android Notification Channel