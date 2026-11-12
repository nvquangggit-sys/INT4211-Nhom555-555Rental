# API - Hệ thống quản lý nhà trọ (Nhóm 555 - INT4211 - Đề 12)

Tài liệu này mô tả toàn bộ REST API của backend. Có thể import file
`postman/555Rental.postman_collection.json` để gọi thử ngay.

## 1. Quy ước chung

| Nội dung | Quy ước |
|---|---|
| Base URL local | `http://localhost:3000` |
| Base URL production | `https://rental-nhom555-api.onrender.com` |
| Định dạng dữ liệu | JSON, UTF-8 |
| Tên trường | `snake_case` (một số API nhận thêm alias `camelCase` để app dễ dùng) |
| Xác thực | Header `Authorization: Bearer <token>` |
| Token | JWT, hạn mặc định 7 ngày, payload gồm `id`, `vaiTro`, `hoTen`, `email` |
| Tiền | Số nguyên, đơn vị đồng |
| Tháng | Chuỗi `YYYY-MM` |
| Ngày | `YYYY-MM-DD` (riêng `thoi_gian` xem phòng dùng ISO 8601) |
| Ảnh | Gửi `multipart/form-data` (field `anh`, `anh_bien_lai`) hoặc URL trong JSON |

### Vai trò

- `CHU_TRO`: chủ trọ, toàn quyền.
- `QUAN_LY`: quản lý khu trọ, **không** được xem doanh thu và **không** được sửa biểu giá.
- `NGUOI_THUE`: người thuê, chỉ xem dữ liệu của mình.

Phân quyền được kiểm tra ở backend bằng middleware `xacThuc` + `choPhep`; ẩn nút trên app không đủ.

### Mã trạng thái

| Mã | Ý nghĩa |
|---|---|
| 200 | Lấy / cập nhật thành công |
| 201 | Tạo mới thành công |
| 400 | Dữ liệu sai, thiếu trường, sai định dạng |
| 401 | Thiếu / sai / hết hạn token, sai mật khẩu |
| 403 | Đã đăng nhập nhưng không đủ quyền |
| 404 | Không tìm thấy tài nguyên / đường dẫn |
| 409 | Xung đột dữ liệu (trùng tháng, phòng đã thuê, giao dịch đã xác nhận...) |
| 500 | Lỗi máy chủ |
| 502 | Lỗi dịch vụ ngoài (Supabase Storage) |

### Định dạng lỗi

```json
{
  "loi": "Chỉ số điện cuối (120) không được nhỏ hơn chỉ số đầu (150)",
  "chi_tiet": {
    "truong": "dien_cuoi",
    "dien_dau": 150,
    "dien_cuoi": 120
  }
}
```

`chi_tiet` chỉ xuất hiện ở một số lỗi nghiệp vụ cần chỉ rõ trường sai.

### Tài khoản seed

Mật khẩu chung: `123456`

| Vai trò | Email |
|---|---|
| Chủ trọ | `chutro@555rental.vn` |
| Quản lý | `quanly@555rental.vn` |
| Người thuê | `nguoithue01@555rental.vn` ... `nguoithue45@555rental.vn` |

---

## 2. Kiểm tra hệ thống

### `GET /health` - Public

Render dùng endpoint này để health check.

```json
{
  "ok": true,
  "ten": "555Rental API - Nhóm 555",
  "phien_ban": "1.0.0",
  "thoi_gian": "2026-11-11T08:00:00.000Z",
  "db": "ok"
}
```

Nếu CSDL lỗi, API vẫn trả `200` nhưng `db` là `"khong ket noi duoc"` để Render không restart liên tục.

### `GET /` - Public

Trả thông tin giới thiệu API và đường dẫn tài liệu.

---

## 3. Xác thực - `/auth`

### `POST /auth/dang-ky` - Public

Tạo tài khoản `NGUOI_THUE`.

Body:

