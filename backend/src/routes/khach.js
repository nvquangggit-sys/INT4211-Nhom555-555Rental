const router = require('express').Router();
const { truyVan } = require('../db');
const { xacThuc, choPhep } = require('../middleware/auth');
const { asyncHandler } = require('../utils/async');
const { LoiApi } = require('../utils/loi');
const { upload, luuAnh } = require('../utils/upload');
const { laThang, soNguyen, soThuc, chuoi } = require('../utils/kiem-tra');

// File này là phần route phía khách (thành viên C phụ trách theo phân công).
// Thành viên A dựng sẵn để cả nhóm có API thật chạy song song.

// Trạng thái hiệu lực của hóa đơn, suy ra từ dữ liệu nên không bị "đóng băng"
// ở giá trị cũ trong cột trang_thai:
// - đã thu đủ -> DA_THU
// - quá hạn hơn 10 ngày mà chưa thu đủ -> QUA_HAN
// - đã thu một phần -> MOT_PHAN
// - còn lại -> CHUA_THU
const TRANG_THAI_HOA_DON = `CASE
  WHEN hd.tong_tien <= hd.da_thu THEN 'DA_THU'
  WHEN hd.trang_thai = 'QUA_HAN' OR hd.han_thanh_toan < CURRENT_DATE - 10 THEN 'QUA_HAN'
  WHEN hd.da_thu > 0 THEN 'MOT_PHAN'
  ELSE 'CHUA_THU'
END`;

function chon(o, ...ten) {
  for (const k of ten) if (o && o[k] !== undefined && o[k] !== null) return o[k];
  return undefined;
}

function layFile(req) {
  if (req.file) return req.file;
  if (!req.files) return null;
  for (const k of ['anh_bien_lai', 'anhBienLai', 'anh']) {
    if (req.files[k] && req.files[k][0]) return req.files[k][0];
  }
  return null;
}

const upAnh = upload.fields([
  { name: 'anh_bien_lai', maxCount: 1 },
  { name: 'anhBienLai', maxCount: 1 },
  { name: 'anh', maxCount: 1 },
]);

// ---------------------------------------------------------------------
// TÌM PHÒNG (công khai, không cần đăng nhập)
// GET /phong?khuVuc=&giaTu=&giaDen=&dienTichTu=&trangThai=TRONG&khuTro=&page=&limit=
// ---------------------------------------------------------------------
router.get('/phong', asyncHandler(async (req, res) => {
  const dk = [];
  const ts = [];
  const them = (dieuKien, giaTri) => { ts.push(giaTri); dk.push(dieuKien.replace('?', `$${ts.length}`)); };

  if (req.query.khuVuc) {
    const tuKhoa = `%${String(req.query.khuVuc).trim()}%`;
    ts.push(tuKhoa, tuKhoa, tuKhoa);
    dk.push(`(k.phuong_xa ILIKE $${ts.length - 2} OR k.ten ILIKE $${ts.length - 1} OR k.dia_chi ILIKE $${ts.length})`);
  }
  if (req.query.giaTu) them('p.gia_thue >= ?', soNguyen(req.query.giaTu, { min: 0, ten: 'Giá từ' }));
  if (req.query.giaDen) them('p.gia_thue <= ?', soNguyen(req.query.giaDen, { min: 0, ten: 'Giá đến' }));
  if (req.query.dienTichTu) them('p.dien_tich >= ?', soThuc(req.query.dienTichTu, { min: 0, ten: 'Diện tích từ' }));
  if (req.query.dienTichDen) them('p.dien_tich <= ?', soThuc(req.query.dienTichDen, { min: 0, ten: 'Diện tích đến' }));
  if (req.query.sucChua) them('p.suc_chua >= ?', soNguyen(req.query.sucChua, { min: 1, ten: 'Sức chứa' }));
  if (req.query.khuTro) them('p.khu_tro_id = ?', soNguyen(req.query.khuTro, { min: 1, ten: 'Mã khu trọ' }));
  if (req.query.q) them('p.so_phong ILIKE ?', `%${String(req.query.q).trim()}%`);

  const trangThai = req.query.trangThai === undefined ? 'TRONG' : String(req.query.trangThai).toUpperCase();
  if (trangThai !== 'ALL') {
    if (!['TRONG', 'DA_THUE', 'DANG_SUA'].includes(trangThai)) {
      throw new LoiApi(400, 'trangThai không hợp lệ (TRONG, DA_THUE, DANG_SUA, ALL)');
    }
    them('p.trang_thai = ?', trangThai);
  }

  // Chặn limit âm/0 gây lỗi LIMIT của PostgreSQL; tối đa 100 để bảo vệ máy chủ.
  const limit = Math.min(Math.max(Number(req.query.limit) || 50, 1), 100);
  const page = Math.max(Math.floor(Number(req.query.page) || 1), 1);
  const offset = (page - 1) * limit;
  ts.push(limit, offset);

  const r = await truyVan(
    `SELECT p.*, k.ten AS ten_khu, k.dia_chi, k.phuong_xa, k.tien_ich,
            bg.gia_dien, bg.gia_nuoc, bg.phi_rac, bg.phi_gui_xe,
            count(*) OVER ()::int AS tong_so
       FROM phong p
       JOIN khu_tro k ON k.id = p.khu_tro_id
       LEFT JOIN bieu_gia bg ON bg.khu_tro_id = k.id
      ${dk.length ? 'WHERE ' + dk.join(' AND ') : ''}
      ORDER BY (p.trang_thai = 'TRONG') DESC, p.gia_thue, p.id
      LIMIT $${ts.length - 1} OFFSET $${ts.length}`,
    ts
  );
  if (r.rows[0]) res.set('X-Tong-So', String(r.rows[0].tong_so));
  res.json(r.rows);
}));

