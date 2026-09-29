# G.R. Book — release ProGuard/R8 rules.
# Flutter's own default rules handle the engine; these cover the
# reflection/JSON-dependent libraries this app adds on top.

# Drift / SQLite (native bindings + generated code use reflection)
-keep class com.google.android.gms.** { *; }
-dontwarn org.sqlite.**
-keep class org.sqlite.** { *; }

# googleapis (drive/v3) model classes are JSON-(de)serialized by field
# name — stripping/renaming fields breaks backup upload/restore silently.
-keep class com.google.api.** { *; }
-keep class com.google.api.client.** { *; }
-dontwarn com.google.api.client.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# local_auth (biometric)
-keep class androidx.biometric.** { *; }

# Supabase / gotrue / postgrest models used via reflection-free codegen
# in this project don't need extra rules, but keep enum names stable
# since they're sent as literal strings to Postgres.
-keepclassmembers enum * { *; }

# General: keep annotations and line numbers for useful crash reports
# while still removing/obfuscating everything R8 can safely reach.
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
