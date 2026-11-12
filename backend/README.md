# Backend - 555Rental API

Backend REST cho hệ thống quản lý nhà trọ (INT4211 - đề 12 - nhóm 555).

- Node.js 20 + Express 4 + `pg` (SQL thuần, tham số `$1, $2`)
- PostgreSQL trên Supabase
- JWT + bcrypt
- Supabase Storage cho ảnh
- Deploy Render Free

## Chạy nhanh

```bash
npm install
copy .env.example .env
# điền DATABASE_URL, JWT_SECRET, PGSSL...
npm run dev
```

Chạy `schema.sql` rồi `seed.sql` trên Supabase SQL Editor trước khi khởi động.

## Tài liệu

- Toàn bộ endpoint, quyền, body, mã lỗi: [`api.md`](api.md)
- Postman: [`postman/555Rental.postman_collection.json`](postman/555Rental.postman_collection.json)
- Hướng dẫn chạy / deploy đầy đủ: [`../README.md`](../README.md)
- Báo cáo phần A: [`../docs/BAO_CAO_THANH_VIEN_A.md`](../docs/BAO_CAO_THANH_VIEN_A.md)

## Cấu trúc

```text
src/
├── index.js              # Express app, CORS, /health, 404, error handler
├── db.js                 # pool pg + truyVan + trongGiaoDich
├── middleware/auth.js    # xacThuc (401) + choPhep (403)
├── routes/auth.js        # đăng ký / đăng nhập / hồ sơ
├── routes/chu_tro.js     # API quản trị + 2 điểm nhấn kỹ thuật
├── routes/khach.js       # API công khai + người thuê
└── utils/                # lỗi, kiểm tra dữ liệu, quyền, upload ảnh

test/
├── schema-seed.test.js   # chạy schema.sql + seed.sql, kiểm tra đủ số lượng
└── api.test.js           # 88 ca end-to-end qua HTTP
```

## Biến môi trường

Xem [`.env.example`](.env.example). Tối thiểu cần `DATABASE_URL`, `JWT_SECRET`;
production cần thêm `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`.

## Script

| Lệnh | Mô tả |
|---|---|
| `npm start` | Chạy production |
| `npm run dev` | Chạy kèm watch |
| `npm run check` | Kiểm tra cú pháp `src/index.js` |
| `npm test` | Chạy cả `test:sql` và `test:api` |
| `npm run test:sql` | Chạy `schema.sql` + `seed.sql` trên PGlite, kiểm tra số lượng |
| `npm run test:api` | 88 ca kiểm thử API end-to-end trên PGlite |

Bộ test dùng PGlite (PostgreSQL nhúng) và `@electric-sql/pglite-socket`, không
cần cài PostgreSQL hay Docker. Mã nguồn test nằm trong [`test/`](test).

## Điểm nhấn

1. `POST /chi-so-dien-nuoc`: tự lấy chỉ số đầu kỳ, chặn cuối < đầu (400),
   chặn trùng tháng (409), cảnh báo điện tăng > 50% so với trung bình 3 tháng.
2. `POST /hoa-don/phat-hanh?thang=YYYY-MM&khuTro=ID`: phát hành hóa đơn cả khu
   trong một transaction, bỏ qua hóa đơn đã có, báo phòng thiếu chỉ số và cảnh
   báo bất thường.