// GET /phong/:id - chi tiết phòng cho khách
router.get('/phong/:id', asyncHandler(async (req, res) => {
  const id = soNguyen(req.params.id, { min: 1, ten: 'Mã phòng' });
  const r = await truyVan(
    `SELECT p.*, k.ten AS ten_khu, k.dia_chi, k.phuong_xa, k.tien_ich,
            bg.gia_dien, bg.gia_nuoc, bg.phi_rac, bg.phi_gui_xe,
            ct.ho_ten AS ten_chu_tro, ct.sdt AS sdt_chu_tro
       FROM phong p
       JOIN khu_tro k ON k.id = p.khu_tro_id
       LEFT JOIN bieu_gia bg ON bg.khu_tro_id = k.id
       LEFT JOIN nguoi_dung ct ON ct.id = k.chu_tro_id
      WHERE p.id = $1`,
    [id]
  );
  if (!r.rows[0]) throw new LoiApi(404, 'Không tìm thấy phòng');
  res.json(r.rows[0]);
}));

// ---------------------------------------------------------------------
// LỊCH XEM PHÒNG
// ---------------------------------------------------------------------
router.post('/lich-xem-phong', xacThuc, choPhep('NGUOI_THUE'), asyncHandler(async (req, res) => {
  const b = req.body || {};
  const phongId = soNguyen(chon(b, 'phong_id', 'phongId'), { min: 1, ten: 'Mã phòng' });
  const thoiGian = chon(b, 'thoi_gian', 'thoiGian');
  const ngay = new Date(thoiGian);
  if (!thoiGian || Number.isNaN(ngay.getTime())) {
    throw new LoiApi(400, 'Thời gian xem phòng không hợp lệ');
  }
  if (ngay.getTime() <= Date.now()) {
    throw new LoiApi(400, 'Thời gian xem phòng phải ở tương lai');
  }

  const p = await truyVan('SELECT * FROM phong WHERE id = $1', [phongId]);
  const phong = p.rows[0];
  if (!phong) throw new LoiApi(404, 'Không tìm thấy phòng');
  if (phong.trang_thai !== 'TRONG') throw new LoiApi(409, 'Phòng này không còn trống để xem');

  const trung = await truyVan(
    `SELECT id FROM lich_xem_phong
      WHERE phong_id = $1 AND thoi_gian = $2 AND trang_thai <> 'TU_CHOI'`,
    [phongId, ngay.toISOString()]
  );
  if (trung.rows[0]) throw new LoiApi(409, 'Khung giờ này đã có người đặt lịch xem');

  const r = await truyVan(
    `INSERT INTO lich_xem_phong (phong_id, khach_id, thoi_gian, trang_thai)
     VALUES ($1, $2, $3, 'CHO_XAC_NHAN') RETURNING *`,
    [phongId, req.nguoiDung.id, ngay.toISOString()]
  );
  res.status(201).json({ ...r.rows[0], so_phong: phong.so_phong });
}));

