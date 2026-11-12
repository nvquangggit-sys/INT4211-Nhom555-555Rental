# Checklist 18 mục tự kiểm trước khi nộp

> In bảng này, cả nhóm tick từng dòng trước buổi bảo vệ. Cột “Ghi chú” ghi người chịu trách nhiệm và bằng chứng.

| # | Hạng mục kiểm tra | Cách kiểm tra | Trạng thái | Ghi chú |
|---|---|---|---|---|
| 1 | `/health` trả 200 từ máy khác | Mở `https://rental-nhom555-api.onrender.com/health` trên điện thoại/trình duyệt khác | ☐ | A |
| 2 | Không token → 401 | Postman `GET /hoa-don` không header Authorization | ☑ | Đã kiểm tra: `401 {"loi":"Thiếu token đăng nhập"}` |
| 3 | Sai vai trò → 403 | Token `quanly` gọi `GET /bao-cao/doanh-thu` | ☑ | Đã kiểm tra: `403` |
| 4 | Supabase đang Active | Supabase Dashboard → Project status | ☐ | A kiểm tra trước giờ demo |
| 5 | `schema.sql` + `seed.sql` chạy trên CSDL trống | Tạo project Supabase mới → SQL Editor → chạy lần lượt | ☐ | A |
| 6 | Dữ liệu mẫu đủ số lượng | Đếm: 3 khu, 60 phòng, 45 hợp đồng, 270 hóa đơn | ☐ | A cung cấp câu `SELECT COUNT(*)` |
| 7 | APK Admin cài máy thật, đăng nhập được | `adb install -r admin-android/releases/555Rental-Admin-v1.0.0.apk` | ☐ | B |
| 8 | APK Client cài máy thật, đăng nhập được | Theo hướng dẫn của C | ☐ | C |
| 9 | Thêm ở Admin → hiện ở Client | Tạo phòng/khu mới ở Admin, mở Client tải lại | ☐ | B + C |
| 10 | Tắt Wi-Fi không văng | Bật chế độ máy bay, mở app, kéo xuống tải lại | ☐ | B |
| 11 | Xoay màn hình không mất dữ liệu | Nhập form, xoay ngang/dọc | ☐ | B |
| 12 | `flutter analyze` sạch | `cd client-flutter && flutter analyze` | ☐ | C |
| 13 | `.env` không có trong repo (cả lịch sử) | `git log --all --oneline -- .env`; `git grep -i "JWT_SECRET" (git rev-list --all)` | ☐ | A |
| 14 | README đủ link API, tài khoản thử, cách chạy | Đọc `README.md` | ☑ | Đã bổ sung phần App Admin |
| 15 | Mỗi người ≥ 15 commit tài khoản riêng | `git shortlog -sne --all` | ☐ | B: kiểm tra trước khi nộp |
| 16 | Báo cáo đủ 9 mục, có ERD + ≥ 25 ca kiểm thử | Đối chiếu `docs/` và báo cáo PDF | ☐ | Cả nhóm |
| 17 | Video 5–8 phút, quay thật, có thuyết minh | Xem lại video trước khi nộp | ☐ | Cả nhóm |
| 18 | Gọi thử API 3 phút trước giờ demo | Mở `/health` + đăng nhập thử | ☐ | A |

## Ghi chú riêng cho phần App Admin

- [x] Build `assembleDebug` thành công.
- [x] Build `assembleRelease` thành công, APK đã ký.
- [x] Kiểm tra `401` / `403` / `400` / `404` bằng API thật.
- [x] Có đủ 12 màn hình, 9 RecyclerView, 2 biểu đồ.
- [ ] Chụp ảnh màn hình thật cho báo cáo.
- [ ] Quay đoạn video phần Admin.
- [ ] Cài APK trên máy thật và tick mục 7, 10, 11.

## Lệnh kiểm tra nhanh

```powershell
# 1. Health
curl.exe -i https://rental-nhom555-api.onrender.com/health

# 2. Không token
curl.exe -i https://rental-nhom555-api.onrender.com/hoa-don

# 3. Đăng nhập và gọi API sai vai trò
$body = '{"email":"quanly@555rental.vn","matKhau":"123456"}'
$token = (curl.exe -s -X POST https://rental-nhom555-api.onrender.com/auth/dang-nhap `
  -H "Content-Type: application/json" -d $body | ConvertFrom-Json).token
curl.exe -i https://rental-nhom555-api.onrender.com/bao-cao/doanh-thu `
  -H "Authorization: Bearer $token"

# 4. Kiểm tra .env trong lịch sử
git log --all --oneline -- .env
git grep -i "JWT_SECRET" (git rev-list --all)
```
