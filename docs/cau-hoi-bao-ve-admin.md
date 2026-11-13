# 6 câu giảng viên có thể hỏi – App Admin (Thành viên B)

> Mỗi câu gồm: câu hỏi, câu trả lời mẫu (nói 30–60 giây), và ý chính cần nhớ.
> Khi bảo vệ, giảng viên có thể chỉ vào đúng đoạn mã trong repo; nên mở sẵn các file được nhắc.

## Câu 1. Vì sao app không tự tính tiền? Tiền được tính ở đâu?

**Trả lời mẫu:**

“Mọi quyết định nghiệp vụ nằm ở backend, app chỉ hiển thị và gửi yêu cầu. Tiền được tính trong `POST /hoa-don/phat-hanh`: backend lấy biểu giá của khu, lấy chỉ số đầu – cuối, tính `(dien_cuoi − dien_dau) × gia_dien`, nước tương tự, rồi cộng tiền phòng, rác, gửi xe. App nhận `tong_tien`, `chi_tiet`, `con_no` từ JSON và hiển thị. Nếu app tự tính, hai app Admin và Client có thể ra hai con số khác nhau, và sửa biểu giá sẽ phải sửa ở nhiều nơi. Đặt ở backend còn để chặn chỉ số sai và đảm bảo transaction khi phát hành hàng loạt.”

**Ý chính:** một nguồn sự thật duy nhất; tránh lệch số giữa 2 app; backend kiểm tra quyền và dữ liệu.

**Có thể bị hỏi tiếp:** “Nếu mạng lỗi giữa chừng thì sao?” → Backend dùng transaction, lỗi thì `ROLLBACK`, không có hóa đơn rác. App chỉ hiện lỗi và cho thử lại.

---

## Câu 2. Token được lưu và gắn vào request như thế nào? Tự đăng xuất khi 401 ra sao?

**Trả lời mẫu:**

“Sau khi đăng nhập thành công, `TokenStore` lưu token, id, họ tên, email và vai trò vào SharedPreferences. Không lưu mật khẩu. Trong `ApiClient`, em thêm một interceptor OkHttp: mỗi request đọc token từ `TokenStore`, nếu có thì thêm header `Authorization: Bearer <token>`. Ở tầng callback, `ApiCallback.onResponse` kiểm tra nếu `response.code() == 401` thì gọi `PhienDangNhap.hetHan()`: xóa toàn bộ SharedPreferences, hiện Toast ‘Phiên đăng nhập đã hết hạn’ và mở `LoginActivity` với cờ `CLEAR_TASK`. Nhờ vậy mọi màn hình đều tự đăng xuất, không phải viết lại ở từng màn.”

**Ý chính:** `TokenStore` (SharedPreferences) → interceptor gắn Bearer → `ApiCallback` bắt 401 → `PhienDangNhap` xóa phiên + về Login.

**Có thể bị hỏi tiếp:** “Vì sao không lưu token trong biến static?” → Mất khi tiến trình bị hệ thống thu hồi; SharedPreferences bền hơn. Token vẫn có thể bị đọc nếu máy root; với đồ án dùng SharedPreferences là đủ, production nên dùng EncryptedSharedPreferences.

---

## Câu 3. Phân quyền đã làm ở đâu? Chỉ ẩn menu có đủ không?

**Trả lời mẫu:**

“Không, ẩn menu chỉ là lớp giao diện. Quyền thật do backend kiểm tra: middleware `xacThuc` xác thực JWT, `choPhep('CHU_TRO')` chặn theo vai trò. Ví dụ tài khoản `QUAN_LY` gọi `GET /bao-cao/doanh-thu` hoặc `PATCH /bieu-gia/:id` đều nhận `403`. Ở app, `MainActivity.apDungPhanQuyen()` ẩn 8 mục (Tổng quan + 7 mục chỉ dành cho chủ trọ), và `chonMuc()` chặn nếu người dùng cố mở lại mục đó. Em đã kiểm tra bằng Postman: không token → 401, sai vai trò → 403.”

**Ý chính:** 2 lớp: UI ẩn + backend chặn; backend là nguồn quyết định.

**Có thể bị hỏi tiếp:** “Nếu sửa APK để hiện menu thì sao?” → Vẫn không xem được dữ liệu vì API trả 403; dữ liệu nhạy cảm không nằm trong APK.

---

## Câu 4. Vì sao timeout 90 giây? Render ngủ thì app xử lý thế nào?

**Trả lời mẫu:**

“Backend deploy trên Render gói Free, ngủ sau 15 phút không có request. Lần gọi đầu phải chờ Render khởi động, có thể 30–60 giây, nên em đặt connect/read/write timeout 90 giây trong `ApiClient`. Nếu quá thời gian, Retrofit ném `SocketTimeoutException`; `ApiCallback.onFailure` bắt riêng và hiện ‘Máy chủ đang khởi động (Render ngủ 15 phút). Vui lòng thử lại sau ít giây.’ Nếu sai địa chỉ hoặc mất mạng hoàn toàn thì bắt `UnknownHostException` và báo kiểm tra Wi-Fi/Địa chỉ API. App không bị văng vì mọi callback đều kiểm tra `conSong()` trước khi chạm View.”

