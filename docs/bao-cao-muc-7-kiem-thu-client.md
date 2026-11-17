# Mục 7 – Kiểm thử App Client (10 ca + 21 test tự động)

> Thời điểm kiểm thử: **17/11/2026**.
> Môi trường: API Render `https://rental-nhom555-api.onrender.com`, app Flutter build release `555Rental-Khach-v1.0.0.apk`, Flutter 3.47.3 / Dart 3.13.3.
> Các kết quả API dưới đây được gọi thật bằng `curl.exe`; các ca giao diện được đối chiếu với mã nguồn và `flutter test`. Ca nào cần ảnh chụp trên máy thật được ghi rõ **[cần ảnh máy thật]** – khi nộp báo cáo thay bằng ảnh tương ứng.

## 7.1. Bảng 10 ca kiểm thử chức năng

| Mã | Chức năng | Các bước thực hiện | Dữ liệu vào | Kết quả mong đợi | Kết quả thực tế | Đạt |
|---|---|---|---|---|---|---|
| **TC-C01** | Đăng nhập đúng, lưu phiên | 1. Mở app<br>2. Nhập email/mật khẩu người thuê<br>3. Bấm Đăng nhập<br>4. Thoát app rồi mở lại | `nguoithue01@555rental.vn` / `123456` | Vào Trang chủ; token + vai trò `NGUOI_THUE` được lưu; mở lại app không phải đăng nhập | `POST /auth/dang-nhap` → `200`, token dài 243 ký tự, `vai_tro = NGUOI_THUE`, `id = 3`; app lưu token vào `shared_preferences` và chuyển `HomeShell` **[cần ảnh máy thật]** | ✅ |
| **TC-C02** | Đăng nhập sai mật khẩu | 1. Nhập đúng email<br>2. Nhập `sai123`<br>3. Bấm Đăng nhập | `nguoithue01@555rental.vn` / `sai123` | Ở lại màn đăng nhập, hiện “Email hoặc mật khẩu không đúng.”, không bị coi là hết phiên | API → `401` `{"loi":"Email hoặc mật khẩu không đúng"}`. `ApiService` chỉ ném `PhienHetHanException` khi **đang có token**, nên app hiện đúng thông điệp backend và giữ form **[cần ảnh máy thật]** | ✅ |
| **TC-C03** | Validate form đăng nhập/đăng ký | 1. Bỏ trống email + mật khẩu → bấm Đăng nhập<br>2. Nhập `abc` / `123`<br>3. Mở Đăng ký, nhập mật khẩu `123456`, nhập lại `654321` → bấm Tạo tài khoản | Chuỗi rỗng; `abc`; `123`; `123456` / `654321` | Không gọi API; báo đúng “Vui lòng nhập email”, “Email không đúng định dạng”, “Mật khẩu phải có ít nhất 6 ký tự”, “Mật khẩu nhập lại không khớp” | 4 widget test trong `test/login_screen_test.dart` đều pass; validator chặn trước khi gọi API | ✅ |
| **TC-C04** | Tìm phòng + bộ lọc | 1. Mở tab Tìm phòng<br>2. Nhập `Bình Thạnh`, bấm Lọc<br>3. Mở bộ lọc, nhập giá đến `3000000`<br>4. Bấm Xóa lọc | `khuVuc=Bình Thạnh&trangThai=TRONG&limit=3`; `giaDen=3000000`; `giaTu=-1` | Có kết quả đúng khu; lọc dưới 3 triệu trả rỗng và hiện màn “Không tìm thấy phòng phù hợp”; giá âm bị chặn | `khuVuc=Bình Thạnh` → 3 phòng, `tong_so=3`; `giaDen=3000000` → `[]` → `MucRong` + nút “Xóa bộ lọc”; `giaTu=-1` → `400` “Giá từ phải lớn hơn hoặc bằng 0”; `limit` mặc định 20, tối đa 100 | ✅ |
| **TC-C05** | Chi tiết phòng + đặt lịch | 1. Chạm phòng 117<br>2. Chọn ngày mai, giờ 09:00<br>3. Gửi yêu cầu<br>4. Thử đặt với thời gian `2020-01-01` | `phong_id=17`, `thoi_gian` tương lai; sau đó thời gian quá khứ | Chi tiết hiện ảnh, giá, tiện ích, chủ trọ; đặt thành công tạo lịch `CHO_XAC_NHAN` và quay lại danh sách; thời gian quá khứ bị chặn | `GET /phong/17` → `200` kèm `ten_chu_tro`, `sdt_chu_tro`; `GET /phong/99999` → `404` “Không tìm thấy phòng”; `POST /lich-xem-phong` → `201` (id 12); thời gian quá khứ → `400` “Thời gian xem phòng phải ở tương lai” | ✅ |
| **TC-C06** | Hủy lịch + Hoàn tác | 1. Mở Lịch xem phòng<br>2. Bấm Hủy lịch → Hủy lịch trong hộp thoại<br>3. Bấm Hoàn tác trên SnackBar<br>4. Thử hủy lịch đã xác nhận | Lịch id 10 (`CHO_XAC_NHAN`); lịch id 1 (`DA_XAC_NHAN`) | Hủy thành công, danh sách tải lại, SnackBar 6 giây có Hoàn tác; hoàn tác tạo lại lịch; lịch đã xác nhận không hủy được | `DELETE /lich-xem-phong/10` → `200` `{"da_huy":true,...}`; `POST /lich-xem-phong` tạo lại → `201` id 11; `DELETE /lich-xem-phong/1` và id `99999` → `404` “Không tìm thấy lịch xem đang chờ xác nhận của bạn” | ✅ |
| **TC-C07** | Hóa đơn + thanh toán biên lai | 1. Mở tab Hóa đơn<br>2. Mở hóa đơn tháng 10<br>3. Bấm Gửi xác nhận thanh toán<br>4. Chọn ảnh biên lai, gửi<br>5. Gửi lại lần 2 | Hóa đơn id 1, còn nợ `1904800`; ảnh PNG | Chi tiết hiện 5 khoản, chỉ số điện 1637→1919, nước 174→180, lịch sử thanh toán; gửi ảnh `201` và lưu URL Supabase; gửi lần 2 bị chặn | `GET /hoa-don/cua-toi` → `200`, `chi_tiet` 5 dòng, tiêu thụ điện `282 kWh`, nước `6 m³`; `POST /thanh-toan` (multipart, ảnh) trước đó → `201`, `anh_bien_lai` là URL `.../bien-lai/...`; gửi thêm khi còn giao dịch chờ → `409` “Hóa đơn đang có giao dịch chờ chủ trọ xác nhận”; app còn khóa nút bằng cờ `_dangGui` **[cần ảnh máy thật]** | ✅ |
| **TC-C08** | Cảnh báo hợp đồng ≤ 30 ngày | 1. Mở Hợp đồng thuê<br>2. Quan sát thanh tiến trình và khối cảnh báo<br>3. Kiểm tra dữ liệu thật tháng 11/2026 | Hợp đồng id 1: `2026-01-01` → `2026-12-31` (còn 44 ngày) | Hợp đồng còn ≤ 30 ngày hiện khối cam + “còn N ngày”; còn 44 ngày thì không cảnh báo; quá hạn hiện khối đỏ | API trả `so_ngay_con_lai=44` → app không hiện cảnh báo (đúng). Unit test `HopDong` với `so_ngay_con_lai=20` cho `sapHetHan=true`; mã `contracts_screen.dart` dùng ngưỡng `0..30` và tô cam **[cần ảnh máy thật với dữ liệu mẫu 20 ngày]** | ✅ |
| **TC-C09** | Báo sự cố kèm ảnh + theo dõi | 1. Tab Sự cố → Báo sự cố<br>2. Chọn phòng 101, loại “Hỏng điện”, mô tả, chọn ảnh<br>3. Gửi<br>4. Thử báo sự cố cho phòng 102 | `phong_id=1` (có hợp đồng hiệu lực); `phong_id=2` (không thuê) | Gửi thành công `201`, ảnh lên Supabase, tab hiện timeline “Đã gửi”; phòng không thuê bị `403` | `POST /bao-su-co` multipart → `201`, `anh_url = .../su-co/...`; JSON không ảnh → `201` id 11; `phong_id=2` → `403` “Bạn không có hợp đồng hiệu lực ở phòng này”; form chỉ cho chọn phòng từ `GET /hop-dong/cua-toi` | ✅ |
| **TC-C10** | Nhắc hạn + xử lý lỗi phiên/mạng | 1. Mở chuông nhắc hạn<br>2. Tắt Wi-Fi, kéo xuống tải lại<br>3. Bật Wi-Fi, bấm Thử lại<br>4. Gọi API bằng token rỗng/token rác | Token rỗng; `tokenrac`; không có mạng | Nhắc hạn hiện hóa đơn quá hạn 7 ngày; mất mạng hiện thông báo + nút Thử lại, app không văng; token sai bị đẩy về đăng nhập | `GET /nhac-han` → `200` `so_ngay_con_lai=-7`, 1 hóa đơn; `GET /hoa-don/cua-toi` không token → `401` “Thiếu token đăng nhập”; token rác → `401` “Token không hợp lệ hoặc đã hết hạn”; `api_service.dart` bắt `SocketException`/`TimeoutException` và hiển thị thông điệp thân thiện | ✅ |