router.get('/lich-xem-phong/cua-toi', xacThuc, choPhep('NGUOI_THUE'), asyncHandler(async (req, res) => {
  const r = await truyVan(
    `SELECT lx.*, p.so_phong, p.gia_thue, p.anh_url, k.ten AS ten_khu, k.dia_chi
       FROM lich_xem_phong lx
       JOIN phong p ON p.id = lx.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
      WHERE lx.khach_id = $1
      ORDER BY lx.thoi_gian DESC`,
    [req.nguoiDung.id]
  );
  res.json(r.rows);
}));

// DELETE /lich-xem-phong/:id - khách tự hủy lịch còn chờ xác nhận
router.delete('/lich-xem-phong/:id', xacThuc, choPhep('NGUOI_THUE'), asyncHandler(async (req, res) => {
  const id = soNguyen(req.params.id, { min: 1, ten: 'Mã lịch xem' });
  const r = await truyVan(
    `DELETE FROM lich_xem_phong
      WHERE id = $1 AND khach_id = $2 AND trang_thai = 'CHO_XAC_NHAN'
      RETURNING *`,
    [id, req.nguoiDung.id]
  );
  if (!r.rows[0]) throw new LoiApi(404, 'Không tìm thấy lịch xem đang chờ xác nhận của bạn');
  res.json({ da_huy: true, lich: r.rows[0] });
}));

// ---------------------------------------------------------------------
// HỢP ĐỒNG CỦA TÔI
// ---------------------------------------------------------------------
router.get('/hop-dong/cua-toi', xacThuc, choPhep('NGUOI_THUE'), asyncHandler(async (req, res) => {
  const dk = ['h.nguoi_thue_id = $1'];
  if (!['1', 'true'].includes(String(req.query.tatCa || '').toLowerCase())) {
    dk.push(`h.trang_thai = 'HIEU_LUC'`);
  }
  const r = await truyVan(
    `SELECT h.*, p.so_phong, p.dien_tich, p.gia_thue, p.anh_url,
            k.ten AS ten_khu, k.dia_chi, k.phuong_xa,
            ct.ho_ten AS ten_chu_tro, ct.sdt AS sdt_chu_tro,
            (h.ket_thuc - CURRENT_DATE)::int AS so_ngay_con_lai
       FROM hop_dong h
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
       JOIN nguoi_dung ct ON ct.id = k.chu_tro_id
      WHERE ${dk.join(' AND ')}
      ORDER BY (h.trang_thai = 'HIEU_LUC') DESC, h.bat_dau DESC`,
    [req.nguoiDung.id]
  );
  res.json(r.rows);
}));

// ---------------------------------------------------------------------
// HÓA ĐƠN CỦA TÔI (kèm chi tiết + chỉ số đầu - cuối kỳ)
// ---------------------------------------------------------------------
router.get('/hoa-don/cua-toi', xacThuc, choPhep('NGUOI_THUE'), asyncHandler(async (req, res) => {
  const dk = ['h.nguoi_thue_id = $1'];
  const ts = [req.nguoiDung.id];
  if (req.query.thang) {
    if (!laThang(req.query.thang)) throw new LoiApi(400, 'Tháng không hợp lệ (YYYY-MM)');
    ts.push(req.query.thang); dk.push(`hd.thang = $${ts.length}::char(7)`);
  }

  const r = await truyVan(
    `SELECT hd.*, ${TRANG_THAI_HOA_DON} AS trang_thai,
            p.id AS phong_id, p.so_phong, k.ten AS ten_khu,
            (hd.tong_tien - hd.da_thu)::int AS con_no,
            (CURRENT_DATE - hd.han_thanh_toan)::int AS so_ngay_qua_han,
            cs.dien_dau, cs.dien_cuoi, cs.nuoc_dau, cs.nuoc_cuoi,
            COALESCE((SELECT json_agg(ct ORDER BY ct.id)
                        FROM chi_tiet_hoa_don ct WHERE ct.hoa_don_id = hd.id), '[]'::json) AS chi_tiet,
            COALESCE((SELECT json_agg(tt ORDER BY tt.thoi_diem DESC)
                        FROM thanh_toan tt WHERE tt.hoa_don_id = hd.id), '[]'::json) AS thanh_toan
       FROM hoa_don hd
       JOIN hop_dong h ON h.id = hd.hop_dong_id
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
       LEFT JOIN chi_so_dien_nuoc cs ON cs.phong_id = p.id AND cs.thang = hd.thang
      WHERE ${dk.join(' AND ')}
      ORDER BY hd.thang DESC`,
    ts
  );
  res.json(r.rows);
}));

