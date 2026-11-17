# Câu hỏi bảo vệ – App Client (Flutter)

> 8 câu hỏi thường gặp cho phần của thành viên C. Câu trả lời bám sát mã nguồn `client-flutter/` và `backend/src/routes/khach.js`.

---

## Câu 1. Vì sao chọn Flutter cho App Client? So với App Admin (Java + XML) có gì khác?

**Trả lời:**

- Flutter dùng một mã nguồn Dart cho Android/iOS, UI khai báo theo widget nên viết nhanh, đồng bộ giao diện; phù hợp phần Client nhiều màn hình hiển thị dữ liệu.
- App Admin cần truy cập phần cứng, dùng RecyclerView/Adapter truyền thống và Retrofit; nhóm muốn thử cả hai hướng công nghệ để so sánh.
- Điểm chung: cả hai app gọi **cùng một REST API**, dùng JWT, nên không phụ thuộc nền tảng. Nếu đổi app Admin sang Flutter cũng không phải sửa backend.

---

## Câu 2. App quản lý trạng thái thế nào? Vì sao không dùng Provider/Bloc?

**Trả lời:**

- Phạm vi Client chủ yếu là **đọc dữ liệu và gửi form**, ít trạng thái chia sẻ giữa các màn hình, nên dùng `StatefulWidget` + `FutureBuilder` là đủ và dễ đọc.
- Mỗi màn hình giữ `Future` trong `State`, tạo trong `initState` hoặc khi bấm Lọc/Tải lại. `FutureBuilder` tự hiển thị 3 trạng thái: waiting / error / data.
- Trạng thái toàn cục duy nhất là **phiên đăng nhập**, đặt trong singleton `ApiService` (token, họ tên, email, vai trò) và lưu bằng `shared_preferences`.
- `HomeShell` dùng `IndexedStack` để giữ trạng thái 5 tab khi chuyển qua lại, tránh gọi lại API.
- Nếu mở rộng (chat, thông báo realtime), có thể thêm Provider/Riverpod; hiện tại không cần để tránh phức tạp.

---

## Câu 3. Token được lưu và bảo vệ như thế nào? Xử lý 401 ra sao?

**Trả lời:**

- Sau đăng nhập, app lưu `token`, `id`, `hoTen`, `email`, `vaiTro` vào `shared_preferences`. **Không lưu mật khẩu.**
- Mỗi request cần đăng nhập có header `Authorization: Bearer <token>` do `ApiService._headers()` gắn tự động.
- `ApiService._xuLy()`: nếu status `401` **và đang có token** thì ném `PhienHetHanException`; `_goi()` bắt exception này, gọi `dangXuat()` (xóa token) và `khiHetPhien` → `main.dart` dùng `GlobalKey<NavigatorState>` đẩy về `LoginScreen(daHetPhien: true)`, xóa stack cũ.
- Điều kiện “đang có token” rất quan trọng: khi người dùng đăng nhập sai, backend trả 401 nhưng không có token → app hiện thông điệp “Email hoặc mật khẩu không đúng” thay vì nhảy màn hình.
- Hạn token 7 ngày (`JWT_EXPIRES_IN`), hết hạn thì quy trình trên tự đưa về đăng nhập.

---

## Câu 4. Vì sao timeout 90 giây? Làm sao app không bị “treo” khi mạng chậm?

**Trả lời:**

- Backend deploy trên **Render Free**, gói này ngủ sau 15 phút không có request. Lần gọi đầu phải chờ Render khởi động, có thể 30–60 giây. Đặt timeout 90 giây để không báo lỗi oan.
- Mọi hàm `get/post/postMultipart/delete` đều `.timeout(ApiService.thoiGianCho)`.
- `_goi()` bắt riêng `TimeoutException`, `SocketException`, `http.ClientException` và đổi thành `ApiException` với thông điệp tiếng Việt thân thiện.
- UI luôn có trạng thái đang tải (vòng xoay + khóa nút) và trạng thái lỗi có nút **Thử lại**, nên người dùng biết app đang chờ chứ không tưởng bị treo.

---

## Câu 5. Vì sao phải `utf8.decode(res.bodyBytes)` thay vì `res.body`?

**Trả lời:**

- package `http` suy ra charset từ header `Content-Type`. Nếu server không ghi `charset=utf-8`, `res.body` có thể giải mã theo Latin-1 → tiếng Việt thành “Nguy?n V?n Ch?”.
- `res.bodyBytes` là byte gốc; `utf8.decode(...)` luôn cho đúng UTF-8. Đây là lỗi rất hay gặp khi làm app tiếng Việt.
- Tương tự, khi gửi JSON, app đặt `Content-Type: application/json; charset=utf-8` và dùng `jsonEncode` (Dart luôn xuất UTF-8).

---

## Câu 6. Gửi ảnh biên lai/ảnh sự cố như thế nào? Làm sao chống gửi trùng?

**Trả lời:**

