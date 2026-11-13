# Hướng dẫn build và cài APK App Admin

> Áp dụng cho `admin-android/` – **555Rental Admin**.
> APK đã build sẵn: `admin-android/releases/555Rental-Admin-v1.0.0.apk`.

## 1. Yêu cầu môi trường

| Thành phần | Phiên bản / ghi chú |
|---|---|
| Android Studio | Narwhal trở lên (hỗ trợ AGP 9.x) |
| JDK | 17 (dùng JBR có sẵn trong Android Studio) |
| Android SDK | `compileSdk 37`, `targetSdk 37`, `minSdk 24` |
| Gradle | 9.6.0 (đã có wrapper) |
| Thiết bị | Android 7.0+ (API 24), bật “Nguồn không xác định” |

## 2. Mở project

1. Mở Android Studio → **Open**.
2. Chọn thư mục `INT4211-Nhom555-555Rental/admin-android` (không mở thư mục gốc repo).
3. Chờ Gradle sync. Nếu Android Studio hỏi SDK 37, bấm **Install missing SDK package**.
4. Kiểm tra `admin-android/local.properties` có dòng:
   ```properties
   sdk.dir=C:\\Users\\<tên-máy>\\AppData\\Local\\Android\\Sdk
   ```
   File này không commit lên Git.

## 3. Build bản debug

```powershell
cd admin-android
.\gradlew.bat assembleDebug
```

APK: `app/build/outputs/apk/debug/app-debug.apk`.

## 4. Build bản release có ký

Project đã cấu hình sẵn:

- Keystore: `admin-android/keystore/555rental-release.jks`
- Alias: `nhom555`
- Mật khẩu demo: `555rental`
- Cấu hình đọc từ `admin-android/keystore.properties`

```powershell
cd admin-android
.\gradlew.bat clean assembleRelease
```

APK: `app/build/outputs/apk/release/app-release.apk`.

> Khóa và mật khẩu trong repo chỉ dùng cho đồ án. Khi triển khai thật, tạo keystore riêng, không commit mật khẩu, dùng biến môi trường hoặc `~/.gradle/gradle.properties`.

### Nếu muốn dùng keystore khác

Sửa `admin-android/keystore.properties`:

```properties
storeFile=keystore/ten-khoa-cua-ban.jks
storePassword=...
keyAlias=...
keyPassword=...
```

Hoặc tạo keystore mới:

```powershell
keytool -genkeypair -v `
  -keystore admin-android/keystore/555rental-release.jks `
  -alias nhom555 -keyalg RSA -keysize 2048 -validity 10000 `
  -storepass 555rental -keypass 555rental `
  -dname "CN=Nhom 555, OU=INT4211, O=Hoc vien Cong nghe Buu chinh Vien thong, L=Ha Noi, C=VN"
```

## 5. Kiểm tra chữ ký APK

```powershell
$env:JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"
& "$env:ANDROID_HOME\build-tools\36.0.0\apksigner.bat" verify --print-certs `
  app\build\outputs\apk\release\app-release.apk
```

Kết quả mong đợi có dòng:

```
Signer #1 certificate DN: CN=Nhom 555, OU=INT4211, ...
```

## 6. Cài lên máy thật

### Cách 1: dùng ADB

1. Trên điện thoại: **Cài đặt → Giới thiệu → Nhấn 7 lần vào Số bản dựng** để mở Tùy chọn nhà phát triển.
2. Bật **Gỡ lỗi USB**.
3. Cắm cáp, chọn **Truyền tệp**, cho phép gỡ lỗi.
4. Chạy:

```powershell
adb devices
adb install -r admin-android\releases\555Rental-Admin-v1.0.0.apk
```

### Cách 2: chép file

1. Copy `555Rental-Admin-v1.0.0.apk` vào điện thoại (USB, Google Drive, Zalo…).
2. Mở file bằng trình quản lý tệp.
3. Cho phép “Cài đặt ứng dụng không rõ nguồn gốc”.
4. Bấm **Cài đặt**.

## 7. Cấu hình API sau khi cài

App mặc định gọi:

```
https://rental-nhom555-api.onrender.com/
```

Nếu đổi backend:

1. Ở màn đăng nhập, bấm **Địa chỉ API**.
2. Nhập URL **có dấu `/` ở cuối**, ví dụ `https://api-cua-ban.example/`. App tự thêm `https://` và `/` nếu thiếu.
3. Bấm **Lưu**.

Lưu ý:

- Backend Render Free ngủ sau 15 phút. Lần gọi đầu có thể chờ 30–60 giây; app đã đặt timeout 90 giây.
- App chặn cleartext (`http://`) với mọi tên miền, chỉ mở cho `10.0.2.2`, `localhost`, `127.0.0.1` để tiện debug. Muốn dùng backend local trên điện thoại thật, chạy `adb reverse tcp:3000 tcp:3000` rồi nhập `http://localhost:3000/`; hoặc dùng HTTPS (ví dụ qua tunnel/ngrok). Không dùng trực tiếp `http://192.168.x.x:3000/` vì sẽ bị chặn.

## 8. Lỗi thường gặp

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Đã cài bản khác chữ ký | Gỡ app cũ: `adb uninstall com.nhom555.rentaladmin` rồi cài lại |
| `INSTALL_FAILED_OLDER_SDK` | Máy chạy Android < 7.0 | Dùng máy API 24+ hoặc emulator |
| `App not installed` | Chưa bật cài từ nguồn ngoài | Bật “Cài đặt ứng dụng không rõ nguồn gốc” |
| Màn hình trắng / không có dữ liệu | Render đang ngủ hoặc sai API | Chờ 30–60 giây, bấm Thử lại, kiểm tra Địa chỉ API |
| `CLEARTEXT communication not permitted` | Dùng `http://` với tên miền/IP không được mở | Dùng `https://`, hoặc `adb reverse tcp:3000 tcp:3000` rồi dùng `http://localhost:3000/` |
| `401` ngay sau khi mở app | Token cũ/hết hạn | Đăng xuất rồi đăng nhập lại |
| Gradle báo thiếu SDK 37 | Chưa cài platform | SDK Manager → Android 37 → Apply |

## 9. Kiểm tra nhanh sau khi cài

1. Đăng nhập `chutro@555rental.vn` / `123456` → thấy Tổng quan.
2. Mở **Ghi chỉ số** → chọn khu, tháng → thấy chỉ số đầu và ô nhập.
3. Mở **Hóa đơn** → bấm **Phát hành hóa đơn** với tháng đã có → dialog báo “Đã tạo 0, bỏ qua N”.
4. Mở **Báo cáo** → thấy biểu đồ cột và biểu đồ tròn.
5. Đăng xuất, đăng nhập `quanly@555rental.vn` / `123456` → drawer chỉ còn Ghi chỉ số và Sự cố.
6. Tắt Wi-Fi → kéo xuống tải lại → thấy trạng thái lỗi và nút Thử lại, app không văng.
