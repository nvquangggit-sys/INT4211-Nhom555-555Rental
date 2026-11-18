# Minh chứng chạy thật – App Admin và App Client

Thư mục này để chứa **ảnh chụp màn hình máy thật** và **video demo** của cả hai app.
Với App Admin, đây là hai việc còn lại chưa tick trong `docs/checklist-18-muc.md` (mục 7 và 17).
Với App Client, ảnh và video là minh chứng cho 10 ca kiểm thử trong `docs/bao-cao-muc-7-kiem-thu-client.md`.

> Chỉ cần copy file vào đúng tên dưới đây, không phải sửa code. Ảnh chụp từ điện thoại
> hay bằng `adb` đều được; ưu tiên ảnh không có thanh thông báo và không lộ thông tin cá nhân.

## 1. Ảnh cần chụp (bắt buộc)

| Tên file | Chụp gì | Dùng cho |
|---|---|---|
| `01-cai-apk.jpg` | Ảnh chụp điện thoại đang mở app, thấy rõ tên **555Rental Admin**; thêm 1 ảnh phụ màn `Cài đặt → Ứng dụng` hiện `com.nhom555.rentaladmin`, phiên bản `1.0.0` | Checklist mục 7 |
| `02-dang-nhap.png` | Màn đăng nhập, đã nhập `chutro@555rental.vn` | Mục 5.4.1 |
| `03-tong-quan.png` | Tổng quan có 60 phòng / 45 đã thuê / 9 trống / 6 đang sửa | Mục 5.4.2, TC-A01 |
| `04-drawer-quan-ly.png` | Drawer của `quanly@555rental.vn`: chỉ còn Ghi chỉ số, Sự cố, Địa chỉ API, Đăng xuất | TC-A03 |
| `05-ghi-chi-so.png` | Dialog ghi chỉ số đã prefill chỉ số đầu kỳ + dòng “Tiêu thụ dự kiến” | Mục 5.4.6, TC-A04 |
| `06-loi-400-dien-cuoi.png` | Nhập điện đầu `900`, cuối `100` → ô **Điện cuối** viền đỏ, đúng thông báo backend | TC-A05 |
| `07-canh-bao-tang-vot.png` | Dialog cảnh báo sau khi lưu chỉ số tăng > 50% | Mục 5.4.6, TC-A06 |
| `08-phat-hanh-hoa-don.png` | Dialog kết quả phát hành: đã tạo / bỏ qua / phòng thiếu chỉ số | Mục 5.4.8 |
| `09-chi-tiet-hoa-don.png` | Chi tiết hóa đơn: các khoản, chỉ số đầu – cuối, lịch sử thanh toán | Mục 5.4.9 |
| `10-thanh-toan-bien-lai.png` | Màn thanh toán + dialog xem ảnh biên lai | Mục 5.4.10 |
| `11-su-co.png` | Thẻ sự cố và dialog đổi trạng thái Mới → Đang xử lý | Mục 5.4.11 |
| `12-bao-cao.png` | Báo cáo có **biểu đồ cột** + **biểu đồ tròn** + công nợ | Mục 5.4.12, TC-A07 |
| `13-mat-mang.png` | Bật chế độ máy bay, kéo xuống tải lại → trạng thái lỗi có nút “Thử lại” | TC-A02, checklist mục 10 |
| `14-xoay-ngang.png` | Đang mở dialog ghi chỉ số, xoay ngang → nội dung vẫn còn nguyên | TC-A08, checklist mục 11 |

Tối thiểu để qua mục 7 và 17: `01`, `03`, `04`, `12`, `14`.

## 2. Video

| Tên file | Nội dung | Thời lượng |
|---|---|---|
| `admin-demo.mp4` | Toàn bộ phần B theo `docs/kich-ban-video-admin.md`, có tiếng thuyết minh | 2:30 – 3:00 |

**Thời điểm:** quay **cuối cùng, sau khi thành viên C hoàn thiện app Client** – vì cảnh cuối là
câu chuyển sang phần C và cần cảnh liên thông “Admin thêm → Client thấy”. Điều kiện và dữ liệu
cần nhờ C chuẩn bị: xem `docs/kich-ban-video-admin.md` mục 0.1.

Ảnh chụp màn hình thì **chụp ngay được**, không cần chờ C.

Nếu video nhóm ghép chung: đặt tên `admin-demo-phan-b.mp4` và ghi rõ mốc thời gian
`1:30 – 4:20` trong video tổng.

## 3. Cách chụp nhanh bằng cáp USB

```powershell
# Cài APK + mở app
cd admin-android
.\tools\minh-chung.ps1 -Cai

# Chụp từng ảnh: bấm phím Enter sau khi đã mở đúng màn hình
.\tools\minh-chung.ps1 -Chup 03-tong-quan

# Quay video: Enter để bắt đầu, thao tác theo kịch bản, Enter để dừng
.\tools\minh-chung.ps1 -Quay

# Xem còn thiếu ảnh nào
.\tools\minh-chung.ps1 -KiemTra
```