// ---------------------------------------------------------------------
// LỊCH SỬ THANH TOÁN + GỬI XÁC NHẬN CHUYỂN KHOẢN
// ---------------------------------------------------------------------
router.get('/thanh-toan/cua-toi', xacThuc, choPhep('NGUOI_THUE'), asyncHandler(async (req, res) => {
  const r = await truyVan(
    `SELECT tt.*, hd.thang, hd.tong_tien, hd.da_thu, p.so_phong, k.ten AS ten_khu,
            nd.ho_ten AS ten_nguoi_xac_nhan
       FROM thanh_toan tt
       JOIN hoa_don hd ON hd.id = tt.hoa_don_id
       JOIN hop_dong h ON h.id = hd.hop_dong_id
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
       LEFT JOIN nguoi_dung nd ON nd.id = tt.xac_nhan_boi
      WHERE h.nguoi_thue_id = $1
      ORDER BY tt.thoi_diem DESC`,
    [req.nguoiDung.id]
  );
  res.json(r.rows);
}));

// POST /thanh-toan - nhận JSON hoặc multipart (ảnh biên lai)
router.post('/thanh-toan', xacThuc, choPhep('NGUOI_THUE'), upAnh, asyncHandler(async (req, res) => {
  const b = req.body || {};
  const hoaDonId = soNguyen(chon(b, 'hoa_don_id', 'hoaDonId'), { min: 1, ten: 'Mã hóa đơn' });

  const q = await truyVan(
    `SELECT hd.*, h.nguoi_thue_id, p.so_phong, k.ten AS ten_khu
       FROM hoa_don hd
       JOIN hop_dong h ON h.id = hd.hop_dong_id
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
      WHERE hd.id = $1`,
    [hoaDonId]
  );
  const hoaDon = q.rows[0];
  if (!hoaDon) throw new LoiApi(404, 'Không tìm thấy hóa đơn');
  if (hoaDon.nguoi_thue_id !== req.nguoiDung.id) throw new LoiApi(403, 'Đây không phải hóa đơn của bạn');

  const conNo = hoaDon.tong_tien - hoaDon.da_thu;
  if (conNo <= 0) throw new LoiApi(409, 'Hóa đơn đã được thanh toán đủ');

  const choXacNhan = await truyVan(
    `SELECT id FROM thanh_toan WHERE hoa_don_id = $1 AND xac_nhan_boi IS NULL`,
    [hoaDonId]
  );
  if (choXacNhan.rows[0]) {
    throw new LoiApi(409, 'Hóa đơn đang có giao dịch chờ chủ trọ xác nhận');
  }

  const soTien = chon(b, 'so_tien', 'soTien') === undefined
    ? conNo
    : soNguyen(chon(b, 'so_tien', 'soTien'), { min: 1, ten: 'Số tiền' });
  if (soTien > conNo) throw new LoiApi(400, `Số tiền vượt quá còn nợ (${conNo} đồng)`);

  const hinhThuc = String(chon(b, 'hinh_thuc', 'hinhThuc') || 'CHUYEN_KHOAN').toUpperCase();
  if (!['TIEN_MAT', 'CHUYEN_KHOAN'].includes(hinhThuc)) {
    throw new LoiApi(400, 'Hình thức thanh toán không hợp lệ');
  }

  let anhUrl = chon(b, 'anh_bien_lai', 'anhBienLai') || null;
  const file = layFile(req);
  if (file) anhUrl = (await luuAnh(file, 'bien-lai')).url;
  if (hinhThuc === 'CHUYEN_KHOAN' && !anhUrl) {
    throw new LoiApi(400, 'Chuyển khoản phải kèm ảnh biên lai');
  }

  const r = await truyVan(
    `INSERT INTO thanh_toan (hoa_don_id, so_tien, hinh_thuc, anh_bien_lai, xac_nhan_boi)
     VALUES ($1, $2, $3, $4, NULL) RETURNING *`,
    [hoaDonId, soTien, hinhThuc, anhUrl]
  );
  res.status(201).json({
    thanh_toan: r.rows[0],
    hoa_don: { id: hoaDon.id, thang: hoaDon.thang, tong_tien: hoaDon.tong_tien, da_thu: hoaDon.da_thu, con_no: conNo },
    thong_diep: 'Đã gửi xác nhận, chờ chủ trọ kiểm tra biên lai',
  });
}));