```json
{
  "email": "nguoimoi@example.com",
  "matKhau": "123456",
  "hoTen": "Nguyễn Văn Mới",
  "sdt": "0909123456",
  "cccd": "079012345678"
}
```

- `201`: `{ "nguoiDung": { ... }, "token": "..." }`
- `400`: email sai hoặc dài quá 120 ký tự, mật khẩu dưới 6 ký tự, thiếu họ tên.
- `409`: email hoặc CCCD đã tồn tại.

### `POST /auth/dang-nhap` - Public

```json
{ "email": "chutro@555rental.vn", "matKhau": "123456" }
```

- `200`:

```json
{
  "token": "eyJhbGciOi...",
  "nguoiDung": {
    "id": 1,
    "email": "chutro@555rental.vn",
    "ho_ten": "Nguyễn Văn Chủ",
    "sdt": "0901000001",
    "cccd": null,
    "vai_tro": "CHU_TRO"
  }
}
```

- `400`: thiếu email/mật khẩu.
- `401`: sai email hoặc mật khẩu (thông báo giống nhau để không lộ email tồn tại).

### `GET /auth/toi` - Đã đăng nhập

Trả hồ sơ của người dùng trong token, dùng khi app mở lại. Không bao giờ trả `mat_khau_hash`.

- `200`, `401`, `404`.

---

## 4. Tìm phòng - Public

### `GET /phong`

Tìm phòng cho thuê. Mặc định chỉ trả phòng `TRONG`.

Query:

| Tham số | Kiểu | Mô tả |
|---|---|---|
| `khuVuc` | string | Tìm trong phường/xã, tên khu, địa chỉ (ILIKE) |
| `giaTu`, `giaDen` | int | Khoảng giá thuê |
| `dienTichTu`, `dienTichDen` | number | Khoảng diện tích |
| `sucChua` | int | Sức chứa tối thiểu |
| `khuTro` | int | Lọc theo mã khu |
| `q` | string | Tìm theo số phòng |
| `trangThai` | `TRONG` / `DA_THUE` / `DANG_SUA` / `ALL` | Mặc định `TRONG` |
| `page` | int | Mặc định 1 |
| `limit` | int | Mặc định 50, tối đa 100 |

Response: mảng phòng kèm `ten_khu`, `dia_chi`, `phuong_xa`, `tien_ich`, đơn giá điện/nước/phí. Header `X-Tong-So` chứa tổng số bản ghi khớp điều kiện.

- `200`, `400` nếu tham số sai.

### `GET /phong/:id`

Chi tiết một phòng, kèm tên/số điện thoại chủ trọ. `200`, `404`.

---

## 5. API cho người thuê

### `POST /lich-xem-phong` - `NGUOI_THUE`

```json
{
  "phong_id": 36,
  "thoi_gian": "2026-11-15T09:00:00.000Z"
}
```

- `201`: bản ghi lịch với `trang_thai = "CHO_XAC_NHAN"`.
- `400`: thời gian sai hoặc ở quá khứ.
- `404`: không có phòng.
- `409`: phòng không còn trống / trùng khung giờ.

### `GET /lich-xem-phong/cua-toi` - `NGUOI_THUE`

Danh sách lịch xem của chính mình, kèm thông tin phòng. `200`.

### `DELETE /lich-xem-phong/:id` - `NGUOI_THUE`

Chỉ hủy được lịch của mình đang `CHO_XAC_NHAN`.

- `200`: `{ "da_huy": true, "lich": { ... } }`
- `404`: không tìm thấy lịch phù hợp.

### `GET /hop-dong/cua-toi` - `NGUOI_THUE`

Hợp đồng `HIEU_LUC` của mình, kèm `so_ngay_con_lai`. Thêm `?tatCa=1` để lấy cả hợp đồng đã hủy/hết hạn. `200`.

### `GET /hoa-don/cua-toi` - `NGUOI_THUE`

Hóa đơn của mình, mỗi hóa đơn có `chi_tiet`, `thanh_toan`, `con_no`, chỉ số điện nước của tháng. Lọc thêm `?thang=YYYY-MM`.