Không có cáp thì dùng điện thoại: bật “Nguồn không xác định”, copy
`admin-android/releases/555Rental-Admin-v1.0.0.apk` sang máy, cài, rồi chụp bằng
nút nguồn + giảm âm lượng. Video quay bằng ứng dụng ghi màn hình có micro.

## 4. Sau khi có ảnh

1. Chèn ảnh vào báo cáo Word/PDF đúng mục 5 tương ứng (bảng trên).
2. Tick `docs/checklist-18-muc.md` mục 7, 10, 11, 17.
3. Cập nhật `docs/bao-cao-muc-8-9-phan-cong-tu-danh-gia.md`: đổi
   “Đã ký, chờ ảnh cài máy thật” → “Đã cài và chạy trên máy thật (ảnh trong `docs/minh-chung/`)”.

## 5. Lưu ý khi công khai repo

Ảnh/video có thể chứa email, số điện thoại, IMEI. Nếu repo public, che các thông tin
này trước khi commit, hoặc thêm `docs/minh-chung/*.jpg`, `*.png`, `*.mp4` vào
`.gitignore` và chỉ nộp kèm file nén riêng.

---

## 6. Ảnh và video App Client (Thành viên C)

Thiết bị: Android 7.0+ đã cài `client-flutter/releases/555Rental-Khach-v1.0.0.apk`.
Đăng nhập `nguoithue01@555rental.vn` / `123456`. Gọi `/health` trước khi quay để đánh thức Render.

### 6.1. Ảnh cần chụp (theo bảng 7.5)

| Tên file | Chụp gì | Dùng cho |
|---|---|---|
| `client-01-dang-nhap.png` | Trang chủ sau khi đăng nhập, và ảnh phụ mở lại app vẫn ở Trang chủ | TC-C01 |
| `client-02-sai-mat-khau.png` | Màn đăng nhập có dòng đỏ “Email hoặc mật khẩu không đúng.” | TC-C02 |
| `client-03-validate.png` | Form đăng nhập/đăng ký có 2 ô báo đỏ | TC-C03 |
| `client-04-tim-phong.png` | Danh sách phòng sau lọc `Bình Thạnh` + màn rỗng khi lọc dưới 3 triệu | TC-C04 |
| `client-05-chi-tiet-phong.png` | Chi tiết phòng 117 + màn đặt lịch có DatePicker/TimePicker | TC-C05 |
| `client-06-hoan-tac.png` | SnackBar “Đã hủy lịch…” có nút **Hoàn tác** + danh sách sau khi hoàn tác | TC-C06 |
| `client-07-hoa-don.png` | Chi tiết hóa đơn tháng 10: 5 khoản + chỉ số điện/nước | TC-C07 |
| `client-08-thanh-toan.png` | Màn xác nhận thanh toán đã chọn ảnh biên lai (hoặc dialog `409` chống gửi trùng) | TC-C07 |
| `client-09-hop-dong.png` | Màn hợp đồng có khối cảnh báo cam (dùng hợp đồng mẫu còn ≤ 30 ngày) | TC-C08 |
| `client-10-su-co.png` | Form báo sự cố có ảnh + timeline trạng thái | TC-C09 |
| `client-11-mat-mang.png` | Banner nhắc hạn quá hạn + màn lỗi mạng có nút **Thử lại** | TC-C10 |

Tối thiểu để chứng minh phần C: `client-01`, `client-04`, `client-06`, `client-07`, `client-10`.

### 6.2. Video

| Tên file | Nội dung | Thời lượng |
|---|---|---|
| `client-demo.mp4` | Toàn bộ phần C theo `docs/kich-ban-video-client.md`, có tiếng thuyết minh | 5:00 – 6:00 |

Quay **trước** phần Admin để cảnh chuyển tiếp và cảnh liên thông “Admin thêm → Client thấy” khớp dữ liệu.

### 6.3. Cách chụp nhanh bằng ADB

```powershell
# Cài APK Client
adb install -r client-flutter\releases\555Rental-Khach-v1.0.0.apk

# Chụp màn hình đang mở
adb exec-out screencap -p > docs\minh-chung\client-04-tim-phong.png

# Quay video thủ công bằng ứng dụng ghi màn hình của điện thoại,
# hoặc dùng scrcpy nếu đã cài.
```

Sau khi có ảnh: chèn vào báo cáo mục 5/7, tick `docs/checklist-18-muc.md` mục 8, 9, 17,
và cập nhật `docs/bao-cao-muc-8-9-phan-cong-tu-danh-gia.md` (mục 8.C.6).
