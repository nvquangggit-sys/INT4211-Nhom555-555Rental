# Mục 8 – Phân công và tiến độ (phần Thành viên B và C)

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

- Chụp đủ ảnh màn hình theo danh sách trong mục 5.10 và mục 7 → `docs/minh-chung/` (làm ngay, không cần chờ C).
- Cài APK release trên máy thật, kiểm tra lại 8 ca → `admin-android\tools\minh-chung.ps1 -Cai`.
- Quay đoạn video phần Admin theo `docs/kich-ban-video-admin.md` → **quay cuối cùng, sau khi C hoàn thiện app Client**, vì có cảnh chuyển sang phần C và cảnh liên thông Admin → Client.
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

---

# Mục 8 – Phân công và tiến độ (phần Thành viên C)

> Thành viên C: **Nguyễn Phạm Chí Thành – 231A010308**
> Vai trò: App Client (Flutter, `client-flutter/`) + route API phía khách (`backend/src/routes/khach.js`).
> Tỷ lệ đóng góp theo bảng phân công nhóm: **33%**.

## 8.C.1. Phạm vi công việc được giao

| Nhóm việc (theo đề) | Nội dung | Sản phẩm |
|---|---|---|
| **C1** Nền tảng Flutter | Flutter 3.35+/Dart 3, `http` + `shared_preferences`, ApiService UTF-8 + timeout 90 giây + kiểm tra `mounted` + `401` → đăng nhập | `lib/core/`, `lib/main.dart` |
| **C1** Form & khung | Form + validator đăng nhập/đăng ký; `Scaffold` + `NavigationBar` + `Drawer` | `login_screen.dart`, `register_screen.dart`, `home_shell.dart` |
| **C2** Route API khách | 13 endpoint: phòng, lịch xem, hợp đồng, hóa đơn, thanh toán (multipart), sự cố, nhắc hạn; mã lỗi 400/401/403/404/409 | `backend/src/routes/khach.js` |
| **C3** Tìm phòng & đặt lịch | Lọc khu vực/giá/diện tích, `ListView.builder`, `Future` trong `initState`, 3 trạng thái; chi tiết phòng có loading/error ảnh; đặt lịch DatePicker/TimePicker; hủy lịch + dialog + SnackBar **Hoàn tác**; hợp đồng cảnh báo ≤ 30 ngày | 8 màn hình C3 |
| **C4** Hóa đơn & sự cố | Hóa đơn + chi tiết khoản + chỉ số điện nước; lịch sử thanh toán; xác nhận chuyển khoản kèm ảnh biên lai (chống gửi trùng); báo sự cố + timeline; banner nhắc hạn từ `/nhac-han` | 7 màn hình C4 |
| Chất lượng | `flutter analyze` sạch, 21 test tự động, APK release đã ký | `test/`, `releases/` |
| Báo cáo | Mục 1, mục 5 (Client), 10 ca kiểm thử Client, mục 8–9, README Client, kịch bản video, 10 câu Q&A, hướng dẫn build APK | `docs/`, `client-flutter/README.md` |

## 8.C.2. Tiến độ theo tuần

| Tuần | Mốc | Việc đã làm | Minh chứng |
|---|---|---|---|
| 8 | Nhận đề, chốt contract API | Đọc đề 12, thống nhất JSON response với A (đăng nhập, phòng, hóa đơn), tạo khung `client-flutter/` | Commit khung project Flutter |
| 9 | C1 – tầng API | `ApiService` (token, UTF-8, timeout 90s, 401), 8 model đọc JSON chịu được `NUMERIC` dạng chuỗi | `lib/core/`, `lib/models/` |
| 10 | C1 – đăng nhập/đăng ký | Form + validator, lưu phiên `shared_preferences`, màn đổi địa chỉ API | `login_screen.dart`, `register_screen.dart` |
| 11 | C3 – tìm phòng | Lọc khu vực/giá/diện tích, `ListView.builder`, 3 trạng thái, chi tiết phòng có bảng giá | `rooms_tab.dart`, `room_detail_screen.dart` |
| 12 | C3 – đặt/hủy lịch | DatePicker + TimePicker, chống bấm hai lần; hủy lịch + SnackBar Hoàn tác | `booking_screen.dart`, `my_bookings_screen.dart` |
| 13 | C4 – hóa đơn, thanh toán | Danh sách + chi tiết hóa đơn, chỉ số điện/nước, gửi biên lai multipart | `invoices_tab.dart`, `payment_screen.dart` |
| 14 | C4 – sự cố, nhắc hạn | Báo sự cố kèm ảnh, timeline 3 bước, banner nhắc hạn + badge AppBar | `incidents_tab.dart`, `reminders_screen.dart` |
| 15 | Chất lượng & phát hành | `flutter analyze` sạch, 21 test, build + ký APK release, kiểm thử API thật bằng `curl` | `releases/555Rental-Khach-v1.0.0.apk` |
| 15 | Báo cáo & bảo vệ | Mục 1, 5, 7 (Client), mục 8–9, kịch bản video, Q&A, hướng dẫn build | `docs/*client*` |
| 16 | Dự phòng | Chụp ảnh màn hình thật, quay video, rà 18 mục | ⏳ |

