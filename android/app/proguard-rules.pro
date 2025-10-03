# Keep Stripe SDK classes
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# Keep push provisioning classes specifically
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# Keep React Native Stripe SDK classes
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**