// ---------------------------------------------------------------------
// BÁO SỰ CỐ
// ---------------------------------------------------------------------
router.post('/bao-su-co', xacThuc, choPhep('NGUOI_THUE'), upAnh, asyncHandler(async (req, res) => {
  const b = req.body || {};
  const phongId = soNguyen(chon(b, 'phong_id', 'phongId'), { min: 1, ten: 'Mã phòng' });
  const loai = chuoi(chon(b, 'loai'), { ten: 'Loại sự cố', max: 30 });
  const moTa = chuoi(chon(b, 'mo_ta', 'moTa'), { ten: 'Mô tả sự cố', max: 2000 });

  const q = await truyVan(
    `SELECT h.id FROM hop_dong h
      WHERE h.phong_id = $1 AND h.nguoi_thue_id = $2 AND h.trang_thai = 'HIEU_LUC'
      LIMIT 1`,
    [phongId, req.nguoiDung.id]
  );
  if (!q.rows[0]) throw new LoiApi(403, 'Bạn không có hợp đồng hiệu lực ở phòng này');

  let anhUrl = chon(b, 'anh_url', 'anhUrl') || null;
  const file = layFile(req);
  if (file) anhUrl = (await luuAnh(file, 'su-co')).url;

  const r = await truyVan(
    `INSERT INTO bao_su_co (phong_id, nguoi_bao_id, loai, mo_ta, anh_url, trang_thai)
     VALUES ($1, $2, $3, $4, $5, 'MOI') RETURNING *`,
    [phongId, req.nguoiDung.id, loai, moTa, anhUrl]
  );
  res.status(201).json(r.rows[0]);
}));

router.get('/bao-su-co/cua-toi', xacThuc, choPhep('NGUOI_THUE'), asyncHandler(async (req, res) => {
  const r = await truyVan(
    `SELECT bs.*, p.so_phong, k.ten AS ten_khu
       FROM bao_su_co bs
       JOIN phong p ON p.id = bs.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
      WHERE bs.nguoi_bao_id = $1
      ORDER BY bs.id DESC`,
    [req.nguoiDung.id]
  );
  res.json(r.rows);
}));

// ---------------------------------------------------------------------
// NHẮC HẠN: hóa đơn sắp đến hạn / quá hạn + hợp đồng sắp hết hạn
// ---------------------------------------------------------------------
router.get('/nhac-han', xacThuc, choPhep('NGUOI_THUE'), asyncHandler(async (req, res) => {
  const hoaDon = await truyVan(
    `SELECT hd.id, hd.thang, hd.tong_tien, hd.da_thu, hd.han_thanh_toan,
            ${TRANG_THAI_HOA_DON} AS trang_thai,
            (hd.tong_tien - hd.da_thu)::int AS con_no,
            (hd.han_thanh_toan - CURRENT_DATE)::int AS so_ngay_con_lai,
            p.so_phong, k.ten AS ten_khu
       FROM hoa_don hd
       JOIN hop_dong h ON h.id = hd.hop_dong_id
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
      WHERE h.nguoi_thue_id = $1
        AND hd.tong_tien > hd.da_thu
        AND hd.han_thanh_toan <= CURRENT_DATE + 7
      ORDER BY hd.han_thanh_toan`,
    [req.nguoiDung.id]
  );

  const hopDong = await truyVan(
    `SELECT h.id, h.phong_id, h.ket_thuc, p.so_phong, k.ten AS ten_khu,
            (h.ket_thuc - CURRENT_DATE)::int AS so_ngay_con_lai
       FROM hop_dong h
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
      WHERE h.nguoi_thue_id = $1
        AND h.trang_thai = 'HIEU_LUC'
        AND h.ket_thuc <= CURRENT_DATE + 30
      ORDER BY h.ket_thuc`,
    [req.nguoiDung.id]
  );

  res.json({ hoa_don: hoaDon.rows, hop_dong: hopDong.rows });
}));

// ---------------------------------------------------------------------
// UPLOAD ẢNH DÙNG CHUNG (biên lai, sự cố, ảnh phòng)
// ---------------------------------------------------------------------
router.post('/upload/anh', xacThuc, upAnh, asyncHandler(async (req, res) => {
  const file = layFile(req);
  if (!file) throw new LoiApi(400, 'Thiếu tệp ảnh (field: anh)');
  const kq = await luuAnh(file, 'khac');
  res.status(201).json(kq);
}));

module.exports = router;
