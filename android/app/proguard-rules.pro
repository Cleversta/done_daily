# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Play Store deferred components — not used, suppress R8 warnings
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Hive
-keep class * extends com.google.flatbuffers.Table { *; }
-keep class * implements com.google.flatbuffers.FlatBufferBuilder { *; }

# Keep Hive adapters (generated code)
-keep class * extends hive.** { *; }
-keepclassmembers class ** {
    @hive.* <fields>;
}

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# General: keep model classes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
