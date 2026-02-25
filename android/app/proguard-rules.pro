# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Android Play Core (split install / deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# Shared Preferences
-keep class androidx.datastore.** { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Local Auth / Biometric
-keep class androidx.biometric.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }

# Package Info Plus
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Don't warn about missing classes
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn com.google.errorprone.**
-dontwarn javax.annotation.**

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Missing R8 classes fix
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