- `200`, `400` nếu tháng sai.

### `GET /thanh-toan/cua-toi` - `NGUOI_THUE`

Lịch sử giao dịch thanh toán của mình, kèm tên người xác nhận. `200`.

### `POST /thanh-toan` - `NGUOI_THUE`

Gửi xác nhận thanh toán. Hỗ trợ JSON hoặc `multipart/form-data`.

JSON:

```json
{
  "hoa_don_id": 12,
  "so_tien": 100000,
  "hinh_thuc": "CHUYEN_KHOAN",
  "anh_bien_lai": "https://.../bien-lai.jpg"
}
```

Multipart: các field giống trên, thêm file ở field `anh_bien_lai` (hoặc `anh`).

Quy tắc:

- Bỏ `so_tien` thì mặc định trả toàn bộ còn nợ.
- `CHUYEN_KHOAN` bắt buộc có ảnh biên lai.
- Mỗi hóa đơn chỉ có tối đa một giao dịch đang chờ xác nhận.
- Không cho trả vượt số còn nợ.

- `201`: `{ "thanh_toan": {...}, "hoa_don": {...}, "thong_diep": "..." }`
- `400`: thiếu ảnh, số tiền sai, hình thức sai.
- `403`: hóa đơn của người khác.
- `404`: không có hóa đơn.
- `409`: đã trả đủ / đang có giao dịch chờ.

### `POST /bao-su-co` - `NGUOI_THUE`

```json
{
  "phong_id": 1,
  "loai": "Hỏng điện",
  "mo_ta": "Ổ điện bị chập",
  "anh_url": "https://.../su-co.jpg"
}
```

Chỉ được báo cho phòng mình đang có hợp đồng `HIEU_LUC`.

- `201`: sự cố `MOI`.
- `403`: không có hợp đồng hiệu lực ở phòng đó.

### `GET /bao-su-co/cua-toi` - `NGUOI_THUE`

Danh sách sự cố do mình báo. `200`.

### `GET /nhac-han` - `NGUOI_THUE`

Trả hai mảng:

- `hoa_don`: hóa đơn còn nợ, đến hạn trong 7 ngày tới hoặc đã quá hạn.
- `hop_dong`: hợp đồng còn hiệu lực, hết hạn trong 30 ngày tới.

### `GET /hoa-don/:id` - Đã đăng nhập

Chi tiết hóa đơn kèm `chi_tiet`, `chi_so`, `thanh_toan`.

- Chủ trọ chỉ xem hóa đơn thuộc khu của mình.
- Người thuê chỉ xem hóa đơn của mình.
- `403` nếu sai chủ, `404` nếu không tồn tại.

### `POST /upload/anh` - Đã đăng nhập

Upload một ảnh dùng chung (tối đa 5 MB; JPEG/PNG/WEBP/GIF), field `anh`.

- `201`: `{ "url": "...", "nguon": "supabase" | "local" }`
- `400`: thiếu tệp / sai định dạng / quá dung lượng.

---

## 6. Quản lý khu trọ - `/khu-tro`

### `GET /khu-tro` - `CHU_TRO`, `QUAN_LY`

Chủ trọ chỉ thấy khu của mình; quản lý thấy tất cả. Mỗi khu kèm biểu giá và số phòng (`so_phong`, `so_phong_trong`, `so_phong_da_thue`). `200`.

### `GET /khu-tro/:id` - `CHU_TRO`, `QUAN_LY`

Chi tiết khu + biểu giá. `200`, `403`, `404`.

### `POST /khu-tro` - `CHU_TRO`

Tạo khu và biểu giá mặc định trong **một transaction**.

```json
{
  "ten": "Khu trọ 555 Quận 7",
  "dia_chi": "10 Nguyễn Thị Thập",
  "phuong_xa": "Tân Phú, Quận 7, TP.HCM",
  "tien_ich": "Wifi, giữ xe",
  "bieu_gia": {
    "gia_dien": 3800,
    "gia_nuoc": 18000,
    "phi_rac": 30000,
    "phi_gui_xe": 100000
  }
}
```