## 8.C.3. Bảng công việc chi tiết

| STT | Công việc | Kết quả | Trạng thái |
|---|---|---|---|
| 1 | `ApiService` dùng chung | GET/POST/DELETE/multipart, token, timeout 90s, `utf8.decode(bodyBytes)`, 401 → login | ✅ |
| 2 | 8 model + tiện ích đọc JSON | Chịu được `NUMERIC` dạng chuỗi, `null`, mảng lồng | ✅ |
| 3 | Theme + widget dùng chung | `AnhMang` (loading/error), `NhanTrangThai`, `KhungDangTai`, `ManHinhLoi`, `MucRong` | ✅ |
| 4 | Đăng nhập | Validator email/mật khẩu, 3 trạng thái, điền tài khoản demo, banner hết phiên | ✅ |
| 5 | Đăng ký | 5 ô validate, kiểm tra nhập lại mật khẩu, trả email về màn đăng nhập | ✅ |
| 6 | HomeShell | 5 tab `NavigationBar` + `Drawer`, `IndexedStack`, badge nhắc hạn, FAB sự cố | ✅ |
| 7 | Trang chủ + nhắc hạn | Banner theo `/nhac-han`, 4 lối tắt, tóm tắt hợp đồng/hóa đơn | ✅ |
| 8 | Tìm phòng | Lọc khu vực/giá/diện tích, `ListView.builder`, đủ 3 trạng thái | ✅ |
| 9 | Chi tiết phòng | Ảnh loading/error builder, bảng giá điện–nước–rác–xe, liên hệ chủ trọ | ✅ |
| 10 | Đặt lịch | DatePicker/TimePicker tiếng Việt, chặn thời gian quá khứ, `Navigator.pop(true)` | ✅ |
| 11 | Lịch xem của tôi | Hủy có dialog, SnackBar **Hoàn tác** gọi lại API tạo lịch | ✅ |
| 12 | Hợp đồng | Thanh tiến trình, cảnh báo cam ≤ 30 ngày, đỏ khi quá hạn | ✅ |
| 13 | Hóa đơn | Tổng nợ, lọc Còn nợ/Đã đủ, chi tiết khoản + chỉ số điện/nước | ✅ |
| 14 | Thanh toán | `image_picker`, multipart, chống gửi trùng 2 lớp (client + 409) | ✅ |
| 15 | Lịch sử thanh toán | Lọc đã/chờ xác nhận, xem ảnh biên lai | ✅ |
| 16 | Sự cố | Báo sự cố JSON/multipart, timeline 3 bước, thống kê | ✅ |
| 17 | Tài khoản + đổi API | Hồ sơ từ `/auth/toi`, kiểm tra `/health`, khôi phục mặc định | ✅ |
| 18 | Kiểm thử | 21 test (định dạng, model, widget form) + 10 ca thủ công trên API thật | ✅ |
| 19 | APK release | Ký keystore riêng, `apksigner verify` đạt, 55.3 MB | ✅ |
| 20 | Tài liệu | Mục 1, 5, 7 (Client), mục 8–9, video, Q&A, build APK, README | ✅ |
| 21 | Ảnh chụp màn hình thật | Cần chụp trên máy thật khi nộp | ⏳ |

## 8.C.4. Commit cá nhân

- Tài khoản Git: `ChiThanh` – `nguyenphamchithanh2005@gmail.com`.
- 21 commit có ý nghĩa (cộng thêm các commit rà soát, sửa tài liệu), chia theo từng lớp: tầng API → model → theme → từng màn hình → cấu hình Android → test → APK → tài liệu → README.
- Kiểm tra: `git log --oneline --author=ChiThanh` hoặc GitHub → **Insights → Contributors**.

