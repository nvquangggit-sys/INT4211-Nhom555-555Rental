# Mục 8 – Phân công và tiến độ (phần Thành viên B)

> Thành viên B: **Trần Phước Vinh – 231A290104**
> Vai trò: App Admin (Android, Java + XML), nhánh `admin-android/`.
> Tỷ lệ đóng góp theo bảng phân công nhóm: **32%**.

## 8.1. Phạm vi công việc được giao

| Nhóm việc | Nội dung | Sản phẩm |
|---|---|---|
| Nền tảng Android | Project Java + XML, `minSdk 24`, package/tên app/TAG log chứa `555` | `admin-android/` |
| Gọi API | Retrofit 2 + Gson, interceptor token, timeout 90 giây, `BASE_URL` https có `/` cuối | `ApiClient`, `ApiService` |
| Xác thực | Đăng nhập, lưu token, tự đăng xuất khi `401` | `LoginActivity`, `TokenStore`, `PhienDangNhap` |
| Phân quyền | `CHU_TRO` toàn quyền; `QUAN_LY` chỉ ghi chỉ số + sự cố | `MainActivity`, kiểm tra ở backend |
| Màn hình | ≥ 6 màn: đăng nhập, khu trọ, phòng, hợp đồng, chỉ số, hóa đơn, thanh toán, sự cố, báo cáo | 12 màn + 6 layout dialog dùng lại |
| Chất lượng | Form validate, dialog xác nhận xóa, 3 trạng thái, xoay màn hình, APK release | Toàn bộ app |
| Báo cáo | Mục 2, mục 5, 8 ca kiểm thử, mục 8–9, README, kịch bản video, Q&A, hướng dẫn build APK | `docs/` |

## 8.2. Tiến độ theo tuần

| Tuần | Mốc | Việc đã làm | Minh chứng |
|---|---|---|---|
| 8 | Đăng ký đề tài, tạo repo | Đọc đề 12, thống nhất API contract với A, tạo khung `admin-android/` | Commit khung project |
| 9 | Chốt phân tích, API đăng nhập | Dựng Gradle, Manifest, theme, màu, icon; viết `ApiClient` + `ApiService`; màn đăng nhập | Commit “Khoi tao project Android…” |
| 10 | Khu trọ, phòng, hợp đồng | RecyclerView + Adapter cho 3 màn; form thêm/sửa/xóa; validate; dialog xác nhận | Các commit `ui/khutro`, `ui/phong`, `ui/hopdong` |
| 11 | Mốc chạy API thật | Kết nối backend Render; sửa lỗi `GET /phong` mặc định `TRONG`; kiểm tra 401/403 | Ảnh chụp app + Postman |
| 12 | Ghi chỉ số, hợp đồng | Màn ghi chỉ số, prefill chỉ số đầu từ tháng trước, tính tiêu thụ trực tiếp | Commit `ui/chiso` |
| 13 | Hóa đơn, thanh toán | Danh sách hóa đơn, lọc nợ > 10 ngày, phát hành tháng, chi tiết hóa đơn, xác nhận thanh toán, ảnh biên lai | Commit `ui/hoadon`, `ui/thanhtoan` |
| 14 | Sự cố, báo cáo, APK | Sự cố + đổi trạng thái, lịch xem, báo cáo cột + tròn, 3 trạng thái, xoay màn hình, ký APK release | Commit `ui/suco`, `ui/baocao`, `releases/` |
| 15 | Bảo vệ | Rà 18 mục tự kiểm, quay video phần Admin, chuẩn bị Q&A | Video + APK |

## 8.3. Bảng công việc chi tiết