- Dùng `image_picker` chọn ảnh từ thư viện, giới hạn `maxWidth` và `imageQuality` để giảm dung lượng.
- `ApiService.postMultipart()` tạo `http.MultipartRequest`, thêm các field text (`hoa_don_id`, `so_tien`, `hinh_thuc`) và file ở field `anh` bằng `MultipartFile.fromPath`.
- Backend dùng `multer` memoryStorage, giới hạn 5 MB, chỉ nhận `image/*`; sau đó đẩy lên **Supabase Storage** (thư mục `bien-lai/` hoặc `su-co/`) và lưu URL public vào PostgreSQL.
- Chống gửi trùng 2 lớp:
  1. **Client**: cờ `_dangGui` khóa nút và toàn bộ input khi request đang chạy.
  2. **Server**: mỗi hóa đơn chỉ nhận một giao dịch `xac_nhan_boi IS NULL`; gửi thêm trả `409` “Hóa đơn đang có giao dịch chờ chủ trọ xác nhận”.
- Sau khi gửi, hóa đơn **không** cộng `da_thu` ngay; chủ trọ kiểm tra biên lai rồi xác nhận bên App Admin. Đây là lý do trạng thái có “Chờ xác nhận” và “Đã xác nhận”.

---

## Câu 7. Cảnh báo hợp đồng sắp hết hạn tính thế nào? Vì sao dùng `so_ngay_con_lai` từ backend?

**Trả lời:**

- Backend tính `(h.ket_thuc::date - CURRENT_DATE)::int AS so_ngay_con_lai` để tránh lệch múi giờ và tránh mỗi client tính một kiểu.
- Client dùng giá trị này; nếu thiếu (0) thì fallback `DinhDang.soNgayConLai(ketThuc)` – tính theo ngày, bỏ phần giờ.
- Quy ước: `> 30` bình thường; `0..30` sắp hết hạn → thanh tiến trình và khối cảnh báo màu cam kèm SĐT chủ trọ; `< 0` đã hết hạn → màu đỏ.
- API `/nhac-han` cũng lọc hợp đồng `HIEU_LUC` có `ket_thuc <= CURRENT_DATE + 30` nên app không phải tải tất cả rồi tự lọc.

---

## Câu 8. Thiết kế API phía khách thế nào? Vì sao dùng 400/401/403/404/409?

**Trả lời:**

- Các route nằm trong `backend/src/routes/khach.js`, đều có tiền tố nghiệp vụ và hậu tố `/cua-toi` cho dữ liệu cá nhân: `/lich-xem-phong/cua-toi`, `/hop-dong/cua-toi`, `/hoa-don/cua-toi`, `/thanh-toan/cua-toi`, `/bao-su-co/cua-toi`, `/nhac-han`.
- Phân quyền: middleware `xacThuc` kiểm tra JWT, `chiVaiTro('NGUOI_THUE')` chặn vai trò khác. Chủ trọ gọi endpoint khách → `403`.
- Mã lỗi:
  - `400` dữ liệu sai (thiếu `phong_id`, thời gian quá khứ, số tiền ≤ 0, tham số lọc âm).
  - `401` thiếu/sai/hết hạn token.
  - `403` đúng người đăng nhập nhưng không có quyền (báo sự cố phòng không thuê).
  - `404` không tìm thấy tài nguyên hoặc không thuộc về người dùng (tránh lộ dữ liệu người khác).
  - `409` xung đột trạng thái: phòng đã thuê, hóa đơn còn giao dịch chờ.
- Body lỗi thống nhất `{"loi": "..."}` để app hiển thị trực tiếp; body thành công trả đúng thực thể vừa tạo (201) hoặc danh sách (200).
- Các endpoint `/phong` và `/phong/:id` để **công khai** vì khách chưa đăng nhập vẫn cần tìm phòng; các endpoint còn lại đều yêu cầu token.

---

## Câu 9 (dự phòng). Nếu bị hỏi “phần nào em tự làm, phần nào dùng công cụ/AI hỗ trợ?”

**Trả lời:**

- Em phụ trách toàn bộ `client-flutter/`, `backend/src/routes/khach.js`, các tài liệu mục 1/5/7 phần Client, kịch bản video, Q&A và APK.
- Em dùng AI như trợ lý soạn khung và rà lỗi chính tả, nhưng đã **đọc, chạy thật và sửa** từng phần: `flutter analyze`, `flutter test`, gọi API bằng `curl`, build APK và cài trên máy.
- Các quyết định thiết kế (timeout 90 giây, 401 chỉ khi có token, chống gửi trùng 2 lớp, `IndexedStack`, `AnhMang` có errorBuilder) đều xuất phát từ lỗi thực tế gặp khi chạy demo, không phải copy nguyên mẫu.

---

## Câu 10 (dự phòng). Nếu Render ngủ hoặc Supabase lỗi thì demo thế nào?

**Trả lời:**

1. Trước giờ bảo vệ 3–5 phút, gọi `https://rental-nhom555-api.onrender.com/health` bằng trình duyệt để đánh thức; đợi tới `{"ok":true,"db":"ok"}`.
2. Trong app, màn **Địa chỉ API** cho phép đổi sang backend local:
   - Emulator: `http://10.0.2.2:3000`
   - Máy thật + cáp USB: `adb reverse tcp:3000 tcp:3000` rồi `http://localhost:3000`
3. Nếu mất mạng, app hiện trạng thái lỗi + nút Thử lại; đây là hành vi đã được kiểm thử (TC-C10), có thể dùng làm minh chứng thay vì cố che lỗi.