## 7.2. Bảng 21 test tự động (`flutter test`)

Chạy:

```powershell
cd client-flutter
flutter test
# 00:00 +21: All tests passed!
```

| # | Tệp | Tên test | Nội dung kiểm tra | Kết quả |
|---|---|---|---|---|
| 1 | `dinh_dang_test.dart` | định dạng tiền VND | `3809600 → 3.809.600 đ`, `null → 0 đ` | ✅ |
| 2 | `dinh_dang_test.dart` | rút gọn triệu/tỷ | `2500000 → 2.5 triệu`, `1.2 tỷ`, `45 nghìn` | ✅ |
| 3 | `dinh_dang_test.dart` | ngày dd/MM/yyyy | `DateTime(2026,10,10) → 10/10/2026` | ✅ |
| 4 | `dinh_dang_test.dart` | tháng hóa đơn | `"2026-10" → Tháng 10/2026` | ✅ |
| 5 | `dinh_dang_test.dart` | đọc ngày ISO | Chuỗi ISO hợp lệ → `DateTime`; chuỗi sai/null → `null` | ✅ |
| 6 | `dinh_dang_test.dart` | nhắc hạn | `12 → còn 12 ngày`, `0 → đến hạn hôm nay`, `-3 → đã quá hạn 3 ngày` | ✅ |
| 7 | `dinh_dang_test.dart` | số ngày còn lại | Bỏ phần giờ, tính đúng theo ngày | ✅ |
| 8 | `dinh_dang_test.dart` | rút gọn văn bản | Cắt 100 ký tự + “…”, xóa khoảng trắng thừa | ✅ |
| 9 | `models_test.dart` | `Phong.tuJson` | `dien_tich "30.0"` → `30.0`; tiện ích tách theo dấu phẩy; `tong_so` | ✅ |
| 10 | `models_test.dart` | `HopDong.tuJson` | Ngày ISO, `sapHetHan` với 20 ngày | ✅ |
| 11 | `models_test.dart` | `HoaDon.tuJson` | 2 khoản, thanh toán đã xác nhận, tiêu thụ điện 282/nước 6, `MOT_PHAN` | ✅ |
| 12 | `models_test.dart` | `ThanhToan.tuJson` | `xac_nhan_boi=null` → chờ xác nhận; ảnh biên lai | ✅ |
| 13 | `models_test.dart` | `SuCo.tuJson` | `DANG_XU_LY → Đang xử lý`; `anh_url=null` | ✅ |
| 14 | `models_test.dart` | `LichXemPhong.tuJson` | `CHO_XAC_NHAN → dangCho=true`; thời gian ISO | ✅ |
| 15 | `models_test.dart` | `NhacHan.tuJson` | Đếm 2 việc; hóa đơn `so_ngay_con_lai=-7 → quaHan=true` | ✅ |
| 16 | `models_test.dart` | `KetQuaDangNhap.tuJson` | Token + `nguoiDung` camelCase; `NGUOI_THUE → Người thuê` | ✅ |
| 17 | `login_screen_test.dart` | bỏ trống email/mật khẩu | 2 thông báo lỗi | ✅ |
| 18 | `login_screen_test.dart` | sai định dạng email, mật khẩu ngắn | 2 thông báo lỗi | ✅ |
| 19 | `login_screen_test.dart` | điền tài khoản demo | Email + `123456` được điền | ✅ |
| 20 | `login_screen_test.dart` | nhập lại mật khẩu không khớp | “Mật khẩu nhập lại không khớp” | ✅ |
| 21 | `login_screen_test.dart` | quay lại từ màn đăng ký | `Navigator.pop` trả về màn trước | ✅ |

