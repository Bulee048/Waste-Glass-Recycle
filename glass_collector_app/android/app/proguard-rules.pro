# Keep ML Kit and Barcode Scanning classes
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }

-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class com.google.android.gms.vision.** { *; }

# Keep Mobile Scanner classes
-keep class dev.steenbakker.mobile_scanner.** { *; }

# Keep CameraX classes
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**