`[chèn ảnh: biểu đồ đóng góp GitHub của Nguyễn Phạm Chí Thành]`

`[chèn ảnh: git log --oneline --author=ChiThanh]`

## 8.C.5. Khó khăn và cách xử lý

| Khó khăn | Nguyên nhân | Cách xử lý |
|---|---|---|
| Render Free ngủ 15 phút | Gói Free | Timeout 90 giây + thông điệp “máy chủ có thể đang ngủ đông” + nút Thử lại |
| Tiếng Việt bị lỗi font | `http` đoán charset từ header, server không ghi `charset=utf-8` | Đọc `utf8.decode(res.bodyBytes)` ở mọi response |
| Đăng nhập sai bị đẩy về màn đăng nhập | Xử lý `401` quá tay | Chỉ coi `401` là hết phiên khi **đang có token** |
| Bấm gửi biên lai hai lần | Mạng chậm, người dùng bấm lại | Cờ `_dangGui` khóa nút + backend trả `409` khi có giao dịch chờ |
| Gradle lỗi `Could not close incremental caches` | Windows/antivirus khóa cache Kotlin | `kotlin.incremental=false` + `flutter clean` trước khi build release |
| Ảnh Supabase không hiện | URL chết hoặc mất mạng | `errorBuilder` ở mọi `Image.network`, không để app văng |
| Dữ liệu seed không có hợp đồng ≤ 30 ngày | Ngày seed tính theo `CURRENT_DATE` | Unit test `HopDong` với `so_ngay_con_lai=20`; ghi chú trong mục 7 |
| Không có emulator | Máy không đủ tài nguyên | Build APK release, cài máy thật; kiểm thử API bằng `curl` |

## 8.C.6. Việc còn lại trước khi nộp

- Chụp ảnh 10 ca theo bảng 7.5 → `docs/minh-chung/client-*.png` (danh sách chi tiết ở mục 6 của `docs/minh-chung/README.md`).
- Quay video Client theo `docs/kich-ban-video-client.md` → `docs/minh-chung/client-demo.mp4` (quay **trước** phần Admin để B quay cảnh liên thông Admin → Client).
- Đối chiếu 18 mục tự kiểm: xem `docs/checklist-18-muc.md`.
- Nhờ chủ trọ xác nhận giao dịch 100.000 đ còn chờ trên hóa đơn id 1 để quay lại cảnh gửi biên lai thành công.

---

# Mục 9 – Tự đánh giá (phần Thành viên C)

## 9.C.1. Kết quả đạt được

| Tiêu chí App Client | Kết quả | Minh chứng |
|---|---|---|
| Flutter 3.35+, `http` + `shared_preferences` | Đạt | `pubspec.yaml`, `lib/core/api_service.dart` |
| ApiService: UTF-8, timeout 90s, `mounted`, `401` → login | Đạt | `api_service.dart`, `main.dart` (`GlobalKey<NavigatorState>`) |
| Form + validator đăng nhập/đăng ký | Đạt | `login_screen.dart`, `register_screen.dart`, 5 widget test |
| `Scaffold` + `NavigationBar`/`Drawer` | Đạt | `home_shell.dart` (5 tab + Drawer) |
| Route khách + mã lỗi 400/401/403/404/409 | Đạt | `backend/src/routes/khach.js`; bảng mã lỗi thật ở mục 7.4 |
| Tìm phòng: lọc, `ListView.builder`, `Future` trong `initState`, 3 trạng thái | Đạt | `rooms_tab.dart` |
| Chi tiết phòng: ảnh loading/error, đặt lịch, `Navigator.pop(result)` | Đạt | `room_detail_screen.dart`, `booking_screen.dart`, `anh_mang.dart` |
| Hủy lịch + dialog + SnackBar Hoàn tác | Đạt | `my_bookings_screen.dart` |
| Hợp đồng cảnh báo ≤ 30 ngày | Đạt | `contracts_screen.dart`, unit test `HopDong` |
| Hóa đơn: khoản, chỉ số, lịch sử thanh toán | Đạt | `invoice_detail_screen.dart`, `payment_history_screen.dart` |
| Thanh toán kèm ảnh, không gửi trùng | Đạt | `payment_screen.dart` + `409` từ backend |
| Báo sự cố + theo dõi trạng thái | Đạt | `incident_create_screen.dart`, `incidents_tab.dart` |
| Banner nhắc hạn từ `/nhac-han` | Đạt | `home_tab.dart`, `reminders_screen.dart` |
| ≥ 6 màn hình | Đạt (18) | Mục 5.3 |
| `flutter analyze` sạch | Đạt | “No issues found!” |
| APK release đã ký | Đạt | `client-flutter/releases/555Rental-Khach-v1.0.0.apk`; `apksigner verify` đạt |
| ≥ 8 ca kiểm thử | Đạt (10 thủ công + 21 tự động) | `docs/bao-cao-muc-7-kiem-thu-client.md` |

