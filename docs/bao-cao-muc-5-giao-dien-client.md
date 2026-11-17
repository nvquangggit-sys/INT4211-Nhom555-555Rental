# Mục 5 – Giao diện App Client (Flutter)

> App **555Rental Khách** – dành cho người thuê (`NGUOI_THUE`).
> Mã nguồn: `client-flutter/`. APK: `client-flutter/releases/555Rental-Khach-v1.0.0.apk`.
> Backend dùng chung: `https://rental-nhom555-api.onrender.com`.

## 5.1. Kiến trúc mã nguồn

```
client-flutter/lib/
├── main.dart                     # Khởi động, MaterialApp, điều hướng khi hết phiên
├── core/
│   ├── api_service.dart          # Tầng gọi API duy nhất (token, timeout 90s, UTF-8, 401)
│   ├── api_exception.dart        # ApiException + PhienHetHanException
│   └── dinh_dang.dart            # Định dạng tiền, ngày, tháng, nhắc hạn
├── models/
│   ├── nguoi_dung.dart           # Người dùng + KetQuaDangNhap
│   ├── phong.dart                # Phòng + tiện ích + tổng số kết quả
│   ├── lich_xem_phong.dart       # Lịch xem phòng
│   ├── hop_dong.dart             # Hợp đồng + số ngày còn lại
│   ├── hoa_don.dart              # Hóa đơn + chi tiết khoản + thanh toán + chỉ số
│   ├── thanh_toan.dart           # Giao dịch thanh toán
│   ├── su_co.dart                # Báo cáo sự cố + loại sự cố
│   └── nhac_han.dart             # Nhắc hạn hóa đơn/hợp đồng
└── ui/
    ├── theme.dart                # Màu, theme Material 3, các khối trạng thái dùng chung
    ├── widgets/
    │   ├── anh_mang.dart         # Ảnh mạng có loading/error builder
    │   └── trang_thai.dart       # Nhãn trạng thái màu theo mã
    └── screens/                  # 18 màn hình
```

**Nguyên tắc thiết kế**

- **Một cửa vào API**: mọi màn hình gọi `ApiService.instance.get/post/postMultipart/delete`. Không nơi nào tự dùng `http` trực tiếp → dễ đổi `baseUrl`, dễ thêm header, dễ xử lý 401 một chỗ.
- **Model tự đọc JSON**: mỗi model có `tuJson(Map)` chịu được dữ liệu “bẩn” của PostgreSQL: `NUMERIC` trả về chuỗi (`"15.0"`), cột nullable, mảng JSON lồng nhau.
- **UI tách khỏi dữ liệu**: màn hình chỉ lo hiển thị; `Future` được tạo trong `initState` hoặc khi người dùng bấm Lọc/Tải lại, không tạo trong `build`.
- **Tái sử dụng khối trạng thái**: `KhungDangTai`, `ManHinhLoi`, `MucRong`, `DongThongTin`, `TheSoLieu`, `NhanTrangThai` dùng chung để 18 màn hình có cùng ngôn ngữ hình ảnh.

## 5.2. Sơ đồ điều hướng

```
main()
 └─ daDangNhap? ── có token ──► HomeShell (NavigationBar 5 tab + Drawer)
                └─ chưa có ──► LoginScreen ──► RegisterScreen
                                   │
                                   └─(đăng nhập OK)──► HomeShell

HomeShell
 ├─ Tab 0 Trang chủ ....... HomeTab ──► ContractsScreen / RemindersScreen / InvoiceDetailScreen
 ├─ Tab 1 Tìm phòng ....... RoomsTab ──► RoomDetailScreen ──► BookingScreen
 ├─ Tab 2 Hóa đơn ......... InvoicesTab ──► InvoiceDetailScreen ──► PaymentScreen
 │                                     └─► PaymentHistoryScreen
 ├─ Tab 3 Sự cố ........... IncidentsTab ──► IncidentCreateScreen
 ├─ Tab 4 Tài khoản ....... AccountTab ──► ContractsScreen / MyBookingsScreen /
 │                                          PaymentHistoryScreen / RemindersScreen /
 │                                          ApiSettingsScreen
 ├─ Drawer ................ lối tắt tới các màn trên + Đăng xuất
 └─ AppBar ................ badge nhắc hạn ──► RemindersScreen
```

Kỹ thuật điều hướng:

