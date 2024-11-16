# OkHttp 예외 규칙
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Retrofit 예외 규칙
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**
-keepattributes Signature
-keepattributes Exceptions

# Gson 예외 규칙
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# 네트워크 통신 관련 클래스 유지
-keep class okhttp3.** { *; }
-keep class com.google.gson.** { *; }
