# Keep Flutter background entry points so R8 does not strip them in release builds
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep the Dart VM entry-point annotations used by firebase_messaging background handler
-keepattributes *Annotation*
-keep @interface io.flutter.embedding.engine.plugins.FlutterPlugin

# Keep Firebase Messaging classes
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.** { *; }

# Keep flutter_local_notifications classes
-keep class com.dexterous.** { *; }

# Keep OkHttp (used by socket.io and http clients)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Keep socket.io client
-keep class io.socket.** { *; }
-dontwarn io.socket.**

# Keep Gson TypeToken generics — fixes "Missing type parameter" in flutter_local_notifications
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes EnclosingMethod
-dontwarn com.google.gson.**

# Keep JSON serialization (used by notification payload)
-keepattributes *Annotation*
-keep class com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.**

# Keep Kotlin coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Keep permission_handler classes
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Suppress missing Google Play Core split-install classes
# These are only needed for Play Store dynamic delivery, not required for APK sideloading
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
