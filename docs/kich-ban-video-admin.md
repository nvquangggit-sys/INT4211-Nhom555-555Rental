# Kịch bản video demo – phần App Admin (Thành viên B)

> Video nhóm 5–8 phút. Phần của B chiếm khoảng **2 phút 30 giây**, nằm giữa phần Backend (A) và phần Client (C).
> Quay màn hình thật, không dựng cảnh. Chuẩn bị trước: backend đã thức, đăng nhập sẵn ở một tab, dữ liệu tháng demo đã có chỉ số.

## 0. Chuẩn bị trước khi quay

| Việc | Cách làm |
|---|---|
| Đánh thức Render | Mở `https://rental-nhom555-api.onrender.com/health` trước 3 phút |
| Tài khoản | `chutro@555rental.vn` / `123456`; `quanly@555rental.vn` / `123456` |
| Dữ liệu | Chọn khu 1, tháng trước; đảm bảo còn phòng chưa ghi chỉ số để demo |
| Cửa sổ | Ẩn thanh thông báo, bật chế độ không làm phiền, cỡ chữ lớn vừa phải |
| Dự phòng | Quay lại cảnh phát hành hóa đơn với tháng đã có hóa đơn (kết quả “đã tạo 0, bỏ qua N”) nếu lỗi mạng |

## 1. Bảng phân cảnh

| Thời gian | Cảnh | Thao tác trên màn hình | Lời thuyết minh |
|---|---|---|---|
| **1:30 – 1:45** | Đăng nhập Admin | Mở app → nhập `chutro@555rental.vn` / `123456` → Đăng nhập | “Đây là App Admin của nhóm 555, viết bằng Java + XML. Em đăng nhập bằng tài khoản chủ trọ. Token được lưu vào SharedPreferences, các request sau tự gắn Bearer token.” |
| **1:45 – 1:55** | Tổng quan | Lướt nhẹ màn Tổng quan | “Màn tổng quan lấy số liệu từ `/bao-cao/tong-quan`: 60 phòng, 45 đã thuê, 9 trống, 6 đang sửa, và số sự cố đang mở.” |
| **1:55 – 2:15** | Ghi chỉ số | Drawer → **Ghi chỉ số** → chọn khu 1, tháng trước → mở một phòng | “Em chọn khu và tháng. App tự lấy chỉ số đầu kỳ từ tháng trước và tính tiêu thụ ngay khi nhập. Nếu chỉ số cuối nhỏ hơn đầu, backend trả 400 và app báo đỏ đúng ô.” |
| **2:15 – 2:25** | Cảnh báo tăng vọt | Nhập chỉ số cao bất thường → Lưu → dialog cảnh báo | “Khi điện tăng hơn 50% so với trung bình 3 tháng, backend trả `canh_bao`; sau khi lưu app hiện hộp thoại cảnh báo để chủ trọ đối chiếu lại chỉ số. Đây là điểm nhấn nghiệp vụ của đề.” |
| **2:25 – 2:45** | Phát hành hóa đơn | Drawer → **Hóa đơn** → chọn khu 1, tháng → **Phát hành hóa đơn** → xác nhận → dialog kết quả | “Phát hành hóa đơn cho cả khu trong một lần gọi. Backend mở transaction, tính tiền phòng, điện, nước, rác, gửi xe, bỏ qua phòng đã có hóa đơn và báo phòng thiếu chỉ số. Nút bị khóa khi đang gọi để tránh bấm hai lần.” |
| **2:45 – 3:00** | Chi tiết hóa đơn | Bấm một hóa đơn → cuộn các khoản → chỉ số → lịch sử thanh toán | “Mỗi hóa đơn hiển thị từng khoản, chỉ số đầu – cuối và lịch sử thanh toán. App không tự tính tiền; mọi con số do backend trả về.” |
| **3:00 – 3:20** | Xác nhận thanh toán | Drawer → **Thanh toán** → chọn giao dịch chờ → **Xem biên lai** → đóng → **Xác nhận đã thu** → Đồng ý | “Khi người thuê gửi biên lai, chủ trọ xem ảnh rồi xác nhận. Backend cộng số đã thu và cập nhật trạng thái hóa đơn trong transaction.” |
| **3:20 – 3:35** | Sự cố | Drawer → **Sự cố** → bấm một sự cố → xem ảnh → **Nhận xử lý** → **Đã xử lý** | “Sự cố đi theo quy trình Mới → Đang xử lý → Đã xử lý. Quản lý khu trọ cũng dùng được màn này.” |
| **3:35 – 3:55** | Báo cáo | Drawer → **Báo cáo** → chỉ biểu đồ cột, biểu đồ tròn, công nợ, bất thường | “Báo cáo có biểu đồ cột doanh thu 6 tháng, biểu đồ tròn tỷ lệ lấp đầy, bảng công nợ quá 10 ngày và danh sách phòng tiêu thụ bất thường. Dữ liệu lấy từ các API `/bao-cao/*`.” |
| **3:55 – 4:10** | Phân quyền | Đăng xuất → đăng nhập `quanly@555rental.vn` → mở drawer | “Với tài khoản quản lý, drawer chỉ còn nhóm nghiệp vụ Ghi chỉ số và Sự cố (cùng Địa chỉ API, Đăng xuất). App ẩn menu, còn backend vẫn chặn thật: gọi doanh thu hay sửa biểu giá đều trả 403.” |
| **4:10 – 4:20** | Kết thúc phần B | Quay lại màn Ghi chỉ số | “Phần Admin đến đây. Tiếp theo bạn C sẽ demo App Client.” |

