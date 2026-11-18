# 555Rental Khách – App Client (Flutter)

App dành cho **người thuê** trong hệ thống quản lý nhà trọ – đồ án cuối kỳ **INT4211**, đề 12, **Nhóm 555**.

- Backend dùng chung: `https://rental-nhom555-api.onrender.com`
- APK release: [`releases/555Rental-Khach-v1.0.0.apk`](releases/555Rental-Khach-v1.0.0.apk)
- Báo cáo giao diện: [`../docs/bao-cao-muc-5-giao-dien-client.md`](../docs/bao-cao-muc-5-giao-dien-client.md)
- Hướng dẫn build: [`../docs/huong-dan-build-apk-client.md`](../docs/huong-dan-build-apk-client.md)
- Danh sách ảnh/video minh chứng: [`../docs/minh-chung/README.md`](../docs/minh-chung/README.md) (mục 6)

## Tính năng

| Nhóm | Chức năng |
|---|---|
| Tài khoản | Đăng nhập, đăng ký, lưu phiên JWT, tự đăng xuất khi 401, đổi địa chỉ API, đăng xuất |
| Tìm phòng | Lọc theo khu vực / khoảng giá / diện tích, danh sách phòng trống, chi tiết phòng, bảng giá điện nước, tiện ích, liên hệ chủ trọ |
| Đặt lịch | Chọn ngày + giờ, đặt lịch xem phòng, hủy lịch có xác nhận và **Hoàn tác** |
| Hợp đồng | Thời hạn, tiền cọc, thanh tiến trình, cảnh báo **≤ 30 ngày** hoặc quá hạn |
| Hóa đơn | Danh sách + tổng nợ, chi tiết từng khoản, chỉ số điện/nước, lịch sử thanh toán |
| Thanh toán | Gửi xác nhận chuyển khoản kèm **ảnh biên lai**, chống gửi trùng, lịch sử giao dịch |
| Sự cố | Báo sự cố kèm ảnh, theo dõi timeline: Đã gửi → Đang xử lý → Hoàn tất |
| Nhắc hạn | Hóa đơn đến hạn/quá hạn, hợp đồng sắp hết hạn, badge trên AppBar |

## Công nghệ

| Thư viện | Dùng cho |
|---|---|
| `http` | Gọi REST API, multipart upload |
| `shared_preferences` | Lưu token, hồ sơ, địa chỉ API |
| `image_picker` | Chọn ảnh biên lai / ảnh sự cố |
| `intl`, `flutter_localizations` | Định dạng tiền VND, ngày tháng, DatePicker/TimePicker tiếng Việt |

Yêu cầu: Flutter **3.35+** (máy build 3.47.3), Dart 3, Android SDK 36, `minSdk 24`.

## Chạy

```powershell
flutter pub get
flutter analyze     # No issues found!
flutter test        # 21/21 pass
flutter run
```

Mặc định app gọi backend Render. Muốn đổi: màn đăng nhập → **Địa chỉ API** → nhập URL → **Kiểm tra kết nối** → **Lưu**.

- Emulator + backend local: `http://10.0.2.2:3000`
- Máy thật + cáp USB: `adb reverse tcp:3000 tcp:3000` rồi `http://localhost:3000`

## Tài khoản demo

| Vai trò | Email | Mật khẩu |
|---|---|---|
| Người thuê | `nguoithue01@555rental.vn` | `123456` |
| Người thuê khác | `nguoithue02@555rental.vn` … `nguoithue45@555rental.vn` | `123456` |

> App Client chỉ cho vai trò `NGUOI_THUE` sử dụng các API `/…/cua-toi`. Tài khoản chủ trọ/quản lý dùng App Admin.

## Cấu trúc

```
lib/
├── main.dart                 # MaterialApp, locale vi, điều hướng khi hết phiên
├── core/
│   ├── api_service.dart      # GET/POST/PATCH/DELETE/multipart, token, timeout 90s, UTF-8, 401
│   ├── api_exception.dart
│   └── dinh_dang.dart        # tiền, ngày, tháng, nhắc hạn
├── models/                   # 8 model đọc JSON backend + tiện ích chuyển kiểu
└── ui/
    ├── theme.dart            # theme + KhungDangTai/ManHinhLoi/MucRong/DongThongTin/TheSoLieu
    ├── widgets/              # AnhMang (loading/error), NhanTrangThai
    └── screens/              # 18 màn hình
```

## API sử dụng

| Màn hình | Endpoint |
|---|---|
| Đăng nhập / đăng ký | `POST /auth/dang-nhap`, `POST /auth/dang-ky`, `GET /auth/toi` |
| Tìm phòng | `GET /phong`, `GET /phong/:id` |
| Đặt / hủy lịch | `POST /lich-xem-phong`, `GET /lich-xem-phong/cua-toi`, `DELETE /lich-xem-phong/:id` |
| Hợp đồng | `GET /hop-dong/cua-toi` |
| Hóa đơn | `GET /hoa-don/cua-toi` |
| Thanh toán | `POST /thanh-toan` (multipart, field ảnh `anh`), `GET /thanh-toan/cua-toi` |
| Sự cố | `POST /bao-su-co` (JSON hoặc multipart), `GET /bao-su-co/cua-toi` |
| Nhắc hạn | `GET /nhac-han` |
| Kiểm tra backend | `GET /health` |

## Kiểm thử

```powershell
flutter test
```

| Tệp | Số test | Nội dung |
|---|---|---|
| `test/dinh_dang_test.dart` | 8 | Tiền VND, triệu/tỷ, ngày, tháng, nhắc hạn, rút gọn |
| `test/models_test.dart` | 8 | Đọc JSON thật: NUMERIC dạng chuỗi, null, mảng lồng, nhãn trạng thái |
| `test/login_screen_test.dart` | 5 | Validator đăng nhập/đăng ký, điền tài khoản demo, `Navigator.pop` |

Chi tiết 10 ca kiểm thử chức năng: [`../docs/bao-cao-muc-7-kiem-thu-client.md`](../docs/bao-cao-muc-7-kiem-thu-client.md).

## Build APK release

```powershell
flutter clean
flutter pub get
flutter build apk --release
Copy-Item build\app\outputs\flutter-apk\app-release.apk `
  releases\555Rental-Khach-v1.0.0.apk -Force
```

- `applicationId`: `vn.nhom555.rental_client`
- `versionName`: `1.0.0` (`versionCode 1`)
- Ký bằng `android/app/555rental-release.jks` + `android/key.properties` (cả hai **không commit**). Nếu thiếu, Gradle tự dùng debug key.
- Chi tiết keystore, lỗi thường gặp: [`../docs/huong-dan-build-apk-client.md`](../docs/huong-dan-build-apk-client.md).

## Ghi chú kỹ thuật

- **Timeout 90 giây** vì Render Free ngủ sau 15 phút.
- **`utf8.decode(bodyBytes)`** để tiếng Việt không lỗi font.
- **401 chỉ coi là hết phiên khi có token** → đăng nhập sai vẫn hiện đúng lỗi backend.
- Mọi `setState`/`Navigator` sau `await` đều kiểm tra `mounted`.
- Cờ `_dangGui` chống bấm gửi hai lần; server cũng chặn giao dịch chờ trùng (`409`).
- `IndexedStack` giữ trạng thái 5 tab; `ListView.builder` cho danh sách dài.
- Ảnh dùng `Image.network` có `loadingBuilder` + `errorBuilder`.