- `Navigator.push` + `MaterialPageRoute` cho màn chi tiết.
- **Trả kết quả bằng `Navigator.pop(true)`**: `BookingScreen` → `RoomDetailScreen` → `RoomsTab` để tải lại danh sách phòng; `PaymentScreen` → `InvoiceDetailScreen` để làm mới hóa đơn; `IncidentCreateScreen` → `IncidentsTab` để tải lại danh sách sự cố.
- `HomeShell` dùng `IndexedStack` giữ nguyên trạng thái 5 tab khi chuyển qua lại.
- `main.dart` giữ `GlobalKey<NavigatorState>`; khi `ApiService` phát hiện 401, callback `khiHetPhien` đẩy về `LoginScreen(daHetPhien: true)` và xóa toàn bộ stack.

## 5.3. Danh sách màn hình

| # | Màn hình | Tệp | API sử dụng | Điểm chính |
|---|---|---|---|---|
| 1 | Đăng nhập | `login_screen.dart` | `POST /auth/dang-nhap` | Form + validator, 3 trạng thái, điền tài khoản demo, mở cài đặt API |
| 2 | Đăng ký | `register_screen.dart` | `POST /auth/dang-ky` | 5 ô validate, kiểm tra nhập lại mật khẩu, trả email về màn đăng nhập |
| 3 | Khung chính | `home_shell.dart` | `GET /nhac-han` | NavigationBar 5 tab, Drawer, badge nhắc hạn, FAB báo sự cố |
| 4 | Trang chủ | `home_tab.dart` | `/nhac-han`, `/hop-dong/cua-toi`, `/hoa-don/cua-toi` | Banner nhắc hạn, 4 lối tắt, tóm tắt hợp đồng + hóa đơn gần nhất |
| 5 | Tìm phòng | `rooms_tab.dart` | `GET /phong` | Lọc khu vực/giá/diện tích, `ListView.builder`, 3 trạng thái |
| 6 | Chi tiết phòng | `room_detail_screen.dart` | `GET /phong/:id` | Ảnh lớn, thông tin, bảng giá, tiện ích, liên hệ chủ trọ |
| 7 | Đặt lịch xem | `booking_screen.dart` | `POST /lich-xem-phong` | DatePicker + TimePicker, ghi chú, chống bấm hai lần |
| 8 | Lịch xem của tôi | `my_bookings_screen.dart` | `GET /lich-xem-phong/cua-toi`, `DELETE /lich-xem-phong/:id`, `POST /lich-xem-phong` | Hủy có hộp thoại, SnackBar **Hoàn tác** |
| 9 | Hợp đồng | `contracts_screen.dart` | `GET /hop-dong/cua-toi` | Tiến trình thời hạn, cảnh báo ≤ 30 ngày, cảnh báo quá hạn |
| 10 | Hóa đơn | `invoices_tab.dart` | `GET /hoa-don/cua-toi` | Tổng nợ, lọc Tất cả/Còn nợ/Đã đủ, mở lịch sử thanh toán |
| 11 | Chi tiết hóa đơn | `invoice_detail_screen.dart` | `GET /hoa-don/cua-toi` (lọc theo id) | Các khoản, chỉ số điện/nước, lịch sử thanh toán, banner hạn |
| 12 | Xác nhận thanh toán | `payment_screen.dart` | `POST /thanh-toan` (multipart) | Số tiền, hình thức, `image_picker`, chống double submit |
| 13 | Lịch sử thanh toán | `payment_history_screen.dart` | `GET /thanh-toan/cua-toi` | Lọc đã/chờ xác nhận, xem ảnh biên lai |
| 14 | Sự cố | `incidents_tab.dart` | `GET /bao-su-co/cua-toi` | Thống kê, lọc, timeline 3 bước |
| 15 | Báo sự cố | `incident_create_screen.dart` | `/hop-dong/cua-toi`, `POST /bao-su-co` | Chọn phòng đang thuê, loại sự cố, mô tả, ảnh |
| 16 | Nhắc hạn | `reminders_screen.dart` | `GET /nhac-han` | Tổng quan việc cần làm, danh sách hóa đơn/hợp đồng |
| 17 | Tài khoản | `account_tab.dart` | `GET /auth/toi` | Hồ sơ, menu lối tắt, đổi API, đăng xuất |
| 18 | Địa chỉ API | `api_settings_screen.dart` | `GET /health` | Đổi backend, kiểm tra kết nối |

