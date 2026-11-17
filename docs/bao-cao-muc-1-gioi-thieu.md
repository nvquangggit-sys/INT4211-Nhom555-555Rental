# Mục 1 – Giới thiệu đề tài

> Đồ án cuối kỳ **INT4211 – Lập trình trên các thiết bị di động**, đề 12: **Hệ thống quản lý nhà trọ – phòng cho thuê**.
> Nhóm 555. Tài liệu này là phần giới thiệu chung; các mục 5 (giao diện Client), 7 (kiểm thử Client) do thành viên **Nguyễn Phạm Chí Thành** thực hiện.

## 1.1. Bối cảnh

Các khu nhà trọ, phòng cho thuê tại Việt Nam phần lớn vẫn quản lý bằng sổ sách hoặc file Excel:

- Chủ trọ ghi chỉ số điện – nước, tính tiền, nhắc nợ thủ công nên dễ nhầm lẫn và mất thời gian.
- Người thuê không biết chính xác tháng này mình dùng bao nhiêu kWh, bao nhiêu m³ nước, đã đóng bao nhiêu, còn nợ bao nhiêu.
- Lịch xem phòng, hợp đồng, sự cố (hỏng điện, rò nước, mất khóa…) thường trao đổi qua Zalo/điện thoại, không có nơi lưu trữ tập trung.
- Khi cần đối chiếu (ví dụ chủ trọ báo thiếu tiền), cả hai bên không có dữ liệu chung để kiểm tra.

Một hệ thống di động gồm **app cho chủ trọ**, **app cho người thuê** và **một backend dùng chung** giải quyết trực tiếp các vấn đề trên: dữ liệu nhập một lần, cả hai phía cùng thấy, có lịch sử và trạng thái rõ ràng.

## 1.2. Mục tiêu

| Mục tiêu | Cách thực hiện |
|---|---|
| Số hóa nghiệp vụ quản lý nhà trọ | CSDL PostgreSQL 11 bảng: khu trọ, phòng, hợp đồng, biểu giá, chỉ số điện nước, hóa đơn, thanh toán, sự cố, lịch xem phòng, người dùng |
| Chủ trọ/quản lý thao tác trên điện thoại | App **555Rental Admin** (Android, Java + XML + Retrofit) |
| Người thuê tự tra cứu, thanh toán, báo sự cố | App **555Rental Khách** (Flutter) – phần của thành viên C |
| Dùng chung một nguồn dữ liệu | Backend REST API Node.js + Express + JWT, deploy Render, CSDL Supabase |
| Có kiểm thử và minh chứng | 8 ca kiểm thử Client + 8 ca Admin, APK release đã ký, video demo |

## 1.3. Phạm vi

### Trong phạm vi

- **App Client (Flutter)** dành cho người thuê: tìm phòng trống, đặt/hủy lịch xem, xem hợp đồng, hóa đơn, gửi xác nhận thanh toán kèm ảnh biên lai, báo sự cố kèm ảnh, nhận nhắc hạn, quản lý tài khoản.
- **Route API phía khách** (`backend/src/routes/khach.js`): các endpoint chỉ người thuê dùng, có phân quyền và mã lỗi 400/401/403/404/409.
- Tài liệu: báo cáo mục 1, 5, 7 (phần Client), kịch bản video, câu hỏi bảo vệ, hướng dẫn build APK.

### Ngoài phạm vi

- Thanh toán trực tuyến qua cổng (VNPay, Momo): đồ án chỉ ghi nhận **xác nhận chuyển khoản thủ công** kèm biên lai, chủ trọ kiểm tra và xác nhận bên App Admin.
- Chat trực tiếp giữa chủ trọ và người thuê.
- Ứng dụng iOS: mã nguồn Flutter có thể build iOS nhưng đồ án chỉ phát hành APK Android.

## 1.4. Tác nhân và quyền hạn

| Tác nhân | Vai trò trong hệ thống | Quyền chính |
|---|---|---|
| Chủ trọ | `CHU_TRO` | Toàn quyền: khu trọ, phòng, hợp đồng, biểu giá, chỉ số, hóa đơn, xác nhận thanh toán, sự cố, lịch xem, báo cáo |
| Quản lý khu trọ | `QUAN_LY` | Ghi chỉ số điện nước, xử lý sự cố; không sửa biểu giá, không xem báo cáo doanh thu |
| Người thuê | `NGUOI_THUE` | Dùng App Client: tìm phòng, đặt lịch, xem hợp đồng/hóa đơn, gửi biên lai, báo sự cố, xem nhắc hạn |

## 1.5. Kiến trúc tổng thể

```
┌──────────────────────────┐        ┌──────────────────────────┐
│  555Rental Admin         │        │  555Rental Khách         │
│  Android (Java + XML)    │        │  Flutter (Dart)          │
│  Retrofit + Gson         │        │  http + shared_preferences│
└────────────┬─────────────┘        └────────────┬─────────────┘
             │  HTTPS / JSON + JWT               │
             └───────────────┬───────────────────┘
                             ▼
              ┌──────────────────────────────┐
              │  Backend REST API            │
              │  Node.js + Express + pg      │
              │  JWT, bcrypt, multer         │
              │  https://rental-nhom555-     │
              │  api.onrender.com            │
              └──────────────┬───────────────┘
                             │ SQL
                             ▼
              ┌──────────────────────────────┐
              │  PostgreSQL (Supabase)       │
              │  + Supabase Storage (ảnh)    │
              └──────────────────────────────┘
```

