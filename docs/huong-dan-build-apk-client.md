# Hướng dẫn build và cài APK App Client

> Áp dụng cho `client-flutter/` – **555Rental Khách**.
> APK đã build sẵn: `client-flutter/releases/555Rental-Khach-v1.0.0.apk`
> (cùng bản: `client-flutter/build/app/outputs/flutter-apk/app-release.apk`).

## 1. Yêu cầu môi trường

| Thành phần | Phiên bản đã dùng / ghi chú |
|---|---|
| Flutter | 3.35 trở lên; máy build dùng **3.47.3** |
| Dart | 3.13.3 (đi kèm Flutter) |
| JDK | 17 trở lên (máy build dùng JBR 25 của Android Studio) |
| Android SDK | `compileSdk 36`, `targetSdk 36`, `minSdk 24` |
| Gradle | Wrapper đi kèm project Flutter |
| Thiết bị | Android 7.0+ (API 24), bật “Cài đặt ứng dụng không rõ nguồn gốc” |

Kiểm tra:

```powershell
flutter --version
flutter doctor -v
```

## 2. Lấy mã nguồn và cài phụ thuộc

```powershell
git clone https://github.com/nvquangggit-sys/INT4211-Nhom555-555Rental.git
cd INT4211-Nhom555-555Rental\client-flutter
flutter pub get
```

Nếu máy chưa có `local.properties` (đường dẫn SDK), tạo file `client-flutter/android/local.properties`:

```properties
sdk.dir=C:\\Users\\<tên-máy>\\AppData\\Local\\Android\\Sdk
```

File này **không commit**.

## 3. Chạy thử và kiểm tra chất lượng

```powershell
flutter analyze           # Kỳ vọng: No issues found!
flutter test              # Kỳ vọng: +21: All tests passed!
flutter run               # Chạy debug trên máy thật/emulator
```

## 4. Build APK release

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

Kết quả:

```
client-flutter/build/app/outputs/flutter-apk/app-release.apk
```

Sao chép thành tên phát hành:

```powershell
Copy-Item build\app\outputs\flutter-apk\app-release.apk `
  releases\555Rental-Khach-v1.0.0.apk -Force
```

> Nếu Gradle báo lỗi `Could not close incremental caches in ... kotlin\compileReleaseKotlin`:
> project đã đặt `kotlin.incremental=false` trong `client-flutter/android/gradle.properties` để tránh khóa file trên Windows/antivirus. Nếu vẫn lỗi, chạy `flutter clean` rồi build lại; có thể tạm tắt antivirus khi build.

## 5. Ký APK release

Project đã cấu hình sẵn trong `client-flutter/android/app/build.gradle.kts`:

- Keystore: `client-flutter/android/app/555rental-release.jks` (**không commit**)
- Cấu hình: `client-flutter/android/key.properties` (**không commit**)
- Alias: `555rental`
- Mật khẩu demo: `555rental`

`gradle.properties`/`build.gradle.kts` đọc `key.properties`; nếu file không tồn tại, bản release tự ký bằng debug key để người khác vẫn build được.

### Tạo keystore mới (nếu cần)

```powershell
cd client-flutter\android
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v `
  -keystore app\555rental-release.jks -keyalg RSA -keysize 2048 -validity 10000 `
  -alias 555rental -storepass 555rental -keypass 555rental `
  -dname "CN=Nguyen Pham Chi Thanh, OU=INT4211 Nhom 555, O=555Rental, L=TP.HCM, C=VN"
```

Tạo `android/key.properties`:

```properties
storePassword=555rental
keyPassword=555rental
keyAlias=555rental
storeFile=555rental-release.jks
```

### Kiểm tra chữ ký

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0\apksigner.bat" verify --print-certs `
  releases\555Rental-Khach-v1.0.0.apk
```

Kết quả mong đợi:

```
Signer #1 certificate DN: CN=Nguyen Pham Chi Thanh, OU=INT4211 Nhom 555,
                          O=555Rental, L=TP.HCM, C=VN