## 5.4. Chi tiết từng nhóm giao diện

### 5.4.1. Đăng nhập (`login_screen.dart`)

- Logo + tên app, tiêu đề “Chào mừng trở lại!”.
- `Form` gồm email và mật khẩu. Validator:
  - Email rỗng → “Vui lòng nhập email”; sai định dạng → “Email không đúng định dạng”.
  - Mật khẩu rỗng → “Vui lòng nhập mật khẩu”; `< 6` ký tự → “Mật khẩu phải có ít nhất 6 ký tự”.
- Nút hiện/ẩn mật khẩu, `textInputAction` chuyển ô và submit bằng bàn phím.
- Trạng thái gửi: nút đổi thành vòng xoay, khóa cả nút đăng ký và nút cài đặt API.
- Lỗi backend (sai mật khẩu, mất mạng, timeout) hiện trong khối đỏ ngay trên nút, giữ nguyên dữ liệu đã nhập.
- Khối “Tài khoản thử: `nguoithue01@555rental.vn / 123456`” – chạm để điền nhanh, phục vụ chấm bài.
- Góc phải trên: nút **Địa chỉ API** để đổi backend khi demo local.
- Khi bị đẩy về do hết phiên: hiện banner “Phiên đăng nhập đã hết hạn”.

### 5.4.2. Đăng ký (`register_screen.dart`)

- 5 ô: họ tên, email, số điện thoại, mật khẩu, nhập lại mật khẩu.
- Validate: họ tên ≥ 2 ký tự; email đúng định dạng; SĐT bắt đầu bằng 0 và đủ 10–11 số (khớp backend); mật khẩu ≥ 6; nhập lại phải khớp.
- Gọi `POST /auth/dang-ky`; thành công hiện SnackBar và `Navigator.pop(email)` về màn đăng nhập, tự điền email vừa tạo.
- Lỗi 409 (email đã tồn tại) hiện đúng thông điệp backend.

### 5.4.3. Khung chính (`home_shell.dart`)

- `NavigationBar` 5 tab: Trang chủ, Tìm phòng, Hóa đơn, Sự cố, Tài khoản.
- `Drawer` nền gradient mang màu thương hiệu, hiện avatar chữ cái đầu, họ tên, email; các mục: 5 tab + Hợp đồng, Lịch xem phòng, Lịch sử thanh toán, Nhắc hạn, Địa chỉ API, Đăng xuất.
- AppBar có chuông nhắc hạn: nếu `/nhac-han` trả việc cần làm thì hiện `Badge.count` màu cam.
- FAB “Báo sự cố” chỉ hiện ở tab Sự cố.
- `IndexedStack` giữ trạng thái từng tab; đăng xuất có `AlertDialog` xác nhận.

### 5.4.4. Trang chủ (`home_tab.dart`)

- Lời chào theo giờ trong ngày + tên người dùng.
- **Banner nhắc hạn** (dữ liệu `GET /nhac-han`):
  - Không có việc → banner xanh “Mọi thứ đang ổn!”.
  - Có việc → banner cam; nếu có hóa đơn quá hạn → banner đỏ kèm icon cảnh báo, hiện số việc, hóa đơn gần nhất và hợp đồng sắp hết hạn.
  - Chạm banner hoặc “Xem nhắc hạn” → `RemindersScreen`; “Xem hóa đơn” → tab Hóa đơn.
- 4 thẻ lối tắt: Tìm phòng, Hợp đồng, Hóa đơn, Sự cố.
- Thẻ hợp đồng đầu tiên: ảnh phòng, giá thuê, tiền cọc, hạn hợp đồng, cảnh báo cam nếu ≤ 30 ngày.
- Thẻ hóa đơn gần nhất: tổng tiền, hạn thanh toán, số còn nợ; chạm để mở chi tiết.
- Kéo xuống để tải lại cả 3 nguồn dữ liệu.

### 5.4.5. Tìm phòng (`rooms_tab.dart`)

