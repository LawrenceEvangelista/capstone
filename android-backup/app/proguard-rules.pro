############################################
# PROGUARD RULES FOR FLUTTER + FIREBASE
############################################

# Keep Flutter JNI
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Firebase models
-keepclassmembers class * {
    @com.google.firebase.database.PropertyName <fields>;
}

# Keep Firebase Auth
-keep class com.google.firebase.auth.** { *; }

# Keep Firebase Database
-keep class com.google.firebase.database.** { *; }

# Keep Firebase Storage
-keep class com.google.firebase.storage.** { *; }

# Keep Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }

# Keep Google Play services
-keep class com.google.android.gms.** { *; }

# Prevent warnings for Google libraries
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**

# Keep JSON (needed for QuestionModel)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep Kotlin reflect metadata
-keep class kotlin.Metadata { *; }

# Keep your models (important!)
-keep class com.example.testapp.** { *; }

############################################
# REMOVE UNUSED RESOURCES + CODE
############################################
# (Handled automatically by R8)