`201`: khu kèm `bieu_gia`. `400` nếu thiếu/sai trường.

### `PATCH /khu-tro/:id` - `CHU_TRO`

Sửa `ten`, `dia_chi`, `phuong_xa`, `tien_ich`. `200`, `403`, `404`.

### `DELETE /khu-tro/:id` - `CHU_TRO`

Chỉ xóa khu chưa có phòng. `200`, `409`, `403`, `404`.

---

## 7. Quản lý phòng - `/phong`

> Danh sách và chi tiết phòng công khai nằm ở mục 4.

### `POST /phong` - `CHU_TRO`

```json
{
  "khu_tro_id": 1,
  "so_phong": "121",
  "dien_tich": 25,
  "gia_thue": 3200000,
  "suc_chua": 3,
  "trang_thai": "TRONG",
  "anh_url": "https://..."
}
```

- `201`, `400`, `403`, `404` (khu không tồn tại), `409` (trùng số phòng trong khu).

### `PATCH /phong/:id` - `CHU_TRO`

Sửa một hoặc nhiều trường. `200`, `400`, `403`, `404`, `409`.

### `DELETE /phong/:id` - `CHU_TRO`

Chỉ xóa phòng chưa có hợp đồng và chưa có chỉ số điện nước.

- `200`: `{ "da_xoa": true, "id": 123 }`
- `409`: còn dữ liệu liên quan.

---

## 8. Hợp đồng - `/hop-dong`

### `GET /hop-dong` - `CHU_TRO`, `QUAN_LY`

Query: `khuTro`, `trangThai` (`HIEU_LUC` / `HET_HAN` / `DA_HUY`), `q` (số phòng hoặc tên người thuê).

`200`: mảng hợp đồng kèm `so_phong`, `ten_khu`, `ten_nguoi_thue`, `so_ngay_con_lai`.

### `GET /hop-dong/:id` - `CHU_TRO`, `QUAN_LY`

Chi tiết hợp đồng. `200`, `403`, `404`.

### `POST /hop-dong` - `CHU_TRO`

Tạo hợp đồng + đổi phòng sang `DA_THUE` trong **một transaction**.

```json
{
  "phong_id": 36,
  "nguoi_thue_id": 3,
  "bat_dau": "2026-11-01",
  "ket_thuc": "2027-11-01",
  "tien_coc": 3000000,
  "so_nguoi": 2
}
```

- `201`: hợp đồng `HIEU_LUC`.
- `400`: ngày sai, số người vượt sức chứa, tài khoản không phải người thuê.
- `409`: phòng không trống / đã có hợp đồng hiệu lực.

### `PATCH /hop-dong/:id` - `CHU_TRO`

Kết thúc hoặc hủy hợp đồng:

```json
{ "trang_thai": "DA_HUY" }
```

hoặc gia hạn:

```json
{ "ket_thuc": "2027-12-31" }
```

Khi hợp đồng không còn `HIEU_LUC`, phòng được trả về `TRONG` nếu không còn hợp đồng hiệu lực khác. Ngược lại, hợp đồng `HIEU_LUC` giữ phòng ở `DA_THUE`.

- `200`: hợp đồng sau khi cập nhật.
- `400`: `ket_thuc` không phải ngày hợp lệ hoặc không sau `bat_dau`.
- `403`: không quản lý hợp đồng.
- `404`: không tìm thấy hợp đồng.
- `409`: cố kích hoạt lại hợp đồng đã `HET_HAN` / `DA_HUY` (phải tạo hợp đồng mới).

---

## 9. Biểu giá - `/bieu-gia`

### `GET /bieu-gia` - `CHU_TRO`, `QUAN_LY`

Danh sách biểu giá theo khu. `200`.