- Ô tìm “Khu vực, tên đường…” + nút **Lọc**; nút mở rộng bộ lọc giá từ/đến, diện tích từ.
- Chip nhanh “Dưới 3 triệu”, “3–5 triệu”, “Xóa lọc”.
- Chỉ lấy phòng `TRONG` (`trangThai=TRONG`) và `limit=60`.
- `ListView.builder` (không dùng `ListView` thường) để cuộn mượt; dòng đầu hiển thị “x phòng trống phù hợp” lấy từ `tong_so` backend trả kèm.
- 3 trạng thái rõ ràng:
  1. **Đang tải**: `KhungDangTai` với vòng xoay và thông điệp.
  2. **Lỗi**: `ManHinhLoi` + nút “Thử lại” (giữ nguyên bộ lọc).
  3. **Thành công**: danh sách; nếu rỗng hiện `MucRong` + nút “Xóa bộ lọc”.
- `Future` chỉ tạo trong `initState` và khi bấm Lọc / kéo xuống, không tạo trong `build`.
- Chạm thẻ phòng → chi tiết; đặt lịch xong quay lại tự tải lại danh sách.

### 5.4.6. Chi tiết phòng (`room_detail_screen.dart`)

- Tải mới `GET /phong/:id` để có thêm tên/SĐT chủ trọ (danh sách không có).
- Ảnh lớn 220 px dùng `AnhMang` – `loadingBuilder` hiện shimmer/vòng xoay, `errorBuilder` hiện khung “Không tải được ảnh”.
- Tên phòng, khu, địa chỉ, phường/xã, nhãn trạng thái, giá thuê/tháng.
- Card thông tin: diện tích, sức chứa, khu trọ, chủ trọ, điện thoại.
- Card chi phí: giá điện/kWh, nước/m³, phí rác, phí gửi xe + ghi chú cách tính theo chỉ số.
- Chip tiện ích (wifi, camera, giữ xe…).
- Thanh dưới cùng: giá/tháng + nút **Đặt lịch xem phòng**; phòng đã thuê thì nút bị vô hiệu và đổi chữ “Phòng đã được thuê”.

### 5.4.7. Đặt lịch xem phòng (`booking_screen.dart`)

- Tóm tắt phòng đang đặt.
- Chọn ngày bằng `showDatePicker` (từ hôm nay đến +60 ngày, tiếng Việt) và giờ bằng `showTimePicker` (định dạng 24h).
- Kiểm tra thời gian phải sau hiện tại ít nhất 30 phút; báo lỗi tại chỗ nếu không.
- Ghi chú tối đa 300 ký tự.
- Gửi `POST /lich-xem-phong` với `thoi_gian` ISO UTC; khi đang gửi khóa nút (không gửi trùng).
- Thành công: SnackBar + `Navigator.pop(true)`; lỗi 400/404/409 hiện nguyên văn thông điệp backend (ví dụ “Phòng đã được thuê, không thể đặt lịch”, “Bạn đã có lịch chờ xác nhận cho phòng này”).

### 5.4.8. Lịch xem phòng của tôi (`my_bookings_screen.dart`)

- Danh sách lịch đã đặt, sắp xếp mới nhất trước; mỗi thẻ có ảnh phòng, tên phòng/khu, thời gian, địa chỉ, nhãn trạng thái.
- Chỉ lịch `CHO_XAC_NHAN` và còn ở tương lai mới hiện nút **Hủy lịch**.
- Hủy theo 2 bước: `AlertDialog` “Hủy lịch xem phòng?” → gọi `DELETE /lich-xem-phong/:id`.
- Sau khi hủy: tải lại danh sách + `SnackBar` 6 giây có nút **Hoàn tác**; bấm Hoàn tác sẽ `POST /lich-xem-phong` tạo lại đúng phòng, đúng thời gian.
- Lỗi 404/409 hiện SnackBar đỏ với thông điệp backend (ví dụ lịch đã được chủ trọ xác nhận).

### 5.4.9. Hợp đồng thuê (`contracts_screen.dart`)

- Mỗi hợp đồng: ảnh phòng, phòng/khu, địa chỉ, nhãn trạng thái.
- Khối thời hạn: ngày bắt đầu → ngày kết thúc, thanh tiến trình `LinearProgressIndicator` theo thời gian đã thuê.
- Màu thanh: xanh khi còn nhiều, **cam khi ≤ 30 ngày**, đỏ khi đã hết hạn.
- Dòng chữ “còn N ngày / đến hạn hôm nay / đã quá hạn N ngày”.
- Giá thuê, tiền cọc, số người, diện tích, tên + SĐT chủ trọ.
- **Cảnh báo ≤ 30 ngày**: khối cam “Hợp đồng sắp hết hạn… liên hệ chủ trọ … trước ngày …”.
- Quá hạn: khối đỏ hướng dẫn gia hạn/trả phòng.

