# Kịch bản video demo – App Client (555Rental Khách)

> Thời lượng mục tiêu: **5–6 phút**. Quay dọc, 1080×1920, bật tiếng Việt.
> Thiết bị: điện thoại Android đã cài `555Rental-Khach-v1.0.0.apk`.
> Trước khi quay: gọi `https://rental-nhom555-api.onrender.com/health` để đánh thức Render (đợi tới khi `{"ok":true,"db":"ok"}`), tắt thông báo/Zalo, bật chế độ máy bay **sau** khi quay xong phần chính.

## Chuẩn bị dữ liệu (không quay)

| Mục | Giá trị |
|---|---|
| Tài khoản | `nguoithue01@555rental.vn` / `123456` |
| Phòng để đặt lịch | Phòng **117** – Khu trọ 555 Bình Thạnh – 3.700.000 đ/tháng |
| Hóa đơn để thanh toán | Hóa đơn tháng **10/2026**, còn nợ **1.904.800 đ** |
| Ảnh biên lai | Một ảnh chụp màn hình chuyển khoản bất kỳ trong thư viện (đặt tên `bien-lai.png`) |
| Ảnh sự cố | Một ảnh ổ điện/ống nước trong thư viện |

> Lưu ý: hóa đơn id 1 đang có giao dịch chờ xác nhận. Nếu muốn quay cảnh gửi biên lai thành công, nhờ chủ trọ mở App Admin xác nhận giao dịch cũ trước, hoặc quay cảnh app hiện đúng thông báo `409` “Hóa đơn đang có giao dịch chờ chủ trọ xác nhận” – vẫn chứng minh được chống gửi trùng.

---

## Phân cảnh

### Cảnh 1 – Giới thiệu (0:00 – 0:25)

**Hình ảnh:** Màn hình chờ điện thoại → mở app 555Rental Khách → màn đăng nhập.

**Lời thoại:**

> “Xin chào thầy/cô và các bạn. Em là Nguyễn Phạm Chí Thành, thành viên phụ trách **App Client** của Nhóm 555, đề 12 – Hệ thống quản lý nhà trọ.
> Đây là app **555Rental Khách** viết bằng Flutter, dành cho người thuê. App dùng chung backend Node.js + PostgreSQL với App Admin, nên dữ liệu chủ trọ nhập sẽ hiện ngay bên này.”

**Thao tác:** Chỉ vào logo, dòng “Tài khoản thử”, nút địa chỉ API ở góc phải.

### Cảnh 2 – Đăng nhập và kiểm tra lỗi (0:25 – 0:55)

**Hình ảnh:** Nhập sai mật khẩu trước, sau đó đăng nhập đúng.

**Lời thoại:**

> “Form đăng nhập có kiểm tra định dạng email và mật khẩu từ 6 ký tự. Nếu sai mật khẩu, app hiện đúng thông điệp từ backend và giữ nguyên dữ liệu, không bị đẩy ra ngoài.
> Em bấm vào gợi ý tài khoản thử để điền nhanh, rồi đăng nhập.”

**Thao tác:**
1. Bấm Đăng nhập khi để trống → chỉ 2 dòng đỏ.
2. Nhập email đúng + `sai123` → bấm Đăng nhập → khối đỏ “Email hoặc mật khẩu không đúng.”
3. Bấm khối “Tài khoản thử” → Đăng nhập → vào Trang chủ.

### Cảnh 3 – Trang chủ và nhắc hạn (0:55 – 1:20)

**Hình ảnh:** Trang chủ có banner đỏ/cam.

**Lời thoại:**

> “Trang chủ tổng hợp mọi việc người thuê cần biết: banner nhắc hạn lấy từ API `/nhac-han`, 4 lối tắt, hợp đồng đang thuê và hóa đơn gần nhất.
> Hóa đơn tháng 10 đã quá hạn 7 ngày nên banner chuyển màu đỏ. Chuông trên góc phải cũng hiện badge số việc.”

**Thao tác:** Kéo xuống để refresh; chỉ vào banner, thẻ hợp đồng, thẻ hóa đơn; bấm chuông → mở màn Nhắc hạn rồi quay lại.

### Cảnh 4 – Tìm phòng, lọc, xem chi tiết (1:20 – 2:05)

**Hình ảnh:** Tab Tìm phòng.

**Lời thoại:**

> “Tab Tìm phòng gọi API công khai `GET /phong`, chỉ lấy phòng còn trống. Em có thể lọc theo khu vực, khoảng giá và diện tích.
> Danh sách dùng `ListView.builder`, có đủ ba trạng thái: đang tải, lỗi có nút Thử lại, và rỗng có nút Xóa bộ lọc.”

**Thao tác:**
1. Nhập `Bình Thạnh` → Lọc → có 3 phòng.
2. Mở bộ lọc → nhập giá đến `3000000` → Lọc → màn “Không tìm thấy phòng phù hợp” → bấm Xóa bộ lọc.
3. Chạm phòng **117** → chi tiết: ảnh lớn, giá 3.7 triệu, diện tích 15 m², tiện ích, bảng giá điện 3.800 đ/kWh, nước 18.000 đ/m³, tên và SĐT chủ trọ.

### Cảnh 5 – Đặt lịch xem phòng (2:05 – 2:40)

**Hình ảnh:** Màn Đặt lịch xem phòng.

**Lời thoại:**

> “Bấm Đặt lịch xem phòng, app mở DatePicker và TimePicker tiếng Việt. Em chọn ngày mai lúc 9 giờ, thêm ghi chú.
> App chặn thời gian trong quá khứ, khóa nút khi đang gửi, và trả kết quả về màn trước bằng `Navigator.pop(true)` để danh sách tự tải lại.”

