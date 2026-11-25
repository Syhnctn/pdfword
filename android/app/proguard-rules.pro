# Flutter / Android embedding
# Flutter's Gradle plugin already contributes the embedding keep rules, but these
# keep the plugin registration entry points safe under R8 full mode.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# google_mobile_ads / Google Play Services Ads
# The ads SDK resolves classes and layout views reflectively, and UserMessagingPlatform
# (consent) uses reflection too. Without these, ads can crash at runtime.
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.ump.** { *; }
-keep class io.flutter.plugins.googlemobileads.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.ump.**

# Supabase (realtime/websocket + JSON)
-keep class io.supabase.** { *; }
-keep class supabase.** { *; }
-dontwarn io.supabase.**

# open_filex / share_plus / file_picker / url_launcher
# These talk to platform channels and, in some paths, to file/content providers
# whose class names are resolved at runtime.
-keep class com.example.** { *; }
-keep class io.flutter.plugins.openfilex.** { *; }
-keep class io.flutter.plugins.shareplus.** { *; }
-keep class io.flutter.plugins.filepicker.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep annotations and generic signatures so R8 does not strip metadata that
# Flutter plugins and Play Services rely on for reflection.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Kotlin metadata (required for kotlin-reflect based paths and for readable traces)
-keepattributes RuntimeVisibleAnnotations,RuntimeInvisibleAnnotations,AnnotationDefault