### 5.4.10. Hóa đơn (`invoices_tab.dart`)

- Đầu trang: **Tổng còn nợ** (đỏ nếu > 0, xanh nếu = 0), số hóa đơn, nút tải lại, lối vào Lịch sử thanh toán.
- Chip lọc: Tất cả / Còn nợ / Đã đủ.
- Thẻ hóa đơn: tháng, phòng, khu, tổng tiền, đã thu, còn nợ, hạn thanh toán; quá hạn hiện “Quá hạn N ngày” màu đỏ.
- 3 trạng thái tải/lỗi/rỗng; kéo xuống để làm mới; mở chi tiết rồi quay lại tự tải lại.

### 5.4.11. Chi tiết hóa đơn (`invoice_detail_screen.dart`)

- Tiêu đề tháng + phòng + hạn thanh toán + nhãn trạng thái.
- **Banner nhắc hạn** theo số ngày còn lại: xanh dương khi còn nhiều, cam khi ≤ 5 ngày, đỏ khi quá hạn.
- Card tổng tiền – đã thu – còn nợ.
- **Chi tiết các khoản**: tên khoản, số lượng × đơn giá, thành tiền; tổng cộng.
- **Chỉ số điện nước**: chỉ số đầu, chỉ số cuối, số tiêu thụ (tính từ model).
- **Lịch sử thanh toán của hóa đơn**: số tiền, hình thức, thời điểm, trạng thái chờ/đã xác nhận, ảnh biên lai (chạm mở dialog lớn).
- Nút “Gửi xác nhận thanh toán <số còn nợ>” hoặc khối xanh “Hóa đơn đã thanh toán đủ”.

> Backend không có endpoint xem 1 hóa đơn cho người thuê, nên màn này gọi `GET /hoa-don/cua-toi` rồi lọc theo `id`. Cách này bảo đảm luôn có dữ liệu mới nhất sau khi chủ trọ xác nhận thanh toán.

### 5.4.12. Xác nhận thanh toán (`payment_screen.dart`)

- Tóm tắt hóa đơn: tổng tiền, đã thu, còn nợ.
- Ô số tiền (chỉ nhập số), chip “Trả toàn bộ” / “Một nửa”; validate: > 0 và không vượt quá số còn nợ (khớp backend).
- `SegmentedButton` chọn **Chuyển khoản** / **Tiền mặt**.
- Khối gợi ý nội dung chuyển khoản: `P<số phòng> T<tháng> <số tiền>`.
- **Ảnh biên lai**:
  - Chọn từ thư viện bằng `image_picker` (`maxWidth 1800`, quality 80).
  - Xem trước ảnh, nút bỏ ảnh, nút chọn ảnh khác; `errorBuilder` nếu file hỏng.
  - Chuyển khoản bắt buộc ảnh; tiền mặt không bắt buộc.
- Gửi `multipart/form-data` tới `POST /thanh-toan` với `hoa_don_id`, `so_tien`, `hinh_thuc`, file `anh`.
- **Chống gửi trùng**: cờ `_dangGui` khóa toàn bộ ô nhập/nút; nút đổi thành “Đang gửi biên lai…”.
- Thành công: dialog xác nhận (hiện `thong_diep` backend) → `Navigator.pop(true)` để chi tiết hóa đơn tải lại.
- Lỗi 400/404/409/500 hiện khối đỏ, giữ dữ liệu để người dùng sửa.

### 5.4.13. Lịch sử thanh toán (`payment_history_screen.dart`)

- Danh sách giao dịch mới nhất trước; chip lọc Tất cả / Đã xác nhận / Chờ (kèm số lượng).
- Mỗi giao dịch: số tiền, hóa đơn tháng + phòng, hình thức, thời điểm, nhãn “Đã xác nhận”/“Chờ xác nhận”, người xác nhận.
- Ảnh biên lai thu nhỏ, chạm mở dialog xem lớn.

### 5.4.14. Sự cố (`incidents_tab.dart`)

- 3 ô thống kê: Tổng báo cáo, Đang xử lý, Đã xử lý.
- Chip lọc: Tất cả / Chờ xử lý / Đã xử lý.
- Mỗi báo cáo: loại sự cố, phòng/khu, mô tả, ảnh hiện trạng (chạm xem lớn), nhãn trạng thái.
- **Timeline 3 bước**: Đã gửi → Đang xử lý → Hoàn tất; bước đã đạt tô màu, bước chưa tô xám; có “Cập nhật lần cuối”.
- Trạng thái `TU_CHOI` hiện ghi chú đỏ.
- FAB “Báo sự cố” ở `HomeShell`; gửi xong tự tải lại tab.

