# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Camera related rules
-keep class android.hardware.camera2.** { *; }
-keep class android.hardware.camera.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.mlkit.** { *; }

# Mobile scanner rules
-keep class net.sourceforge.zbar.** { *; }
-keep class com.journeyapps.barcodescanner.** { *; }

# Avoid camera property access issues
-keepattributes *Annotation*
-keep class * extends android.app.Activity
-keep class * extends android.app.Application
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.content.ContentProvider