### `GET /bieu-gia/:khuTroId` - `CHU_TRO`, `QUAN_LY`

Biểu giá của một khu. `200`, `404`.

### `PATCH /bieu-gia/:khuTroId` - **chỉ `CHU_TRO`**

```json
{ "gia_dien": 3900, "gia_nuoc": 19000, "phi_rac": 30000, "phi_gui_xe": 100000 }
```

- `200`: biểu giá mới.
- `403`: `QUAN_LY` gọi (đây là test phân quyền bắt buộc).

---

## 10. Chỉ số điện nước - `/chi-so-dien-nuoc`

### `GET /chi-so-dien-nuoc` - `CHU_TRO`, `QUAN_LY`

Query: `khuTro`, `phong`, `thang`. Trả kèm `tieu_thu_dien`, `tieu_thu_nuoc`. `200`.

### `POST /chi-so-dien-nuoc` - `CHU_TRO`, `QUAN_LY`

**Điểm nhấn 1** - ghi chỉ số thông minh.

```json
{
  "phong_id": 1,
  "thang": "2026-11",
  "dien_cuoi": 5000,
  "nuoc_cuoi": 200
}
```

Quy tắc:

1. `dien_dau` / `nuoc_dau` tự động lấy từ chỉ số cuối của tháng gần nhất trước đó. Nếu chưa có lịch sử mới dùng giá trị gửi lên (mặc định 0).
2. `dien_cuoi < dien_dau` hoặc `nuoc_cuoi < nuoc_dau` → `400`, kèm `chi_tiet.truong`.
3. Ghi trùng `(phong_id, thang)` → `409`.
4. Nếu điện tiêu thụ tháng này **> 150% trung bình tối đa 3 tháng trước**, trả thêm `canh_bao`.

Response `201`:

```json
{
  "chi_so": {
    "id": 316,
    "phong_id": 1,
    "thang": "2026-11",
    "dien_dau": 4670,
    "dien_cuoi": 5000,
    "nuoc_dau": 191,
    "nuoc_cuoi": 200,
    "tieu_thu_dien": 330,
    "tieu_thu_nuoc": 9
  },
  "canh_bao": {
    "loai": "DIEN_TANG_VOT",
    "thong_diep": "Điện tháng 2026-11 tăng 120% so với trung bình 3 tháng trước",
    "tieu_thu_hien_tai": 330,
    "trung_binh_3_thang": 150,
    "phan_tram_tang": 120
  }
}
```

`canh_bao` là `null` nếu bình thường. Đây chỉ là cảnh báo, **không chặn** ghi chỉ số.

---

## 11. Hóa đơn - `/hoa-don`

### `GET /hoa-don` - `CHU_TRO`, `QUAN_LY`

Query: `khuTro`, `thang`, `trangThai` (`CHUA_THU` / `MOT_PHAN` / `DA_THU` / `QUA_HAN`), `quaHan` (số ngày).

`trang_thai` trong response được **suy ra từ dữ liệu** (`tong_tien`, `da_thu`, `han_thanh_toan`) chứ không chỉ đọc cột lưu sẵn: hóa đơn chưa thu đủ và quá hạn hơn 10 ngày luôn hiển thị `QUA_HAN`, kể cả khi cột `trang_thai` trong CSDL còn là `CHUA_THU`. Nhờ vậy bộ lọc `trangThai` luôn chính xác mà không cần job cập nhật định kỳ.

`200`: mảng hóa đơn kèm `so_phong`, `ten_khu`, `ten_nguoi_thue`, `con_no`, `so_ngay_qua_han`.

### `POST /hoa-don/phat-hanh` - `CHU_TRO`, `QUAN_LY`

**Điểm nhấn 2** - phát hành hóa đơn hàng loạt cho một khu trong **một transaction**.

Query bắt buộc:

- `thang=YYYY-MM`
- `khuTro=<id>`

Thiếu `khuTro` trả `400` với thông báo rõ ràng (không phải lỗi kiểu dữ liệu chung chung).