### 5.4.15. Báo sự cố (`incident_create_screen.dart`)

- Tải `GET /hop-dong/cua-toi`, chỉ giữ hợp đồng `HIEU_LUC` để chọn phòng đang thuê (không cho báo sự cố phòng người khác).
- Dropdown phòng, dropdown loại sự cố (Hỏng điện, Hỏng nước, Khóa cửa, Wifi, Khác…), mô tả ≥ 10 ký tự, tối đa 500.
- Ảnh hiện trạng không bắt buộc; chọn/xem trước/xóa ảnh.
- Có ảnh → gửi multipart; không ảnh → gửi JSON. Cùng endpoint `POST /bao-su-co`.
- Thành công: dialog “Đã gửi báo cáo sự cố” → `pop(true)`.
- Không có hợp đồng hiệu lực → màn rỗng hướng dẫn liên hệ chủ trọ.

### 5.4.16. Nhắc hạn (`reminders_screen.dart`)

- Gọi `GET /nhac-han` trả `{hoa_don: [...], hop_dong: [...]}` với `so_ngay_con_lai` (âm = quá hạn).
- Khối tổng quan: số việc cần xử lý, tổng còn nợ, màu đỏ nếu có hóa đơn quá hạn.
- Danh sách hóa đơn cần thanh toán: chạm mở chi tiết hóa đơn.
- Danh sách hợp đồng sắp hết hạn: chạm mở màn hợp đồng.
- Không có việc → màn rỗng “Không có việc nào sắp đến hạn”.

### 5.4.17. Tài khoản (`account_tab.dart`)

- Thẻ hồ sơ: avatar chữ cái đầu, họ tên, email, nhãn vai trò, SĐT, CCCD; nút đồng bộ lại từ `GET /auth/toi`.
- Nếu mất mạng: hiện ghi chú “Đang dùng hồ sơ lưu trên máy” + nút Thử lại (không chặn các mục khác).
- Nhóm “Thuê phòng của tôi”: Hợp đồng, Lịch xem phòng, Lịch sử thanh toán, Nhắc hạn.
- Nhóm “Cài đặt”: Địa chỉ API, Thông tin ứng dụng (AboutDialog có phiên bản + API hiện tại).
- Nút Đăng xuất (đỏ) + hộp thoại xác nhận.

### 5.4.18. Địa chỉ API (`api_settings_screen.dart`)

- Hiện URL hiện tại, ô nhập URL mới; tự thêm `https://` nếu thiếu và bỏ `/` cuối.
- Nút **Kiểm tra kết nối** gọi `GET /health`, hiện kết quả (dịch vụ, phiên bản, trạng thái DB).
- Nút Lưu → lưu `shared_preferences`, áp dụng ngay cho request sau; có nút khôi phục mặc định.
- Dùng khi demo backend local (`http://10.0.2.2:3000` với emulator hoặc `adb reverse` với máy thật).

## 5.5. Thành phần giao diện dùng chung

| Thành phần | Tệp | Mô tả |
|---|---|---|
| `AnhMang` | `ui/widgets/anh_mang.dart` | `Image.network` có `loadingBuilder` (khung xám + vòng xoay) và `errorBuilder` (icon + “Không tải được ảnh”); hỗ trợ bo góc, kích thước |
| `NhanTrangThai` | `ui/widgets/trang_thai.dart` | Map mã trạng thái → màu + nhãn tiếng Việt: `TRONG`, `DA_THUE`, `HIEU_LUC`, `CHO_XAC_NHAN`, `DA_XAC_NHAN`, `MOI`, `DANG_XU_LY`, `DA_XU_LY`, `MOT_PHAN`, `DA_THU`, `QUA_HAN`… |
| `KhungDangTai` | `ui/theme.dart` | Trạng thái đang tải thống nhất |
| `ManHinhLoi` | `ui/theme.dart` | Icon wifi-off, thông điệp, nút “Thử lại” |
| `MucRong` | `ui/theme.dart` | Trạng thái rỗng có icon, tiêu đề, mô tả, nút hành động tùy chọn |
| `DongThongTin` | `ui/theme.dart` | Dòng nhãn – giá trị kèm icon |
| `TheSoLieu` | `ui/theme.dart` | Thẻ lối tắt màu |
| Theme | `ui/theme.dart` | Material 3, màu thương hiệu `#1565C0`, nền `#F5F7FB`, bo góc 16, input dày 48 |