**Thao tác:** Chọn ngày/giờ → nhập ghi chú “Muốn xem phòng buổi sáng” → Gửi yêu cầu → SnackBar thành công → quay về danh sách.

### Cảnh 6 – Hủy lịch và Hoàn tác (2:40 – 3:10)

**Hình ảnh:** Tài khoản → Lịch xem phòng (hoặc Drawer → Lịch xem phòng).

**Lời thoại:**

> “Lịch vừa đặt hiện ở mục Lịch xem phòng với trạng thái Chờ xác nhận. Em thử hủy: app hỏi lại bằng hộp thoại, gọi `DELETE /lich-xem-phong/:id`.
> Sau khi hủy, SnackBar có nút **Hoàn tác** trong 6 giây. Bấm Hoàn tác, app tạo lại đúng lịch cũ bằng `POST /lich-xem-phong`.”

**Thao tác:** Hủy lịch → xác nhận → SnackBar → bấm Hoàn tác → danh sách có lại lịch.

### Cảnh 7 – Hợp đồng và cảnh báo hết hạn (3:10 – 3:30)

**Hình ảnh:** Màn Hợp đồng thuê của tôi.

**Lời thoại:**

> “Màn hợp đồng hiển thị thời hạn bằng thanh tiến trình. Khi còn từ 30 ngày trở xuống, thanh chuyển màu cam và hiện khối cảnh báo kèm số điện thoại chủ trọ để gia hạn. Quá hạn thì chuyển đỏ.”

**Thao tác:** Chỉ vào thanh tiến trình, ngày bắt đầu/kết thúc, tiền cọc, SĐT chủ trọ.

### Cảnh 8 – Hóa đơn, chi tiết, thanh toán (3:30 – 4:35)

**Hình ảnh:** Tab Hóa đơn → chi tiết → màn thanh toán.

**Lời thoại:**

> “Tab Hóa đơn hiện tổng còn nợ và lọc theo Còn nợ / Đã đủ.
> Mở hóa đơn tháng 10: app hiện từng khoản — tiền phòng, điện, nước, rác, gửi xe; chỉ số điện đầu 1637, cuối 1919, tiêu thụ 282 kWh; nước 174 đến 180, tiêu thụ 6 m³; và lịch sử thanh toán của hóa đơn.
> Bấm Gửi xác nhận thanh toán, em chọn ảnh biên lai từ thư viện. App gửi `multipart/form-data` tới `/thanh-toan`, backend đẩy ảnh lên Supabase Storage rồi trả URL.
> Trong lúc gửi, nút bị khóa để không gửi trùng; backend cũng chặn bằng lỗi 409 nếu hóa đơn còn giao dịch chờ.”

**Thao tác:**
1. Mở tab Hóa đơn → chỉ tổng nợ 1.904.800 đ.
2. Mở hóa đơn → cuộn qua các khoản, chỉ số, lịch sử.
3. Bấm Gửi xác nhận → nhập số tiền (mặc định còn nợ) → chọn ảnh biên lai → gửi.
4. Nếu API trả 409: đọc to thông điệp “Hóa đơn đang có giao dịch chờ chủ trọ xác nhận” và nói “đây là chống gửi trùng”.
5. Mở Lịch sử thanh toán → chỉ giao dịch 100.000 đ đang chờ, chạm ảnh biên lai để xem lớn.

### Cảnh 9 – Báo sự cố và theo dõi (4:35 – 5:10)

**Hình ảnh:** Tab Sự cố → form → timeline.

**Lời thoại:**

> “Tab Sự cố thống kê số báo cáo và hiển thị tiến trình 3 bước: Đã gửi, Đang xử lý, Hoàn tất.
> Form báo sự cố chỉ cho chọn phòng đang có hợp đồng hiệu lực; có thể đính kèm ảnh hiện trạng. Có ảnh thì gửi multipart, không ảnh thì gửi JSON, cùng một endpoint `/bao-su-co`.”

**Thao tác:** Bấm FAB Báo sự cố → chọn phòng 101, loại “Hỏng điện”, mô tả, chọn ảnh → Gửi → dialog thành công → timeline báo cáo mới.

### Cảnh 10 – Xử lý lỗi, tài khoản, kết thúc (5:10 – 5:45)

**Hình ảnh:** Tắt Wi-Fi → màn lỗi mạng; sau đó Tài khoản → Đăng xuất.

**Lời thoại:**

> “App đặt timeout 90 giây vì Render Free ngủ sau 15 phút, và bắt lỗi mất mạng bằng thông báo thân thiện kèm nút Thử lại.
> Mọi request 401 đều xóa phiên và đưa về đăng nhập. Em cũng có màn Tài khoản để xem hồ sơ, đổi địa chỉ API khi demo backend local, và đăng xuất có xác nhận.
> Phần Client gồm 18 màn hình, `flutter analyze` không có cảnh báo, `flutter test` pass 21 test, APK release đã ký và cài trên máy thật. Cảm ơn thầy/cô và các bạn đã theo dõi."

**Thao tác:** Tắt Wi-Fi → kéo xuống ở Trang chủ → màn lỗi → bật Wi-Fi → Thử lại. Mở Tài khoản → Đăng xuất → xác nhận.

---

## Checklist sau khi quay

- [ ] Video có hình màn hình điện thoại rõ nét, không lộ thông tin cá nhân khác.
- [ ] Có tiếng nói, không quá ồn; hoặc chèn phụ đề theo lời thoại.
- [ ] Mỗi cảnh có thao tác thật, không cắt ghép quá nhiều.
- [ ] Có ít nhất một cảnh chứng minh **lỗi** (sai mật khẩu, mất mạng, 409) và cách app xử lý.
- [ ] Xuất file `docs/minh-chung/video-client.mp4` (hoặc link Drive) và ghi vào README.