## 7.3. Kiểm thử tĩnh

| Hạng mục | Lệnh | Kết quả |
|---|---|---|
| Phân tích mã | `flutter analyze` | **No issues found!** (ran in 4–5s) |
| Kiểm thử | `flutter test` | **21/21 pass** |
| Cú pháp backend | `node --check src/index.js`, `node --check src/routes/khach.js` | Không lỗi |
| Build release | `flutter build apk --release` | `app-release.apk` 55.3 MB, ký bằng keystore `CN=Nguyen Pham Chi Thanh` |

## 7.4. Các mã lỗi đã kiểm tra trên API thật

| Mã | Tình huống | Body thực tế |
|---|---|---|
| `400` | Đặt lịch quá khứ | `{"loi":"Thời gian xem phòng phải ở tương lai"}` |
| `400` | Giá lọc âm | `{"loi":"Giá từ phải lớn hơn hoặc bằng 0"}` |
| `400` | Đăng ký thiếu họ tên | `{"loi":"Thiếu Họ tên"}` |
| `401` | Không gửi token | `{"loi":"Thiếu token đăng nhập"}` |
| `401` | Token rác/hết hạn | `{"loi":"Token không hợp lệ hoặc đã hết hạn"}` |
| `401` | Sai mật khẩu | `{"loi":"Email hoặc mật khẩu không đúng"}` |
| `403` | Báo sự cố phòng không thuê | `{"loi":"Bạn không có hợp đồng hiệu lực ở phòng này"}` |
| `404` | Phòng không tồn tại | `{"loi":"Không tìm thấy phòng"}` |
| `404` | Hủy lịch không phải của mình/đã xác nhận | `{"loi":"Không tìm thấy lịch xem đang chờ xác nhận của bạn"}` |
| `409` | Đăng ký email trùng | `{"loi":"Email (hoặc CCCD) đã tồn tại"}` |
| `409` | Hóa đơn còn giao dịch chờ | `{"loi":"Hóa đơn đang có giao dịch chờ chủ trọ xác nhận"}` |

