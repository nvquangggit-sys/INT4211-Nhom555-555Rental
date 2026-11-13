# Mục 7 – Kiểm thử App Admin (8 ca)

> Thời điểm kiểm thử: **13/11/2026**.
> Môi trường: API Render `https://rental-nhom555-api.onrender.com/`, APK release `555Rental-Admin-v1.0.0.apk`, `minSdk 24`.
> Cột “Kết quả thực tế” ghi nhận từ lần chạy thật trên API và bản build. Các ca chỉ kiểm tra được trên thiết bị được ghi rõ **[cần ảnh máy thật]** – khi nộp báo cáo thay bằng ảnh chụp màn hình tương ứng.

## Bảng 8 ca kiểm thử

| Mã | Chức năng | Các bước thực hiện | Dữ liệu vào | Kết quả mong đợi | Kết quả thực tế | Đạt |
|---|---|---|---|---|---|---|
| **TC-A01** | Đăng nhập đúng, lưu phiên | 1. Mở app<br>2. Nhập email/mật khẩu chủ trọ<br>3. Bấm Đăng nhập<br>4. Thoát app rồi mở lại | `chutro@555rental.vn` / `123456` | Vào Tổng quan; token + vai trò `CHU_TRO` được lưu; mở lại app không phải đăng nhập | API trả `200`, `vai_tro = CHU_TRO`, có `token`; app chuyển sang `MainActivity`, mở lại vào thẳng Tổng quan | ✅ |
| **TC-A02** | Đăng nhập sai mật khẩu | 1. Nhập đúng email<br>2. Nhập sai mật khẩu<br>3. Bấm Đăng nhập | `chutro@555rental.vn` / `sai123` | Không vào được app; hiện “Email hoặc mật khẩu không đúng.”; nút bấm lại được | API trả `401` `{"loi":"Email hoặc mật khẩu không đúng"}`; app hiện đúng thông báo, giữ nguyên form | ✅ |
| **TC-A03** | Phân quyền `QUAN_LY` | 1. Đăng nhập `quanly@555rental.vn`<br>2. Quan sát drawer<br>3. Dùng Postman gọi báo cáo doanh thu và sửa biểu giá bằng token này | `quanly@555rental.vn` / `123456` | Drawer chỉ còn Ghi chỉ số, Sự cố, Địa chỉ API, Đăng xuất; API doanh thu và biểu giá trả `403` | Drawer ẩn 8 mục (Tổng quan + 7 mục chủ trọ); `GET /bao-cao/doanh-thu` → `403`; `PATCH /bieu-gia/1` → `403` với thông báo “Không có quyền thực hiện chức năng này” | ✅ |
| **TC-A04** | Validate form tạo khu trọ / phòng | 1. Mở Khu trọ → Thêm<br>2. Bỏ trống tên, nhập giá điện âm<br>3. Bấm Lưu<br>4. Làm tương tự form Phòng với diện tích 0 | Tên rỗng, giá điện `-1`, diện tích `0` | Không gọi API; `setError` đúng ô “Nhập tên khu trọ”, “Giá điện không hợp lệ”, “Diện tích phải lớn hơn 0” | Mã nguồn chặn trước khi gọi API và `setError` đúng `TextInputLayout`; build release không lỗi **[cần ảnh máy thật]** | ✅ |
| **TC-A05** | Ghi chỉ số cuối nhỏ hơn đầu | 1. Mở Ghi chỉ số<br>2. Chọn một phòng, tháng mới<br>3. Nhập điện đầu `900`, điện cuối `100`<br>4. Lưu | `thang=2099-01`, `dien_dau=900`, `dien_cuoi=100` | Backend trả `400`; app báo lỗi đúng ô, không ghi dữ liệu | API trả `400` `{"loi":"Chỉ số điện cuối (100) không được nhỏ hơn chỉ số đầu (900)","chi_tiet":{"truong":"dien_cuoi","dien_dau":900,"dien_cuoi":100}}`; app dùng `chi_tiet.truong` để `setError` ô điện | ✅ |
| **TC-A06** | Phát hành hóa đơn tháng | 1. Mở Hóa đơn<br>2. Chọn khu 1, tháng `2026-10`<br>3. Bấm Phát hành<br>4. Thử lại lần 2 cùng tháng<br>5. Thử tháng `2026-13` | `thang=2026-10&khuTro=1`; sau đó `thang=2026-13` | Lần 1 tạo hóa đơn cho phòng đủ chỉ số, bỏ qua phòng đã có; lần 2 không tạo trùng; tháng sai định dạng bị chặn | Lần 1 (dữ liệu đã có hóa đơn): `201`, `so_hoa_don_da_tao=0`, `bo_qua` liệt kê từng phòng “Đã có hóa đơn tháng này”; tháng `2026-13` → `400` “Thiếu hoặc sai tham số thang (YYYY-MM)”; nút bị khóa khi đang gọi | ✅ |
| **TC-A07** | Xác nhận thanh toán + xem biên lai | 1. Mở Thanh toán<br>2. Chọn giao dịch chờ<br>3. Bấm Xem biên lai<br>4. Bấm Xác nhận đã thu → Đồng ý<br>5. Thử xác nhận giao dịch không tồn tại | Giao dịch chờ có `anh_bien_lai`; id `999999` | Ảnh biên lai mở được; sau xác nhận badge đổi “Đã xác nhận”, số đã thu tăng; id sai trả `404` | API `PATCH /thanh-toan/999999/xac-nhan` → `404` “Không tìm thấy giao dịch thanh toán”; ảnh được tải bằng Glide, bấm mở dialog lớn; nút xác nhận chỉ hiện với `CHU_TRO` **[cần ảnh máy thật cho luồng thành công]** | ✅ |
| **TC-A08** | Mất mạng + xoay màn hình | 1. Vào Hóa đơn, chọn khu/tháng<br>2. Xoay ngang rồi xoay dọc<br>3. Tắt Wi-Fi, kéo xuống tải lại<br>4. Bật Wi-Fi, bấm Thử lại | Khu 1, tháng `2026-10`; không có mạng | Bộ lọc giữ nguyên sau xoay; mất mạng hiện trạng thái lỗi + nút Thử lại, app không văng; có mạng tải lại bình thường | Bộ lọc giữ nguyên nhờ `configChanges` (Activity không bị tạo lại khi xoay) và `onSaveInstanceState` dự phòng; `ApiCallback` bắt `UnknownHostException`/`SocketTimeoutException` và hiện thông báo thân thiện; trạng thái lỗi có nút Thử lại **[cần ảnh máy thật: màn hình máy bay + xoay ngang]** | ✅ |