```

## 6. Cài lên máy thật

### Cách 1: ADB

1. Điện thoại: **Cài đặt → Giới thiệu → nhấn 7 lần Số bản dựng** để mở Tùy chọn nhà phát triển.
2. Bật **Gỡ lỗi USB**, cắm cáp, chọn **Truyền tệp**, cho phép gỡ lỗi.
3. Chạy:

```powershell
adb devices
adb install -r client-flutter\releases\555Rental-Khach-v1.0.0.apk
```

### Cách 2: chép file

1. Copy APK vào điện thoại (USB, Google Drive, Zalo…).
2. Mở bằng trình quản lý tệp.
3. Cho phép “Cài đặt ứng dụng không rõ nguồn gốc”.
4. Bấm **Cài đặt**.

> Bản release ký bằng keystore riêng. Nếu máy đã cài bản khác chữ ký (ví dụ bản debug), gỡ trước:
> ```powershell
> adb uninstall vn.nhom555.rental_client
> ```

## 7. Cấu hình địa chỉ API sau khi cài

App mặc định gọi:

```
https://rental-nhom555-api.onrender.com
```

Đổi backend:

1. Ở màn đăng nhập (hoặc Tài khoản → Địa chỉ API), bấm biểu tượng **bánh răng / Địa chỉ API**.
2. Nhập URL, ví dụ:
   - Render: `https://rental-nhom555-api.onrender.com`
   - Emulator với backend local: `http://10.0.2.2:3000`
   - Máy thật với `adb reverse tcp:3000 tcp:3000`: `http://localhost:3000`
3. Bấm **Kiểm tra kết nối** (gọi `/health`), rồi **Lưu**.
4. App tự thêm `https://` nếu thiếu và bỏ dấu `/` cuối.

Lưu ý:

- Render Free ngủ sau 15 phút; lần gọi đầu có thể 30–60 giây. App đặt timeout **90 giây**.
- `AndroidManifest.xml` bật `usesCleartextTraffic="true"` và có quyền `INTERNET` để bản release gọi được cả `http://` khi demo local. Khi triển khai thật nên tắt cleartext và chỉ dùng HTTPS.

## 8. Lỗi thường gặp

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Khác chữ ký với bản đã cài | `adb uninstall vn.nhom555.rental_client` rồi cài lại |
| `INSTALL_FAILED_OLDER_SDK` | Máy chạy Android < 7.0 | Dùng máy API 24+ |
| `App not installed` | Chưa bật cài từ nguồn ngoài | Bật “Cài đặt ứng dụng không rõ nguồn gốc” |
| `Could not close incremental caches ... kotlin` | Windows/antivirus khóa cache Kotlin | Giữ `kotlin.incremental=false`, `flutter clean`, build lại |
| `Execution failed for task ':app:validateSigningRelease'` | Thiếu `key.properties`/`.jks` | Tạo lại theo mục 5, hoặc xóa `key.properties` để dùng debug key |
| Trắng màn hình / “Không kết nối được máy chủ” | Render đang ngủ, sai URL, mất mạng | Chờ 30–60 giây, bấm Thử lại, kiểm tra Địa chỉ API |
| `401` ngay khi mở app | Token cũ/hết hạn | Đăng xuất rồi đăng nhập lại |
| Ảnh không hiện | Link Supabase chết hoặc mất mạng | Kiểm tra Supabase Storage; app có `errorBuilder` nên không văng |
| Google Play Protect cảnh báo | APK ký tự phát hành, ngoài Store | Chọn “Vẫn cài đặt” (chỉ dùng cho đồ án) |

## 9. Kiểm tra nhanh sau khi cài

1. Gọi `/health` trước 3 phút để đánh thức Render.
2. Đăng nhập `nguoithue01@555rental.vn` / `123456` → thấy Trang chủ có banner nhắc hạn.
3. Tab **Tìm phòng** → lọc `Bình Thạnh` → mở phòng 117.
4. Đặt lịch xem phòng → vào **Lịch xem phòng** → hủy → bấm **Hoàn tác**.
5. Tab **Hóa đơn** → mở hóa đơn tháng 10 → xem các khoản, chỉ số điện/nước.
6. Tab **Sự cố** → Báo sự cố → chọn ảnh → gửi → xem timeline.
7. Tắt Wi-Fi → kéo xuống tải lại → thấy màn lỗi có nút Thử lại, app không văng.
8. Tài khoản → Đăng xuất → quay về màn đăng nhập.