## 7.5. Cách chụp ảnh minh chứng

| Ca | Ảnh cần chụp |
|---|---|
| TC-C01 | Trang chủ sau đăng nhập + mở lại app vẫn ở Trang chủ |
| TC-C02 | Màn đăng nhập có dòng lỗi đỏ “Email hoặc mật khẩu không đúng.” |
| TC-C03 | Form đăng nhập/đăng ký có 2 ô báo đỏ |
| TC-C04 | Danh sách phòng sau lọc Bình Thạnh + màn rỗng khi lọc dưới 3 triệu |
| TC-C05 | Chi tiết phòng 117 + màn đặt lịch có DatePicker/TimePicker |
| TC-C06 | SnackBar “Đã hủy lịch…” có nút Hoàn tác + danh sách sau khi hoàn tác |
| TC-C07 | Chi tiết hóa đơn (các khoản, chỉ số) + màn thanh toán có ảnh biên lai |
| TC-C08 | Màn hợp đồng (dữ liệu mẫu còn ≤ 30 ngày) có khối cảnh báo cam |
| TC-C09 | Form báo sự cố có ảnh + timeline trạng thái |
| TC-C10 | Banner nhắc hạn quá 7 ngày + màn hình lỗi mạng có nút Thử lại |

## 7.6. Ghi chú

- Dữ liệu seed ngày **17/11/2026**: hóa đơn tháng `2026-10` hạn `2026-11-10` nên đã quá hạn 7 ngày; hợp đồng id 1 hết hạn `2026-12-31` nên còn 44 ngày (chưa vào ngưỡng cảnh báo).
- Để chụp minh chứng cảnh báo hợp đồng, có thể tạm dùng hợp đồng có `ket_thuc` trong vòng 30 ngày trên CSDL demo, hoặc dựa vào unit test `sapHetHan` và ảnh mã nguồn `contracts_screen.dart`.
- Hóa đơn id 1 hiện có một giao dịch chờ xác nhận (100.000 đ) do lần kiểm thử trước; vì vậy API trả `409` khi gửi thêm. Đây là hành vi đúng (chống gửi trùng), không phải lỗi.
- Không kiểm thử trên emulator; APK release cài trên máy Android thật theo `docs/huong-dan-build-apk-client.md`.