| STT | Công việc | Kết quả | Trạng thái |
|---|---|---|---|
| 1 | Khởi tạo project, Gradle, Manifest, theme | Build debug thành công | ✅ |
| 2 | `ApiClient` + `ApiService` + `ApiCallback` | 30+ endpoint, token interceptor, timeout 90s | ✅ |
| 3 | `TokenStore` + tự đăng xuất 401 | Lưu token/vai trò/base URL; `PhienDangNhap.hetHan()` | ✅ |
| 4 | Màn đăng nhập | Validate email/mật khẩu, 3 trạng thái, đổi API | ✅ |
| 5 | Drawer + phân quyền | 10 mục; `QUAN_LY` chỉ 2 mục nghiệp vụ | ✅ |
| 6 | Tổng quan | 6 thẻ số liệu + 3 lối tắt | ✅ |
| 7 | Khu trọ | CRUD + biểu giá + xác nhận xóa | ✅ |
| 8 | Phòng | CRUD + lọc khu/trạng thái/tìm kiếm | ✅ |
| 9 | Hợp đồng | Tạo/gia hạn/kết thúc + validate ngày | ✅ |
| 10 | Ghi chỉ số | Prefill, tính tiêu thụ, báo lỗi đúng ô, cảnh báo tăng vọt | ✅ |
| 11 | Hóa đơn | Lọc, nợ > 10 ngày, phát hành tháng, chi tiết | ✅ |
| 12 | Thanh toán | Duyệt giao dịch, ảnh biên lai, xác nhận | ✅ |
| 13 | Sự cố | Danh sách, chi tiết + ảnh, đổi trạng thái | ✅ |
| 14 | Lịch xem | Xác nhận / từ chối | ✅ |
| 15 | Báo cáo | Biểu đồ cột doanh thu + biểu đồ tròn lấp đầy + công nợ + bất thường | ✅ |
| 16 | 3 trạng thái + rỗng + thử lại | `TrangThaiManHinh` dùng cho mọi màn danh sách | ✅ |
| 17 | Xoay màn hình | `configChanges` giữ nguyên Activity/form/dialog; `onSaveInstanceState` lưu bộ lọc, email, mục menu | ✅ |
| 18 | APK release | Ký keystore, `app-release.apk` 6.1 MB | ✅ |
| 19 | Tài liệu báo cáo | Mục 2, 5, 7, 8, 9 + README + Q&A | ✅ |
| 20 | Ảnh chụp màn hình minh chứng | Cần chụp trên máy thật khi nộp | ⏳ |

## 8.4. Commit cá nhân

- Tài khoản Git: `Vinh` – `tranphuocvinh205@gmail.com`.
- Toàn bộ mã nguồn Admin nằm trong `admin-android/`; lịch sử commit chia theo từng màn hình/nghiệp vụ, không gộp một commit.
- Mục tiêu: **≥ 15 commit có ý nghĩa**, rải từ tuần 9 đến tuần 15.
- Cách lấy ảnh biểu đồ đóng góp: GitHub → repo → **Insights → Contributors** → chụp biểu đồ; hoặc `git shortlog -sne --all` để đối chiếu số commit.

`[chèn ảnh: biểu đồ đóng góp GitHub của Trần Phước Vinh]`

`[chèn ảnh: git log --oneline --author=Vinh]`

## 8.5. Khó khăn và cách xử lý

| Khó khăn | Nguyên nhân | Cách xử lý |
|---|---|---|
| Backend Render ngủ 15 phút | Gói Free | Timeout 90 giây; thông báo “máy chủ đang khởi động”; nút Thử lại |
| `GET /phong` chỉ trả phòng trống | Backend mặc định `trangThai=TRONG` | App luôn gửi `trangThai=ALL` khi chọn “Tất cả” |
| `GET /hoa-don/{id}` trả `chi_so: null` | Lỗi join của backend | App hiển thị “Chưa có chỉ số của tháng này”, không văng |
| Ảnh biên lai có URL tương đối | Môi trường local không có `PUBLIC_BASE_URL` | `Anh.duongDan()` ghép `BASE_URL` nếu URL bắt đầu bằng `/` |
| Xoay màn hình mất bộ lọc | Activity/Fragment bị tạo lại | `android:configChanges` để không tạo lại Activity; kèm `onSaveInstanceState` cho bộ lọc khi tiến trình bị thu hồi |
| Token hết hạn giữa chừng | JWT 7 ngày | `ApiCallback` bắt `401` → xóa phiên → về Login |
| Không có emulator | Máy không đủ tài nguyên | Build release + cài máy thật; kiểm thử API bằng Postman |

## 8.6. Việc còn lại trước khi nộp

- Chụp đủ ảnh màn hình theo danh sách trong mục 5.10 và mục 7.
- Quay đoạn video phần Admin theo kịch bản `docs/kich-ban-video-admin.md`.
- Cài APK release trên máy thật, kiểm tra lại 8 ca.
- Đối chiếu 18 mục tự kiểm trong `docs/checklist-18-muc.md`.

---

# Mục 9 – Tự đánh giá (phần Thành viên B)

## 9.1. Kết quả đạt được