Ví dụ:

```
POST /hoa-don/phat-hanh?thang=2026-11&khuTro=2
```

Xử lý:

1. Lấy mọi hợp đồng `HIEU_LUC` đang hiệu lực trong tháng của khu.
2. Bỏ qua hợp đồng đã có hóa đơn tháng đó (chống nhân đôi).
3. Bỏ qua phòng chưa ghi chỉ số điện nước tháng đó.
4. Tính: tiền phòng + điện + nước + rác + gửi xe.
5. Ghi `hoa_don` + 5 dòng `chi_tiet_hoa_don` trong cùng transaction.
6. So sánh điện với trung bình 3 tháng trước, trả danh sách cảnh báo.

Response `201`:

```json
{
  "thang": "2026-11",
  "khu_tro_id": 2,
  "so_hoa_don_da_tao": 15,
  "tong_tien": 61200000,
  "da_tao": [
    {
      "hoa_don_id": 271,
      "phong_id": 21,
      "so_phong": "101",
      "tong_tien": 4080000,
      "han_thanh_toan": "2026-12-10"
    }
  ],
  "bo_qua": [
    {
      "phong_id": 22,
      "so_phong": "102",
      "ly_do": "Đã có hóa đơn tháng này"
    }
  ],
  "thieu_chi_so": [
    { "phong_id": 23, "so_phong": "103" }
  ],
  "canh_bao_bat_thuong": [
    {
      "phong_id": 24,
      "so_phong": "104",
      "tieu_thu_dien": 330,
      "trung_binh_3_thang": 150,
      "phan_tram_tang": 120
    }
  ]
}
```

- `400`: thiếu/sai `thang`, `khuTro`, hoặc khu chưa có biểu giá.
- `403`: người thuê gọi.

### `GET /hoa-don/:id` - Đã đăng nhập

Xem mục 5.

---

## 12. Thanh toán (admin) - `/thanh-toan`

### `GET /thanh-toan` - `CHU_TRO`, `QUAN_LY`

Query: `hoaDon`, `khuTro`. Giao dịch chờ xác nhận được xếp trước. `200`.

### `PATCH /thanh-toan/:id/xac-nhan` - `CHU_TRO`

**Transaction**: khóa giao dịch + hóa đơn, kiểm tra chưa xác nhận, cộng tiền vào `hoa_don.da_thu`, cập nhật trạng thái `DA_THU` / `MOT_PHAN`.

- `200`: `{ "thanh_toan": {...}, "hoa_don": {...} }`
- `400`: số tiền vượt công nợ.
- `403`: không phải chủ khu.
- `404`: không có giao dịch.
- `409`: giao dịch đã được xác nhận trước đó.

---

## 13. Lịch xem phòng (admin) - `/lich-xem-phong`

### `GET /lich-xem-phong` - `CHU_TRO`, `QUAN_LY`

Query: `khuTro`, `trangThai` (`CHO_XAC_NHAN` / `DA_XAC_NHAN` / `TU_CHOI`). `200`.

### `PATCH /lich-xem-phong/:id` - `CHU_TRO`, `QUAN_LY`

```json
{ "trang_thai": "DA_XAC_NHAN" }
```

Chỉ nhận `DA_XAC_NHAN` hoặc `TU_CHOI`. `200`, `400`, `403`, `404`.

---

## 14. Người dùng - `/nguoi-dung`

### `GET /nguoi-dung` - `CHU_TRO`, `QUAN_LY`

Query: `vaiTro`, `q` (tên/email/số điện thoại). Tối đa 200 bản ghi.

`200`: chỉ trả `id, email, ho_ten, sdt, cccd, vai_tro` - **không trả mật khẩu**.

Phạm vi dữ liệu:

- `QUAN_LY`: thấy toàn bộ tài khoản (nhân viên vận hành).
- `CHU_TRO`: chỉ thấy chính mình và người thuê **có hợp đồng ở khu mình quản lý**, hoặc người thuê **chưa có hợp đồng nào** (để còn tạo hợp đồng mới). Không thấy CCCD/SĐT của người thuê khu khác.