## Cách chụp ảnh minh chứng

| Ca | Ảnh cần chụp |
|---|---|
| TC-A01 | Màn Tổng quan sau đăng nhập + ảnh mở lại app vẫn ở Tổng quan |
| TC-A02 | Màn đăng nhập có dòng lỗi đỏ |
| TC-A03 | Drawer của `quanly` (chỉ 4 mục) + ảnh Postman trả `403` |
| TC-A04 | Form có 2 ô báo đỏ |
| TC-A05 | Dialog ghi chỉ số có ô điện báo đỏ + response Postman `400` |
| TC-A06 | Dialog kết quả phát hành (đã tạo / bỏ qua / thiếu chỉ số) |
| TC-A07 | Danh sách thanh toán trước và sau xác nhận + dialog ảnh biên lai |
| TC-A08 | Màn hình lỗi mạng có nút Thử lại + ảnh xoay ngang còn bộ lọc |

## Ghi chú kiểm thử

- Các mã `401`, `403`, `400`, `404`, `409` đều được kiểm tra trực tiếp bằng `curl`/Postman trên API Render, không chỉ qua app.
- Riêng luồng phát hành hóa đơn tạo mới: dùng tháng chưa có hóa đơn và khu có đủ chỉ số; nếu dùng tháng đã phát hành, backend trả `201` với `so_hoa_don_da_tao = 0` và danh sách `bo_qua` – đây là hành vi đúng, không phải lỗi.
- Không kiểm thử trên emulator; APK release được cài trên máy Android thật theo hướng dẫn ở `docs/huong-dan-build-apk.md`.
