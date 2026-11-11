# 555Rental - Hệ thống quản lý nhà trọ - phòng cho thuê

Đồ án cuối kỳ môn **INT4211 - Lập trình trên các thiết bị di động** (VHU), đề 12.

Repo gồm 3 phần dùng chung một cơ sở dữ liệu PostgreSQL:

| Thư mục | Nội dung | Công nghệ |
|---|---|---|
| `backend/` | REST API, CSDL, triển khai | Node.js 20, Express 4, `pg`, PostgreSQL (Supabase), JWT, bcrypt |
| `admin-android/` | App Admin cho chủ trọ / quản lý | Android Studio, Java, XML, Retrofit 2 |
| `client-flutter/` | App Client cho khách / người thuê | Flutter 3.35+, Dart 3, gói `http` |

**Thành viên nhóm 555**

- Nguyễn Việt Quang - 231A290134 (Thành viên A: Backend + CSDL + triển khai)
- Nguyễn Phạm Chí Thành - 231A010308 (Thành viên B: App Admin)
- Trần Phước Vinh - 231A290104 (Thành viên C: App Client + route khách)

## Liên kết

- **API production:** https://rental-nhom555-api.onrender.com
- **Health check:** https://rental-nhom555-api.onrender.com/health
- **Tài liệu API:** [`backend/api.md`](backend/api.md)
- **Postman collection:** [`backend/postman/555Rental.postman_collection.json`](backend/postman/555Rental.postman_collection.json)
- **Báo cáo phần Backend - CSDL - triển khai:** [`docs/BAO_CAO_THANH_VIEN_A.md`](docs/BAO_CAO_THANH_VIEN_A.md)

> Render Free ngủ sau 15 phút không có request. Trước khi demo nên gọi
> `/health` khoảng 3 phút để đánh thức service.

## Chức năng chính

### Người thuê / khách

- Tìm phòng trống theo khu vực, khoảng giá, diện tích, sức chứa.
- Xem chi tiết phòng, đặt lịch xem, theo dõi trạng thái lịch.
- Xem hợp đồng, hóa đơn từng tháng (tiền phòng, điện, nước, rác, gửi xe).
- Gửi xác nhận chuyển khoản kèm ảnh biên lai, xem lịch sử thanh toán.
- Báo sự cố kèm ảnh, theo dõi trạng thái xử lý.
- Nhận nhắc hạn hóa đơn và hợp đồng sắp hết hạn.

### Chủ trọ / quản lý

- CRUD khu trọ, phòng; cấu hình biểu giá điện - nước - rác - gửi xe.
- Tạo / hủy / gia hạn hợp đồng, tự đổi trạng thái phòng.
- Ghi chỉ số điện nước hằng tháng, tự lấy chỉ số đầu kỳ.
- Phát hành hóa đơn hàng loạt cho cả khu trong một transaction.
- Xác nhận thanh toán, cập nhật công nợ và trạng thái hóa đơn.
- Xác nhận / từ chối lịch xem phòng, xử lý sự cố.
- Báo cáo: tổng quan, công nợ, tỷ lệ lấp đầy, doanh thu, tiêu thụ bất thường.

### Phân quyền

| Vai trò | Quyền chính | Bị chặn |
|---|---|---|
| `CHU_TRO` | Toàn quyền | - |
| `QUAN_LY` | Khu trọ, phòng, hợp đồng, chỉ số, hóa đơn, lịch xem, sự cố, báo cáo vận hành | Sửa biểu giá, xem doanh thu (403) |
| `NGUOI_THUE` | Dữ liệu của chính mình, gửi thanh toán / sự cố | Toàn bộ API quản trị (403) |

Phân quyền được kiểm tra ở **backend** bằng middleware `xacThuc` + `choPhep`,
không phụ thuộc vào việc app ẩn hay hiện nút.

## Điểm nhấn kỹ thuật

### 1. Ghi chỉ số điện nước thông minh

`POST /chi-so-dien-nuoc`

- Tự lấy `dien_dau`, `nuoc_dau` từ chỉ số cuối của tháng gần nhất.
- Chặn `dien_cuoi < dien_dau` / `nuoc_cuoi < nuoc_dau` → `400`, chỉ rõ trường sai.
- Chặn ghi trùng `(phong_id, thang)` → `409`.
- Cảnh báo `DIEN_TANG_VOT` khi điện tiêu thụ **> 150% trung bình 3 tháng trước**
  (tức tăng hơn 50%), kèm số liệu so sánh.