## 2. Lời thoại đầy đủ (dùng để thu âm)

> “Đây là App Admin của nhóm 555, viết bằng Java và XML, `minSdk 24`. Em đăng nhập bằng tài khoản chủ trọ. Token được lưu vào SharedPreferences; mọi request sau đó được Retrofit gắn thêm `Authorization: Bearer`. Nếu token hết hạn, API trả 401, app tự xóa phiên và quay về màn đăng nhập.
>
> Màn tổng quan lấy số liệu từ `/bao-cao/tong-quan`: hiện có 60 phòng, 45 đã thuê, 9 trống, 6 đang sửa và các sự cố đang mở.
>
> Sang phần ghi chỉ số. Em chọn khu và tháng. App tự lấy chỉ số đầu kỳ từ tháng trước và tính tiêu thụ ngay khi nhập. Nếu chỉ số cuối nhỏ hơn chỉ số đầu, backend trả 400 và app báo đỏ đúng ô. Khi điện tăng hơn 50% so với trung bình 3 tháng, backend trả cảnh báo; sau khi lưu app hiện hộp thoại cảnh báo để chủ trọ đối chiếu lại chỉ số. Đây là điểm nhấn nghiệp vụ của đề.
>
> Tiếp theo là phát hành hóa đơn. Em chọn khu và tháng rồi bấm Phát hành. Chỉ một lần gọi, backend mở transaction, tính tiền phòng, điện, nước, rác, gửi xe cho từng hợp đồng, bỏ qua phòng đã có hóa đơn và trả về danh sách phòng thiếu chỉ số. Nút bị khóa trong lúc gọi để tránh bấm hai lần.
>
> Mỗi hóa đơn có màn chi tiết: từng khoản, chỉ số đầu – cuối, lịch sử thanh toán. App không tự tính tiền; mọi con số do backend trả về.
>
> Ở màn Thanh toán, em xem ảnh biên lai người thuê gửi rồi bấm xác nhận. Backend cộng số đã thu và cập nhật trạng thái hóa đơn trong transaction.
>
> Màn Sự cố cho phép xem ảnh và chuyển trạng thái Mới → Đang xử lý → Đã xử lý.
>
> Màn Báo cáo có biểu đồ cột doanh thu 6 tháng, biểu đồ tròn tỷ lệ lấp đầy, bảng công nợ quá 10 ngày và danh sách phòng tiêu thụ bất thường.
>
> Cuối cùng, em đăng nhập bằng tài khoản quản lý. Drawer chỉ còn nhóm nghiệp vụ Ghi chỉ số và Sự cố (cùng Địa chỉ API, Đăng xuất). App ẩn menu, còn backend vẫn chặn thật: gọi doanh thu hoặc sửa biểu giá đều trả 403. Phần Admin đến đây, tiếp theo là phần App Client.”

## 3. Mẹo quay

- Quay theo thứ tự trên một lần nếu có thể; nếu phải cắt, cắt ở chỗ chuyển màn hình.
- Dùng điện thoại thật quay màn hình bằng **Screen Recorder** có micro; hoặc cài APK lên máy và quay bằng camera (không khuyến khích vì rung).
- Quay ngang; tắt xoay tự động để cảnh không bị xoay giữa chừng.
- Tốc độ thao tác chậm vừa phải; dừng 1–2 giây ở mỗi kết quả quan trọng (dialog phát hành, biểu đồ).
- Chuẩn bị cảnh dự phòng: nếu Render ngủ, quay cảnh “đang tải” rồi tua; hoặc quay trước khi họp nhóm.

## 4. Câu chuyển sang phần C

> “Sau khi chủ trọ phát hành hóa đơn, bạn C sẽ mở App Client để xem hóa đơn vừa tạo, gửi biên lai và báo sự cố. Mời C demo.”