## 5.6. Xử lý lỗi và trải nghiệm người dùng

| Tình huống | Cách xử lý |
|---|---|
| Render Free ngủ đông | Timeout **90 giây**; thông điệp “Máy chủ chưa phản hồi sau 90 giây (Render có thể đang ngủ đông)” |
| Mất mạng / sai URL | Bắt `SocketException`, `http.ClientException` → thông điệp thân thiện + nút Thử lại |
| Token hết hạn (401) | Chỉ coi là hết phiên khi **đang có token**; xóa phiên, đưa về đăng nhập kèm banner. Nhờ vậy đăng nhập sai mật khẩu vẫn hiện đúng “Email hoặc mật khẩu không đúng” thay vì nhảy màn hình |
| Tiếng Việt lỗi font | Mọi response đọc bằng `utf8.decode(res.bodyBytes)` thay vì `res.body` |
| Gọi API khi widget đã đóng | Mọi `setState`/`Navigator` sau `await` đều có `if (!mounted) return;` |
| Bấm gửi nhiều lần | Cờ `_dangGui` khóa nút ở đăng nhập, đặt lịch, thanh toán, báo sự cố |
| Danh sách dài | `ListView.builder` + `RefreshIndicator` |
| Ảnh lỗi/không tải được | `errorBuilder` ở mọi nơi hiển thị ảnh |
| JSON lạ (NUMERIC dạng chuỗi, null) | Hàm `chuoi()`, `soNguyen()`, `soThuc()` trong model chịu được cả `int`, `double`, `String`, `null` |
| Xoay màn hình | Flutter tự rebuild; dữ liệu nằm trong `Future` của State nên không mất |

## 5.7. Ánh xạ yêu cầu C1–C4 → giao diện

| Yêu cầu | Minh chứng trong mã nguồn |
|---|---|
| **C1** Flutter 3.35+, `http` + `shared_preferences` | `pubspec.yaml`; `core/api_service.dart`; `main.dart` |
| **C1** ApiService: UTF-8, timeout 90s, mounted, 401 → login | `api_service.dart` dòng `utf8.decode(bodyBytes)`, `thoiGianCho = 90s`, `khiHetPhien`; toàn bộ screen có kiểm tra `mounted` |
| **C1** Form + validator đăng nhập/đăng ký | `login_screen.dart`, `register_screen.dart`; test `login_screen_test.dart` |
| **C1** Scaffold + NavigationBar/Drawer | `home_shell.dart` |
| **C2** Route khách + mã lỗi | `backend/src/routes/khach.js` |
| **C3** Tìm phòng: lọc, ListView.builder, Future trong initState, 3 trạng thái | `rooms_tab.dart` |
| **C3** Chi tiết phòng: ảnh loading/error, đặt lịch, `Navigator.pop(result)` | `room_detail_screen.dart`, `booking_screen.dart`, `anh_mang.dart` |
| **C3** Lịch xem: hủy + dialog + SnackBar Hoàn tác | `my_bookings_screen.dart` |
| **C3** Hợp đồng: cảnh báo < 30 ngày | `contracts_screen.dart` |
| **C4** Hóa đơn: danh sách/chi tiết, khoản, chỉ số | `invoices_tab.dart`, `invoice_detail_screen.dart` |
| **C4** Lịch sử thanh toán | `payment_history_screen.dart` |
| **C4** Xác nhận chuyển khoản + ảnh, không gửi trùng | `payment_screen.dart` |
| **C4** Báo sự cố + theo dõi trạng thái | `incident_create_screen.dart`, `incidents_tab.dart` |
| **C4** Banner nhắc hạn từ `/nhac-han` | `home_tab.dart`, `reminders_screen.dart`, `home_shell.dart` |
| **C4** ≥ 6 màn hình, `flutter analyze` sạch, APK release | 18 màn hình; log analyze; `releases/555Rental-Khach-v1.0.0.apk` |
| **C4** ≥ 8 ca kiểm thử | `test/` (21 test) + `docs/bao-cao-muc-7-kiem-thu-client.md` |