- **Một backend, hai app**: cùng contract JSON, cùng tài khoản, cùng dữ liệu. Chủ trọ phát hành hóa đơn bên Admin thì vài giây sau người thuê thấy trên Client.
- **Xác thực**: đăng nhập trả JWT (hạn 7 ngày). App Client lưu token trong `shared_preferences`, gắn `Authorization: Bearer <token>` vào mọi request cần đăng nhập; gặp `401` thì xóa phiên và đưa về màn đăng nhập.
- **Ảnh**: biên lai chuyển khoản và ảnh sự cố được app gửi dạng `multipart/form-data`; backend đẩy lên Supabase Storage và lưu URL public vào CSDL.

## 1.6. Công nghệ sử dụng (phần Client)

| Thành phần | Công nghệ / phiên bản | Vai trò |
|---|---|---|
| Ngôn ngữ / framework | Flutter 3.35+ (máy build: 3.47.3), Dart 3 | Xây dựng UI đa nền tảng, phát hành Android |
| Gọi API | package `http` | GET/POST/PATCH/DELETE + multipart |
| Lưu phiên | `shared_preferences` | Token JWT, họ tên, email, vai trò, địa chỉ API |
| Chọn ảnh | `image_picker` | Chụp/chọn ảnh biên lai và ảnh sự cố |
| Định dạng | `intl` + `flutter_localizations` | Định dạng tiền VND, ngày `dd/MM/yyyy`, DatePicker/TimePicker tiếng Việt |
| Kiểm thử | `flutter_test` | 21 test: định dạng, model, widget form |
| Build | Gradle + Android SDK 36, JDK 17 | APK release ký bằng keystore riêng |
| Backend (dùng chung) | Node.js 20, Express 4, `pg`, `jsonwebtoken`, `bcryptjs`, `multer` | REST API, xác thực, upload ảnh |
| CSDL | PostgreSQL (Supabase) | 11 bảng, khóa ngoại, ràng buộc |

## 1.7. Chức năng chính của App Client

1. **Đăng nhập / đăng ký** người thuê, lưu phiên, tự đăng xuất khi token hết hạn.
2. **Tìm phòng trống** theo khu vực, khoảng giá, diện tích; xem chi tiết phòng, bảng giá điện – nước – rác – gửi xe, tiện ích, liên hệ chủ trọ.
3. **Đặt lịch xem phòng** (chọn ngày, giờ, ghi chú); **hủy lịch** kèm hộp thoại xác nhận và nút **Hoàn tác**.
4. **Hợp đồng thuê của tôi**, cảnh báo khi còn **≤ 30 ngày**.
5. **Hóa đơn hằng tháng**: chi tiết từng khoản, chỉ số điện/nước đầu – cuối, số tiêu thụ, lịch sử thanh toán của hóa đơn.
6. **Gửi xác nhận thanh toán**: nhập số tiền, chọn chuyển khoản/tiền mặt, đính kèm ảnh biên lai; chống gửi trùng.
7. **Lịch sử thanh toán** và trạng thái chờ/đã xác nhận.
8. **Báo sự cố** kèm ảnh, theo dõi tiến trình: Đã gửi → Đang xử lý → Hoàn tất.
9. **Nhắc hạn**: hóa đơn đến hạn/quá hạn, hợp đồng sắp hết hạn; badge số việc trên AppBar.
10. **Tài khoản**: hồ sơ, đổi địa chỉ API (để demo backend local), đăng xuất.

## 1.8. Kết quả đạt được

| Hạng mục | Kết quả |
|---|---|
| Mã nguồn Client | `client-flutter/` – 18 màn hình, 8 model dữ liệu, tầng API dùng chung |
| Chất lượng mã | `flutter analyze` → **No issues found!** |
| Kiểm thử tự động | `flutter test` → **21 test pass** |
| APK release | [`client-flutter/releases/555Rental-Khach-v1.0.0.apk`](../client-flutter/releases/555Rental-Khach-v1.0.0.apk) – đã ký, cài trên máy thật |
| Route API khách | `backend/src/routes/khach.js` – 13 endpoint (gồm upload ảnh), đủ mã lỗi 400/401/403/404/409 |
| API chạy thật | <https://rental-nhom555-api.onrender.com> (health check `{"ok":true,"db":"ok"}`) |
| Tài khoản demo | `nguoithue01@555rental.vn` / `123456` |
| Tài liệu | Mục 1, 5, 7 (Client), kịch bản video, Q&A, hướng dẫn build |

## 1.9. Bố cục báo cáo phần Client

| Mục | Tài liệu |
|---|---|
| Mục 1 – Giới thiệu | `docs/bao-cao-muc-1-gioi-thieu.md` (tài liệu này) |
| Mục 5 – Giao diện Client | `docs/bao-cao-muc-5-giao-dien-client.md` |
| Mục 7 – Kiểm thử Client | `docs/bao-cao-muc-7-kiem-thu-client.md` |
| Video demo | `docs/kich-ban-video-client.md` |
| Câu hỏi bảo vệ | `docs/cau-hoi-bao-ve-client.md` |
| Build APK | `docs/huong-dan-build-apk-client.md` |
| README Client | `client-flutter/README.md` |
| README Backend | `backend/README.md` |
