# Keep Flutter background entry points so R8 does not strip them in release builds
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Firebase Messaging classes
-keep class com.google.firebase.messaging.** { *; }

# Keep the Dart VM entry-point annotations used by firebase_messaging background handler
-keep @interface io.flutter.embedding.engine.plugins.FlutterPlugin
-keepattributes *Annotation*

# Prevent R8 from stripping classes referenced only from Dart vm:entry-point
-keep class io.flutter.plugins.** { *; }