**Ý chính:** 90 giây vì Render cold start; phân biệt timeout / unknown host / lỗi khác; không văng.

**Có thể bị hỏi tiếp:** “Vì sao BASE_URL phải có dấu `/` cuối?” → Retrofit ném `IllegalArgumentException: baseUrl must end in /`. App xử lý ngay trong `TokenStore.luuBaseUrl`: tự thêm `https://` nếu thiếu scheme và tự thêm `/` cuối, nên người dùng nhập tắt vẫn dùng được.

---

## Câu 5. Làm sao không mất dữ liệu khi xoay màn hình?

**Trả lời mẫu:**

“Ba Activity của app khai báo `android:configChanges="orientation|screenSize|screenLayout|keyboardHidden"`, nên khi xoay màn hình Android không hủy và tạo lại Activity: toàn bộ View, hộp thoại đang mở và nội dung đang nhập được giữ nguyên. Bên cạnh đó em vẫn lưu các bộ lọc quan trọng như email đăng nhập, mục menu đang chọn, khu/tháng/trạng thái của Hóa đơn và Ghi chỉ số vào `onSaveInstanceState`, để nếu tiến trình bị hệ thống thu hồi thì mở lại vẫn khôi phục đúng. Danh sách thì luôn tải lại từ API theo id/bộ lọc, không giữ đối tượng cũ. Cuối cùng, `ApiCallback.conSong()` kiểm tra Fragment còn gắn và Activity chưa finish trước khi cập nhật View, tránh `NullPointerException` khi callback về sau khi màn hình đã bị hủy.”

**Ý chính:** `configChanges` giữ nguyên Activity/form/dialog; `onSaveInstanceState` dự phòng khi process death; tải lại theo id + kiểm tra vòng đời.

**Có thể bị hỏi tiếp:** “Sao không dùng ViewModel?” → Với dữ liệu nhỏ, `onSaveInstanceState` đủ và ít mã hơn; nếu cần giữ danh sách lớn hoặc gọi API dài, ViewModel + LiveData sẽ tốt hơn, em ghi ở phần hướng phát triển.

---

## Câu 6. RecyclerView + Adapter + ViewHolder hoạt động thế nào? Vì sao dùng `notifyDataSetChanged()`?

**Trả lời mẫu:**

“`RecyclerView` chỉ tạo số View vừa đủ màn hình. `Adapter` biết tổng số item và tạo `ViewHolder` trong `onCreateViewHolder`; `onBindViewHolder` gán dữ liệu vào View đã tái sử dụng. `ViewHolder` giữ tham chiếu các View con để không gọi `findViewById` mỗi lần cuộn. Khi có dữ liệu mới, em xóa list cũ, thêm list mới và gọi `notifyDataSetChanged()`. Với danh sách nhỏ vài chục dòng như đồ án, cách này đơn giản và đủ nhanh. Nếu danh sách lớn hoặc cập nhật từng phần, em sẽ dùng `DiffUtil` hoặc `ListAdapter` để chỉ vẽ lại item thay đổi.”

**Ý chính:** tái sử dụng View + `ViewHolder` giữ findViewById; `notifyDataSetChanged` vẽ lại toàn bộ; `DiffUtil` là hướng tối ưu.

**Có thể bị hỏi tiếp:** “Vì sao phải có `ViewHolder`?” → Tránh `findViewById` lặp lại, giảm giật khi cuộn.

---

## Câu hỏi dự phòng (nếu giảng viên hỏi thêm)

### “Vì sao `GET /phong` lúc đầu chỉ trả 9 phòng?”

“Backend mặc định `trangThai=TRONG` nếu thiếu tham số. Màn Phòng có bộ lọc ‘Tất cả’, em phải gửi `trangThai=ALL` thì backend mới trả đủ 60 phòng. Đây là lỗi em phát hiện khi kiểm thử và đã sửa trong `PhongFragment`.”

### “Ảnh biên lai lưu ở đâu? App tải ảnh thế nào?”

“Backend lưu ảnh trên Supabase Storage và trả URL trong `anh_bien_lai`. App dùng Glide tải URL, có xử lý URL tương đối `/uploads/...` bằng cách ghép `BASE_URL`. Ảnh thumbnail 44dp, bấm vào mở dialog ảnh lớn.”

### “Nếu hai người cùng phát hành hóa đơn một tháng thì sao?”

“Ràng buộc `UNIQUE(hop_dong_id, thang)` ở CSDL và kiểm tra trước khi insert. Người thứ hai nhận danh sách `bo_qua` với lý do ‘Đã có hóa đơn tháng này’, không tạo trùng. Toàn bộ nằm trong transaction.”

### “Vì sao dùng `findViewById` mà không dùng ViewBinding?”

“Project dùng Java + XML thuần theo yêu cầu môn học; `findViewById` dễ đối chiếu khi bảo vệ và không cần bật buildFeatures. ViewBinding sẽ an toàn kiểu hơn, em ghi ở hướng phát triển.”
