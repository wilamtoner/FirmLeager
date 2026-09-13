# Flutter Core Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# SQLite / Database
-keep class com.tekartik.sqflite.** { *; }

# Prevent stripping of Kotlin metadata and reflection
-keepattributes *Annotation*,InnerClasses,Signature,EnclosingMethod

# Suppress harmless warnings during R8 optimization
-dontwarn **
-ignorewarnings
