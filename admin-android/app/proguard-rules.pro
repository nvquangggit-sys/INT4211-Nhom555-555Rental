# Quy tắc ProGuard cho app Admin 555Rental.
# Gson dùng reflection trên các lớp model nên phải giữ nguyên tên trường.
-keep class com.nhom555.rentaladmin.data.model.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn okhttp3.**
-dontwarn retrofit2.**