### 2. Phát hành hóa đơn hàng loạt

`POST /hoa-don/phat-hanh?thang=YYYY-MM&khuTro=ID`

- Chạy trong **một transaction**: tạo `hoa_don` + 5 dòng `chi_tiet_hoa_don` cho
  từng hợp đồng hiệu lực.
- Bỏ qua hợp đồng đã có hóa đơn tháng đó (không nhân đôi).
- Đưa phòng chưa ghi chỉ số vào `thieu_chi_so` thay vì làm hỏng cả lô.
- Trả về `so_hoa_don_da_tao`, `tong_tien`, `bo_qua`, `thieu_chi_so`,
  `canh_bao_bat_thuong`.
- Lỗi bất kỳ giữa chừng → `ROLLBACK` toàn bộ.

Ví dụ:

```bash
curl -X POST "https://rental-nhom555-api.onrender.com/hoa-don/phat-hanh?thang=2026-11&khuTro=2" \
  -H "Authorization: Bearer <token_chu_tro>"
```

## Cấu trúc repo

```text
INT4211-Nhom555-555Rental/
├── backend/
│   ├── schema.sql                  # 11 bảng, FK, UNIQUE, CHECK, index
│   ├── seed.sql                    # dữ liệu mẫu chạy lại được
│   ├── api.md                      # tài liệu toàn bộ endpoint
│   ├── render.yaml                 # Render Blueprint
│   ├── .env.example                # mẫu biến môi trường (không có secret thật)
│   ├── postman/
│   │   └── 555Rental.postman_collection.json
│   ├── test/
│   │   ├── schema-seed.test.js     # chạy schema.sql + seed.sql, kiểm số lượng
│   │   └── api.test.js             # 73 ca end-to-end trên PGlite
│   └── src/
│       ├── index.js                # Express app, /health, error handler
│       ├── db.js                   # pool pg + hàm transaction
│       ├── middleware/auth.js      # xacThuc (401) + choPhep (403)
│       ├── routes/
│       │   ├── auth.js             # đăng ký, đăng nhập, hồ sơ
│       │   ├── chu_tro.js          # API quản trị + điểm nhấn
│       │   └── khach.js            # API công khai + người thuê
│       └── utils/                  # lỗi, kiểm tra, quyền, upload ảnh
├── admin-android/                  # App Admin (Java + XML)
├── client-flutter/                 # App Client (Flutter)
└── docs/
    └── BAO_CAO_THANH_VIEN_A.md     # mục 3, 4, 6, 7, 8, 9 của báo cáo
```

## Yêu cầu môi trường