## 9.C.2. Điểm làm tốt

1. **Một cửa vào API**: toàn bộ app đi qua `ApiService`, nên xử lý token, timeout, UTF-8 và `401` chỉ viết một lần.
2. **Chịu được dữ liệu thật**: PostgreSQL trả `NUMERIC` dạng chuỗi và nhiều cột `null`; model chuẩn hóa hết nên giao diện không văng.
3. **Trải nghiệm lỗi rõ ràng**: 3 trạng thái ở mọi danh sách, nút Thử lại, thông điệp backend hiển thị nguyên văn.
4. **Chống gửi trùng hai lớp**: khóa nút ở client + ràng buộc giao dịch chờ ở backend (`409`).
5. **Kiểm thử thật**: 21 test tự động + gọi `curl` xác minh từng mã lỗi 400/401/403/404/409 trên API production.
6. **Tài liệu đầy đủ**: mục 1, 5, 7, 8–9, kịch bản video 10 cảnh, 10 câu Q&A, hướng dẫn build/ký APK.

## 9.C.3. Hạn chế

1. **Chưa có ảnh chụp màn hình trong báo cáo**: cần chụp trên máy thật trước khi nộp.
2. **Chưa có state management chuyên dụng**: dùng `FutureBuilder` + `setState`, phù hợp phạm vi nhưng khó mở rộng nếu thêm chat/thông báo realtime.
3. **Chưa cache offline**: mất mạng chỉ hiện lỗi và cho thử lại, chưa xem lại dữ liệu cũ.
4. **Chưa có thông báo đẩy**: nhắc hạn chỉ hiện khi mở app.
5. **Token lưu trong `shared_preferences`** (không mã hóa) – đủ cho đồ án, production nên dùng `flutter_secure_storage`.
6. **Ảnh phụ thuộc Supabase Storage**: nếu bucket lỗi/URL chết thì chỉ hiện khung “Không tải được ảnh”.

## 9.C.4. Hướng phát triển

| Hướng | Lợi ích | Độ khó |
|---|---|---|
| VietQR động đúng số tiền + nội dung chuyển khoản | Giảm thao tác đối chiếu | Trung bình |
| Thông báo đẩy (FCM) khi có hóa đơn / biên lai được xác nhận | Người thuê phản hồi nhanh hơn | Trung bình |
| Cache bằng `sqflite`/`drift` + đồng bộ khi có mạng | Xem được hợp đồng, hóa đơn offline | Cao |
| `flutter_secure_storage` cho JWT | An toàn hơn trên máy bị root | Thấp |
| Riverpod + repository pattern | Tách UI/dữ liệu, dễ test hơn | Trung bình |
| Xuất hóa đơn PDF và chia sẻ | Người thuê lưu trữ, in được | Trung bình |
| Đa ngôn ngữ với `intl`/ARB | Mở rộng đối tượng dùng | Thấp |

## 9.C.5. Tự chấm

| Nội dung | Điểm tự chấm (thang 10) | Lý do |
|---|---|---|
| Hoàn thành chức năng App Client (C1–C4) | 9.0 | Đủ 18 màn, đúng luồng nghiệp vụ, đủ mã lỗi |
| Chất lượng mã nguồn | 8.5 | Tách lớp rõ, `analyze` sạch, có 21 test; chưa tách repository |
| Báo cáo và tài liệu | 8.5 | Đủ mục được giao; còn thiếu ảnh chụp thực tế |
| Kỹ năng bảo vệ | 8.5 | Hiểu luồng, đã chuẩn bị 10 câu hỏi và câu trả lời |
| **Trung bình** | **8.6** | |