| Tiêu chí App Admin | Kết quả | Minh chứng |
|---|---|---|
| Đăng nhập + lưu token + tự đăng xuất khi 401 | Đạt | `LoginActivity`, `TokenStore`, `ApiCallback`, `PhienDangNhap` |
| Phân quyền ≥ 2 vai trò | Đạt | `CHU_TRO` / `QUAN_LY`; backend trả `403` |
| ≥ 2 RecyclerView + Adapter + ViewHolder | Đạt (8 danh sách) | Khu trọ, phòng, hợp đồng, chỉ số, hóa đơn, thanh toán, sự cố, lịch xem |
| Fragment hoặc nhiều Activity | Đạt | 1 `MainActivity` + 10 Fragment + 2 Activity (đăng nhập, chi tiết hóa đơn) |
| Form validate đầy đủ | Đạt | `setError` ở đăng nhập, khu trọ, phòng, hợp đồng, chỉ số, hóa đơn |
| Dialog xác nhận trước khi xóa | Đạt | Xóa khu trọ, phòng; kết thúc hợp đồng; xác nhận thanh toán |
| ≥ 1 màn báo cáo có biểu đồ | Đạt | Biểu đồ cột doanh thu + biểu đồ tròn lấp đầy |
| 3 trạng thái tải / thành công / lỗi mạng | Đạt | `TrangThaiManHinh` + `SwipeRefreshLayout` |
| Không mất dữ liệu khi xoay | Đạt | `configChanges` ở 3 Activity + `onSaveInstanceState` ở login, main, hóa đơn, chỉ số |
| Tên app + TAG log chứa mã nhóm | Đạt | `555Rental Admin`; `555Rental-*` |
| ≥ 6 màn hình | Đạt (12) | Mục 5.3 |
| APK release cài được trên máy thật | Đã ký, chờ ảnh cài máy thật | `admin-android/releases/555Rental-Admin-v1.0.0.apk`; `apksigner verify` đạt, chữ ký v2 |

## 9.2. Điểm làm tốt

1. **Bám sát nghiệp vụ**: app không tự tính tiền, mọi con số lấy từ backend; chặn chỉ số sai và cảnh báo tăng vọt được xử lý ở cả API lẫn giao diện.
2. **Phân quyền hai lớp**: ẩn menu ở app + chặn thật ở backend; đã kiểm tra `403` bằng Postman.
3. **Trải nghiệm lỗi rõ ràng**: 3 trạng thái, thông báo tiếng Việt theo từng mã lỗi, nút Thử lại, không văng khi mất mạng.
4. **Mã nguồn có cấu trúc**: tách `data`, `ui`, `util`; DTO đặt tên theo đúng `snake_case` của backend nên Gson ánh xạ trực tiếp, ít lỗi.
5. **Tài liệu đầy đủ**: README, hướng dẫn build APK, kịch bản video, bộ câu hỏi bảo vệ.

## 9.3. Hạn chế

1. **Chưa có ảnh chụp màn hình trong báo cáo**: môi trường làm việc không có emulator; cần chụp trên máy thật trước khi nộp.
2. **Chưa kiểm thử tự động**: chưa viết unit test/Espresso; kiểm thử hiện là thủ công + Postman.
3. **Chưa có chế độ offline thật**: khi mất mạng chỉ hiện lỗi và cho thử lại, chưa cache dữ liệu để xem lại.
4. **Một số trường hợp backend chưa trả đủ dữ liệu** (ví dụ `chi_so` trong chi tiết hóa đơn bị `null`), app chỉ hiển thị thông báo thay thế.
5. **Chưa hỗ trợ đa ngôn ngữ**: toàn bộ chuỗi tiếng Việt, chưa tách hết sang `strings.xml`.

## 9.4. Hướng phát triển

| Hướng | Lợi ích | Độ khó |
|---|---|---|
| Thêm mã VietQR đúng số tiền và nội dung chuyển khoản | Giảm thao tác đối chiếu cho chủ trọ | Trung bình |
| Xuất hợp đồng / hóa đơn ra PDF và chia sẻ | Người thuê lưu trữ, in được | Trung bình |
| Cache bằng Room + WorkManager | Xem dữ liệu khi mất mạng, đồng bộ lại sau | Cao |
| Thông báo đẩy khi có biên lai / sự cố mới | Phản hồi nhanh hơn | Trung bình |
| Unit test + Espresso cho luồng đăng nhập và ghi chỉ số | Giảm hồi quy khi sửa | Trung bình |
| Tách toàn bộ chuỗi sang `strings.xml`, thêm tiếng Anh | Mở rộng đối tượng dùng | Thấp |

## 9.5. Tự chấm

| Nội dung | Điểm tự chấm (thang 10) | Lý do |
|---|---|---|
| Hoàn thành chức năng App Admin | 9.0 | Đủ 12 màn, đúng nghiệp vụ, có phân quyền và báo cáo |
| Chất lượng mã nguồn | 8.5 | Cấu trúc rõ, xử lý lỗi tốt; chưa có test tự động |
| Báo cáo và tài liệu | 8.5 | Đủ mục được giao; còn thiếu ảnh chụp thực tế |
| Kỹ năng bảo vệ | 8.5 | Hiểu luồng, đã chuẩn bị 6 câu hỏi và câu trả lời |
| **Trung bình** | **8.6** | |