- Node.js 20 trở lên.
- Một project PostgreSQL trên [Supabase](https://supabase.com) (gói Free).
- Tài khoản [Render](https://render.com) (gói Free) nếu muốn deploy.
- (Tuỳ chọn) Postman để import bộ collection.

## Chạy backend ở máy local

### 1. Cài dependency

```bash
cd backend
npm install
```

### 2. Tạo cơ sở dữ liệu

Trên Supabase: **SQL Editor** → dán toàn bộ `backend/schema.sql` → Run →
dán tiếp `backend/seed.sql` → Run.

Hai tệp đều có `DROP TABLE IF EXISTS ... CASCADE` / xóa dữ liệu cũ nên
**chạy lại được nhiều lần**.

Nếu dùng PostgreSQL nội bộ:

```bash
psql "$DATABASE_URL" -f backend/schema.sql
psql "$DATABASE_URL" -f backend/seed.sql
```

### 3. Cấu hình biến môi trường

```bash
cd backend
copy .env.example .env     # Windows
# hoặc: cp .env.example .env
```

Điền tối thiểu:

| Biến | Bắt buộc | Ghi chú |
|---|---|---|
| `DATABASE_URL` | Có | Supabase → Connect → **Connection pooling → Session mode, cổng 5432** |
| `JWT_SECRET` | Có | Chuỗi ngẫu nhiên tối thiểu 32 ký tự |
| `PGSSL` | Có | `true` với Supabase, `false` với PostgreSQL nội bộ |
| `JWT_HAN` | Không | Mặc định `7d` |
| `SUPABASE_URL` | Production | Dùng để upload ảnh |
| `SUPABASE_SERVICE_KEY` | Production | Service role key, chỉ đặt trên server |
| `SUPABASE_BUCKET` | Không | Mặc định `anh` |
| `PUBLIC_BASE_URL` | Local | `http://localhost:3000` khi lưu ảnh trên đĩa |

> Không dùng **Direct connection** của Supabase trên Render vì Render chỉ hỗ trợ
> IPv4, còn Direct connection là IPv6. Dùng chuỗi **Session pooler** cổng `5432`.

### 4. Chạy

```bash
npm start        # production
npm run dev      # tự reload khi sửa code
```

Kiểm tra:

```bash
curl http://localhost:3000/health
```

## Tài khoản thử

Mật khẩu chung: `123456`

| Vai trò | Email |
|---|---|
| Chủ trọ | `chutro@555rental.vn` |
| Quản lý | `quanly@555rental.vn` |
| Người thuê 01 | `nguoithue01@555rental.vn` |
| Người thuê 02 | `nguoithue02@555rental.vn` |
| ... | `nguoithue45@555rental.vn` |

## Dữ liệu mẫu

`seed.sql` sinh dữ liệu theo `CURRENT_DATE`, nên demo luôn có tháng hiện tại:

| Bảng | Số lượng |
|---|---:|
| `nguoi_dung` | 47 (1 chủ trọ, 1 quản lý, 45 người thuê) |
| `khu_tro` | 3 |
| `phong` | 60 (45 đã thuê, 9 trống, 6 đang sửa) |
| `bieu_gia` | 3 |
| `hop_dong` | 45 |
| `chi_so_dien_nuoc` | 315 (45 phòng × 7 tháng, gồm tháng gốc) |
| `hoa_don` | 270 (45 hợp đồng × 6 tháng) |
| `chi_tiet_hoa_don` | 1350 (5 khoản/hóa đơn) |
| `thanh_toan` | 234 |
| `bao_su_co` | 10 |
| `lich_xem_phong` | 9 |

Dữ liệu được thiết kế để demo:

- 9 phòng trống cho app Client tìm và đặt lịch.
- 5 phòng có tháng gần nhất tiêu thụ điện gấp 3 lần bình thường.
- Nhiều hóa đơn quá hạn hơn 10 ngày để demo báo cáo công nợ.
- Đủ trạng thái hóa đơn: `CHUA_THU`, `MOT_PHAN`, `DA_THU`, `QUA_HAN`.

Đếm lại sau khi chạy seed:

```sql
SELECT 'nguoi_dung' AS bang, count(*) FROM nguoi_dung
UNION ALL SELECT 'khu_tro', count(*) FROM khu_tro
UNION ALL SELECT 'phong', count(*) FROM phong
UNION ALL SELECT 'hop_dong', count(*) FROM hop_dong
UNION ALL SELECT 'chi_so_dien_nuoc', count(*) FROM chi_so_dien_nuoc
UNION ALL SELECT 'hoa_don', count(*) FROM hoa_don
UNION ALL SELECT 'chi_tiet_hoa_don', count(*) FROM chi_tiet_hoa_don
UNION ALL SELECT 'thanh_toan', count(*) FROM thanh_toan
UNION ALL SELECT 'bao_su_co', count(*) FROM bao_su_co
UNION ALL SELECT 'lich_xem_phong', count(*) FROM lich_xem_phong;
```

## Kiểm thử API

Bộ kiểm thử tự động nằm ngay trong repo (`backend/test/`), dùng PGlite
(PostgreSQL nhúng) nên **không cần cài PostgreSQL hay Docker**:

```bash
cd backend
npm install          # lần đầu, cài cả devDependencies
npm test             # chạy test:sql rồi test:api
# hoặc chạy riêng
npm run test:sql     # schema.sql + seed.sql, kiểm tra đủ số lượng
npm run test:api     # 73 ca end-to-end gọi API thật qua HTTP
```

Kết quả lần chạy cuối: **73/73 ca đạt**. Bộ test bao gồm:

- Health check, đăng ký, đăng nhập, sai mật khẩu → 401.
- Không token → 401; sai vai trò → 403 (kể cả `QUAN_LY` xem doanh thu / sửa biểu giá).
- Tìm phòng, lọc khu vực / giá, thử SQL injection `'; DROP TABLE phong; --`.
- Tạo / hủy hợp đồng, kiểm tra phòng về `TRONG`, xóa phòng còn hợp đồng → 409.
- Ghi chỉ số: tự lấy đầu kỳ, trùng tháng → 409, cuối < đầu → 400, cảnh báo tăng vọt.
- Phát hành hóa đơn hàng loạt: đủ 15 hóa đơn, đủ 5 khoản, tổng chi tiết khớp tổng hóa đơn.
- Phát hành lần 2 không nhân đôi hóa đơn.
- Xác nhận thanh toán cộng đúng tiền, xác nhận lần 2 → 409; ép lỗi giữa transaction → 500 và rollback giữ nguyên dữ liệu.
- Gửi chuyển khoản thiếu ảnh → 400; trùng giao dịch chờ → 409.
- Báo cáo công nợ, lấp đầy, doanh thu, tiêu thụ bất thường, tổng quan.

Chi tiết 9 ca kiểm thử backend và kết quả thực tế nằm trong
[`docs/BAO_CAO_THANH_VIEN_A.md`](docs/BAO_CAO_THANH_VIEN_A.md).
GitHub Actions chạy lại `npm test` mỗi lần push vào `main` (workflow
`.github/workflows/backend-test.yml`).

### Import Postman

1. Mở Postman → **Import** → chọn
   `backend/postman/555Rental.postman_collection.json`.
2. Chạy lần lượt 3 request đăng nhập trong folder **0. Auth**; token được tự
   lưu vào biến collection.
3. Chạy các request còn lại. Các request “mong đợi 403” dùng để chứng minh
   phân quyền backend.

## Triển khai

### Supabase

1. Tạo project Free.
2. SQL Editor → chạy `schema.sql`, sau đó `seed.sql`.
3. Storage → tạo bucket tên `anh`, để **Public** (hoặc dùng signed URL).
4. Connect → **Connection pooling → Session mode** → copy chuỗi kết nối cổng
   `5432` để đặt vào `DATABASE_URL`.

### Render

Cách nhanh: **New → Blueprint** → chọn repo này → Render đọc `backend/render.yaml`.

Cách thủ công:

1. **New → Web Service** → chọn repo.
2. Root Directory: `backend`.
3. Runtime: Node.
4. Build Command: `npm install`.
5. Start Command: `node src/index.js`.
6. Health Check Path: `/health`.
7. Plan: Free.
8. Environment Variables: `DATABASE_URL`, `JWT_SECRET`, `PGSSL=true`,
   `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `SUPABASE_BUCKET=anh`.
9. Deploy, sau đó mở `/health` kiểm tra `"db": "ok"`.

Chi tiết lỗi thường gặp (IPv6, SSL, 502, Render ngủ) xem mục 6 của
[`docs/BAO_CAO_THANH_VIEN_A.md`](docs/BAO_CAO_THANH_VIEN_A.md).

## Bảo mật

- Mật khẩu băm bằng `bcrypt` (10 vòng), không bao giờ trả về client.
- JWT ký bằng `JWT_SECRET`, hạn 7 ngày.
- Mọi câu SQL dùng tham số `$1, $2`, không nối chuỗi.
- `.env` nằm trong `.gitignore`; repo chỉ có `.env.example`.
- Ảnh giới hạn 5 MB, chỉ nhận JPEG/PNG/WEBP/GIF; production lưu trên
  Supabase Storage, không lưu base64 trong CSDL.
- CORS bật cho app di động; có thể giới hạn origin khi cần.

## Hạn chế và hướng phát triển

- Chưa tích hợp VietQR động (số tiền + nội dung chuyển khoản).
- Chưa xuất hợp đồng / hóa đơn ra PDF.
- Chưa có thông báo đẩy; app Client đang dùng màn hình nhắc hạn.
- Render Free ngủ sau 15 phút, cần đánh thức trước khi demo.
- Supabase Free tạm dừng sau 7 ngày không hoạt động, cần khôi phục trước buổi bảo vệ.

## Giấy phép

Đồ án học tập, không dùng cho mục đích thương mại.