---

## 15. Sự cố (admin) - `/bao-su-co`

### `GET /bao-su-co` - `CHU_TRO`, `QUAN_LY`

Query: `khuTro`, `trangThai` (`MOI` / `DANG_XU_LY` / `DA_XU_LY`). `200`.

### `PATCH /bao-su-co/:id` - `CHU_TRO`, `QUAN_LY`

```json
{ "trang_thai": "DA_XU_LY" }
```

Khi chuyển sang `DA_XU_LY`, backend tự ghi `xu_ly_luc = now()`. `200`, `400`, `403`, `404`.

---

## 16. Báo cáo - `/bao-cao`

### `GET /bao-cao/tong-quan` - `CHU_TRO`, `QUAN_LY`

Trả `phong` (tổng/đã thuê/trống/sửa) và `su_co` (mới/đang xử lý).

Chỉ `CHU_TRO` nhận thêm `hoa_don_thang_nay` (phải thu, đã thu, còn nợ). `QUAN_LY` không thấy số liệu doanh thu.

### `GET /bao-cao/cong-no` - `CHU_TRO`, `QUAN_LY`

Query: `khuTro`, `thang`.

Trả:

- `tong_hop`: theo khu, gồm `so_hoa_don`, `tong_con_no`, `no_qua_10_ngay`.
- `chi_tiet`: từng hóa đơn còn nợ, kèm số ngày quá hạn.
- `so_hoa_don_no`, `tong_con_no`.

### `GET /bao-cao/lap-day` - `CHU_TRO`, `QUAN_LY`

Query: `khuTro`. Mỗi khu: tổng phòng, trống, đã thuê, đang sửa, `ty_le_lap_day` (%). `200`.

### `GET /bao-cao/doanh-thu` - **chỉ `CHU_TRO`**

Query: `khuTro`, `tuThang`, `denThang`.

Trả `theo_khu`, `theo_thang`, `tong` (`phai_thu`, `da_thu`, `con_no`, `so_hoa_don`).

`403` nếu `QUAN_LY` gọi.

### `GET /bao-cao/tieu-thu-bat-thuong` - `CHU_TRO`, `QUAN_LY`

Query: `thang` (mặc định tháng trước), `khuTro`.

Trả các phòng có điện tiêu thụ **> 150% trung bình 3 tháng trước**, kèm `tb_3_thang`, `phan_tram_tang`. `200`.

---

## 17. Quy tắc nghiệp vụ quan trọng (dùng khi bảo vệ)

1. **Transaction**:
   - Tạo khu + biểu giá.
   - Tạo hợp đồng + đổi trạng thái phòng.
   - Ghi chỉ số (kiểm tra trùng + đầu kỳ + insert).
   - Phát hành hóa đơn hàng loạt.
   - Xác nhận thanh toán + cộng tiền + đổi trạng thái hóa đơn.
2. **Chống trùng ở tầng CSDL**:
   - `UNIQUE(phong_id, thang)` cho chỉ số.
   - `UNIQUE(hop_dong_id, thang)` cho hóa đơn.
   - `UNIQUE(khu_tro_id, so_phong)` cho phòng.
3. **CHECK**:
   - `dien_cuoi >= dien_dau`, `nuoc_cuoi >= nuoc_dau`.
   - `da_thu <= tong_tien`.
   - `ket_thuc > bat_dau`.
4. **Phân quyền backend**: `QUAN_LY` bị `403` ở `/bieu-gia` (PATCH) và `/bao-cao/doanh-thu`; không chỉ ẩn UI.
5. **Bảo mật**: mọi truy vấn dùng tham số `$1, $2`; mật khẩu bcrypt; không trả `mat_khau_hash`.
6. **Ảnh**: production dùng Supabase Storage, local fallback chỉ để phát triển.
