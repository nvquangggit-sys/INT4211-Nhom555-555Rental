const router = require('express').Router();
const { truyVan, trongGiaoDich } = require('../db');
const { xacThuc, choPhep } = require('../middleware/auth');
const { asyncHandler } = require('../utils/async');
const { LoiApi } = require('../utils/loi');
const { layKhu, layPhong, layHopDong } = require('../utils/quyen');
const {
  laNgay, laThang, soNguyen, soThuc, chuoi, thangTruoc,
} = require('../utils/kiem-tra');

const QUAN_LY = ['CHU_TRO', 'QUAN_LY'];

// Lấy giá trị body theo snake_case hoặc camelCase để app Android/Flutter
// gửi kiểu nào cũng nhận.
function chon(o, ...ten) {
  for (const k of ten) if (o && o[k] !== undefined && o[k] !== null) return o[k];
  return undefined;
}

function maTrangThai(v, ten, ds) {
  const s = chuoi(v, { ten, max: 20 });
  if (!ds.includes(s)) throw new LoiApi(400, `${ten} không hợp lệ (chỉ nhận ${ds.join(', ')})`);
  return s;
}

// ---------------------------------------------------------------------
// KHU TRỌ
// ---------------------------------------------------------------------
router.get('/khu-tro', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const chuTroId = req.nguoiDung.vaiTro === 'CHU_TRO' ? req.nguoiDung.id : null;
  const r = await truyVan(
    `SELECT k.*,
            bg.gia_dien, bg.gia_nuoc, bg.phi_rac, bg.phi_gui_xe,
            (SELECT count(*) FROM phong p WHERE p.khu_tro_id = k.id)::int AS so_phong,
            (SELECT count(*) FROM phong p WHERE p.khu_tro_id = k.id AND p.trang_thai = 'TRONG')::int AS so_phong_trong,
            (SELECT count(*) FROM phong p WHERE p.khu_tro_id = k.id AND p.trang_thai = 'DA_THUE')::int AS so_phong_da_thue
       FROM khu_tro k
       LEFT JOIN bieu_gia bg ON bg.khu_tro_id = k.id
      WHERE ($1::int IS NULL OR k.chu_tro_id = $1)
      ORDER BY k.id`,
    [chuTroId]
  );
  res.json(r.rows);
}));

router.get('/khu-tro/:id', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const id = soNguyen(req.params.id, { min: 1, ten: 'Mã khu trọ' });
  const khu = await layKhu(truyVan, id, req.nguoiDung);
  const r = await truyVan(
    `SELECT k.*, bg.gia_dien, bg.gia_nuoc, bg.phi_rac, bg.phi_gui_xe,
            (SELECT count(*) FROM phong p WHERE p.khu_tro_id = k.id)::int AS so_phong,
            (SELECT count(*) FROM phong p WHERE p.khu_tro_id = k.id AND p.trang_thai = 'TRONG')::int AS so_phong_trong
       FROM khu_tro k LEFT JOIN bieu_gia bg ON bg.khu_tro_id = k.id
      WHERE k.id = $1`,
    [khu.id]
  );
  res.json(r.rows[0]);
}));

// POST /khu-tro - tạo khu + biểu giá mặc định trong cùng transaction
router.post('/khu-tro', xacThuc, choPhep('CHU_TRO'), asyncHandler(async (req, res) => {
  const b = req.body || {};
  const ten = chuoi(chon(b, 'ten'), { ten: 'Tên khu trọ', max: 100 });
  const diaChi = chuoi(chon(b, 'dia_chi', 'diaChi'), { ten: 'Địa chỉ', max: 200 });
  const phuongXa = chuoi(chon(b, 'phuong_xa', 'phuongXa'), { ten: 'Phường/xã', max: 80 });
  const tienIch = chon(b, 'tien_ich', 'tienIch');
  const bgBody = chon(b, 'bieu_gia', 'bieuGia') || {};

  const giaDien = soNguyen(chon(bgBody, 'gia_dien', 'giaDien') ?? 3800, { min: 0, ten: 'Giá điện' });
  const giaNuoc = soNguyen(chon(bgBody, 'gia_nuoc', 'giaNuoc') ?? 18000, { min: 0, ten: 'Giá nước' });
  const phiRac = soNguyen(chon(bgBody, 'phi_rac', 'phiRac') ?? 30000, { min: 0, ten: 'Phí rác' });
  const phiGuiXe = soNguyen(chon(bgBody, 'phi_gui_xe', 'phiGuiXe') ?? 100000, { min: 0, ten: 'Phí gửi xe' });

  const ketQua = await trongGiaoDich(async (c) => {
    const kq = await c.query(
      `INSERT INTO khu_tro (ten, dia_chi, phuong_xa, chu_tro_id, tien_ich)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [ten, diaChi, phuongXa, req.nguoiDung.id,
        tienIch ? chuoi(tienIch, { ten: 'Tiện ích', max: 1000 }) : null]
    );
    const khu = kq.rows[0];
    const bg = await c.query(
      `INSERT INTO bieu_gia (khu_tro_id, gia_dien, gia_nuoc, phi_rac, phi_gui_xe)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [khu.id, giaDien, giaNuoc, phiRac, phiGuiXe]
    );
    return { ...khu, bieu_gia: bg.rows[0] };
  });
  res.status(201).json(ketQua);
}));

router.patch('/khu-tro/:id', xacThuc, choPhep('CHU_TRO'), asyncHandler(async (req, res) => {
  const id = soNguyen(req.params.id, { min: 1, ten: 'Mã khu trọ' });
  await layKhu(truyVan, id, req.nguoiDung);
  const b = req.body || {};

  const ten = chon(b, 'ten');
  const diaChi = chon(b, 'dia_chi', 'diaChi');
  const phuongXa = chon(b, 'phuong_xa', 'phuongXa');
  const tienIch = chon(b, 'tien_ich', 'tienIch');

  const r = await truyVan(
    `UPDATE khu_tro SET
       ten = COALESCE($1, ten),
       dia_chi = COALESCE($2, dia_chi),
       phuong_xa = COALESCE($3, phuong_xa),
       tien_ich = COALESCE($4, tien_ich)
     WHERE id = $5 RETURNING *`,
    [
      ten === undefined ? null : chuoi(ten, { ten: 'Tên khu trọ', max: 100 }),
      diaChi === undefined ? null : chuoi(diaChi, { ten: 'Địa chỉ', max: 200 }),
      phuongXa === undefined ? null : chuoi(phuongXa, { ten: 'Phường/xã', max: 80 }),
      tienIch === undefined ? null : chuoi(tienIch, { ten: 'Tiện ích', max: 1000 }),
      id,
    ]
  );
  res.json(r.rows[0]);
}));

router.delete('/khu-tro/:id', xacThuc, choPhep('CHU_TRO'), asyncHandler(async (req, res) => {
  const id = soNguyen(req.params.id, { min: 1, ten: 'Mã khu trọ' });
  await layKhu(truyVan, id, req.nguoiDung);

  const dem = await truyVan('SELECT count(*)::int AS n FROM phong WHERE khu_tro_id = $1', [id]);
  if (dem.rows[0].n > 0) {
    throw new LoiApi(409, `Không xóa được: khu còn ${dem.rows[0].n} phòng`);
  }
  await truyVan('DELETE FROM khu_tro WHERE id = $1', [id]);
  res.json({ da_xoa: true, id });
}));

// ---------------------------------------------------------------------
// PHÒNG (danh sách công khai nằm ở routes/khach.js)
// ---------------------------------------------------------------------
router.post('/phong', xacThuc, choPhep('CHU_TRO'), asyncHandler(async (req, res) => {
  const b = req.body || {};
  const khuTroId = soNguyen(chon(b, 'khu_tro_id', 'khuTroId'), { min: 1, ten: 'Mã khu trọ' });
  await layKhu(truyVan, khuTroId, req.nguoiDung);

  const soPhong = chuoi(chon(b, 'so_phong', 'soPhong'), { ten: 'Số phòng', max: 10 });
  const dienTich = soThuc(chon(b, 'dien_tich', 'dienTich'), { min: 0.1, ten: 'Diện tích' });
  const giaThue = soNguyen(chon(b, 'gia_thue', 'giaThue'), { min: 0, ten: 'Giá thuê' });
  const sucChua = soNguyen(chon(b, 'suc_chua', 'sucChua'), { min: 1, ten: 'Sức chứa' });
  const trangThai = chon(b, 'trang_thai', 'trangThai');
  const tt = trangThai === undefined ? 'TRONG' : maTrangThai(trangThai, 'Trạng thái phòng', ['TRONG', 'DA_THUE', 'DANG_SUA']);
  const anhUrl = chon(b, 'anh_url', 'anhUrl');

  try {
    const r = await truyVan(
      `INSERT INTO phong (khu_tro_id, so_phong, dien_tich, gia_thue, suc_chua, trang_thai, anh_url)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [khuTroId, soPhong, dienTich, giaThue, sucChua, tt,
        anhUrl ? chuoi(anhUrl, { ten: 'Ảnh phòng', max: 1000 }) : null]
    );
    res.status(201).json(r.rows[0]);
  } catch (e) {
    if (e.code === '23505') throw new LoiApi(409, 'Số phòng đã tồn tại trong khu này');
    throw e;
  }
}));

router.patch('/phong/:id', xacThuc, choPhep('CHU_TRO'), asyncHandler(async (req, res) => {
  const id = soNguyen(req.params.id, { min: 1, ten: 'Mã phòng' });
  const phong = await layPhong(truyVan, id, req.nguoiDung);
  const b = req.body || {};

  if (chon(b, 'khu_tro_id', 'khuTroId') !== undefined) {
    await layKhu(truyVan, soNguyen(chon(b, 'khu_tro_id', 'khuTroId'), { min: 1, ten: 'Mã khu trọ' }), req.nguoiDung);
  }

  const soPhong = chon(b, 'so_phong', 'soPhong');
  const dienTich = chon(b, 'dien_tich', 'dienTich');
  const giaThue = chon(b, 'gia_thue', 'giaThue');
  const sucChua = chon(b, 'suc_chua', 'sucChua');
  const trangThai = chon(b, 'trang_thai', 'trangThai');
  const anhUrl = chon(b, 'anh_url', 'anhUrl');

  try {
    const r = await truyVan(
      `UPDATE phong SET
         so_phong = COALESCE($1, so_phong),
         dien_tich = COALESCE($2, dien_tich),
         gia_thue = COALESCE($3, gia_thue),
         suc_chua = COALESCE($4, suc_chua),
         trang_thai = COALESCE($5, trang_thai),
         anh_url = COALESCE($6, anh_url)
       WHERE id = $7 RETURNING *`,
      [
        soPhong === undefined ? null : chuoi(soPhong, { ten: 'Số phòng', max: 10 }),
        dienTich === undefined ? null : soThuc(dienTich, { min: 0.1, ten: 'Diện tích' }),
        giaThue === undefined ? null : soNguyen(giaThue, { min: 0, ten: 'Giá thuê' }),
        sucChua === undefined ? null : soNguyen(sucChua, { min: 1, ten: 'Sức chứa' }),
        trangThai === undefined ? null : maTrangThai(trangThai, 'Trạng thái phòng', ['TRONG', 'DA_THUE', 'DANG_SUA']),
        anhUrl === undefined ? null : chuoi(anhUrl, { ten: 'Ảnh phòng', max: 1000 }),
        id,
      ]
    );
    res.json(r.rows[0]);
  } catch (e) {
    if (e.code === '23505') throw new LoiApi(409, 'Số phòng đã tồn tại trong khu này');
    throw e;
  }
}));

router.delete('/phong/:id', xacThuc, choPhep('CHU_TRO'), asyncHandler(async (req, res) => {
  const id = soNguyen(req.params.id, { min: 1, ten: 'Mã phòng' });
  await layPhong(truyVan, id, req.nguoiDung);

  const hd = await truyVan('SELECT count(*)::int AS n FROM hop_dong WHERE phong_id = $1', [id]);
  if (hd.rows[0].n > 0) throw new LoiApi(409, 'Không xóa được: phòng đã có hợp đồng');
  const cs = await truyVan('SELECT count(*)::int AS n FROM chi_so_dien_nuoc WHERE phong_id = $1', [id]);
  if (cs.rows[0].n > 0) throw new LoiApi(409, 'Không xóa được: phòng đã có lịch sử chỉ số điện nước');

  await truyVan('DELETE FROM phong WHERE id = $1', [id]);
  res.json({ da_xoa: true, id });
}));

// ---------------------------------------------------------------------
// HỢP ĐỒNG
// ---------------------------------------------------------------------
router.get('/hop-dong', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const dk = [];
  const ts = [];
  if (req.nguoiDung.vaiTro === 'CHU_TRO') { ts.push(req.nguoiDung.id); dk.push(`k.chu_tro_id = $${ts.length}`); }
  if (req.query.khuTro) { ts.push(soNguyen(req.query.khuTro, { min: 1, ten: 'Mã khu trọ' })); dk.push(`p.khu_tro_id = $${ts.length}`); }
  if (req.query.trangThai) { ts.push(maTrangThai(req.query.trangThai, 'Trạng thái hợp đồng', ['HIEU_LUC', 'HET_HAN', 'DA_HUY'])); dk.push(`h.trang_thai = $${ts.length}`); }
  if (req.query.q) { ts.push(`%${String(req.query.q).trim()}%`); dk.push(`(p.so_phong ILIKE $${ts.length} OR nd.ho_ten ILIKE $${ts.length})`); }

  const r = await truyVan(
    `SELECT h.*, p.so_phong, p.khu_tro_id, p.gia_thue, k.ten AS ten_khu,
            nd.ho_ten AS ten_nguoi_thue, nd.sdt AS sdt_nguoi_thue,
            (h.ket_thuc - CURRENT_DATE)::int AS so_ngay_con_lai
       FROM hop_dong h
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
       JOIN nguoi_dung nd ON nd.id = h.nguoi_thue_id
      ${dk.length ? 'WHERE ' + dk.join(' AND ') : ''}
      ORDER BY h.id DESC`,
    ts
  );
  res.json(r.rows);
}));

router.get('/hop-dong/:id', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const id = soNguyen(req.params.id, { min: 1, ten: 'Mã hợp đồng' });
  const hd = await layHopDong(truyVan, id, req.nguoiDung);
  res.json(hd);
}));

// POST /hop-dong - transaction: tạo hợp đồng + đổi phòng sang DA_THUE
router.post('/hop-dong', xacThuc, choPhep('CHU_TRO'), asyncHandler(async (req, res) => {
  const b = req.body || {};
  const phongId = soNguyen(chon(b, 'phong_id', 'phongId'), { min: 1, ten: 'Mã phòng' });
  const nguoiThueId = soNguyen(chon(b, 'nguoi_thue_id', 'nguoiThueId'), { min: 1, ten: 'Mã người thuê' });
  const batDau = chon(b, 'bat_dau', 'batDau');
  const ketThuc = chon(b, 'ket_thuc', 'ketThuc');
  const tienCoc = soNguyen(chon(b, 'tien_coc', 'tienCoc'), { min: 0, ten: 'Tiền cọc' });
  const soNguoi = soNguyen(chon(b, 'so_nguoi', 'soNguoi'), { min: 1, ten: 'Số người ở' });

  if (!laNgay(batDau)) throw new LoiApi(400, 'Ngày bắt đầu không hợp lệ (YYYY-MM-DD)');
  if (!laNgay(ketThuc)) throw new LoiApi(400, 'Ngày kết thúc không hợp lệ (YYYY-MM-DD)');
  if (ketThuc <= batDau) throw new LoiApi(400, 'Ngày kết thúc phải sau ngày bắt đầu');

  const ketQua = await trongGiaoDich(async (c) => {
    const p = await c.query(
      `SELECT p.*, k.chu_tro_id FROM phong p JOIN khu_tro k ON k.id = p.khu_tro_id
        WHERE p.id = $1 FOR UPDATE OF p`,
      [phongId]
    );
    const phong = p.rows[0];
    if (!phong) throw new LoiApi(404, 'Không tìm thấy phòng');
    if (phong.chu_tro_id !== req.nguoiDung.id) throw new LoiApi(403, 'Bạn không quản lý phòng này');
    if (phong.trang_thai !== 'TRONG') throw new LoiApi(409, 'Phòng không còn trống');
    if (soNguoi > phong.suc_chua) throw new LoiApi(400, `Số người ở vượt sức chứa (tối đa ${phong.suc_chua})`);

    const nt = await c.query(`SELECT id, vai_tro FROM nguoi_dung WHERE id = $1`, [nguoiThueId]);
    if (!nt.rows[0]) throw new LoiApi(404, 'Không tìm thấy người thuê');
    if (nt.rows[0].vai_tro !== 'NGUOI_THUE') throw new LoiApi(400, 'Tài khoản được chọn không phải người thuê');

    const dangThue = await c.query(
      `SELECT id FROM hop_dong WHERE phong_id = $1 AND trang_thai = 'HIEU_LUC' FOR UPDATE`,
      [phongId]
    );
    if (dangThue.rows[0]) throw new LoiApi(409, 'Phòng đang có hợp đồng hiệu lực');

    const hd = await c.query(
      `INSERT INTO hop_dong (phong_id, nguoi_thue_id, bat_dau, ket_thuc, tien_coc, so_nguoi, trang_thai)
       VALUES ($1, $2, $3, $4, $5, $6, 'HIEU_LUC') RETURNING *`,
      [phongId, nguoiThueId, batDau, ketThuc, tienCoc, soNguoi]
    );
    await c.query(`UPDATE phong SET trang_thai = 'DA_THUE' WHERE id = $1`, [phongId]);
    return { ...hd.rows[0], so_phong: phong.so_phong, ten_khu: null };
  });
  res.status(201).json(ketQua);
}));

// PATCH /hop-dong/:id - kết thúc / hủy hợp đồng, trả phòng về TRONG
router.patch('/hop-dong/:id', xacThuc, choPhep('CHU_TRO'), asyncHandler(async (req, res) => {
  const id = soNguyen(req.params.id, { min: 1, ten: 'Mã hợp đồng' });
  await layHopDong(truyVan, id, req.nguoiDung);
  const b = req.body || {};
  const trangThai = chon(b, 'trang_thai', 'trangThai');
  const ketThuc = chon(b, 'ket_thuc', 'ketThuc');

  if (trangThai === undefined && ketThuc === undefined) {
    throw new LoiApi(400, 'Cần truyền trang_thai hoặc ket_thuc');
  }
  if (trangThai !== undefined) maTrangThai(trangThai, 'Trạng thái hợp đồng', ['HIEU_LUC', 'HET_HAN', 'DA_HUY']);
  if (ketThuc !== undefined && !laNgay(ketThuc)) throw new LoiApi(400, 'Ngày kết thúc không hợp lệ');

  const ketQua = await trongGiaoDich(async (c) => {
    const hd = await c.query(
      `UPDATE hop_dong SET
         trang_thai = COALESCE($1, trang_thai),
         ket_thuc = COALESCE($2, ket_thuc)
       WHERE id = $3 RETURNING *`,
      [trangThai ?? null, ketThuc ?? null, id]
    );
    const moi = hd.rows[0];
    if (moi.trang_thai !== 'HIEU_LUC') {
      const conHd = await c.query(
        `SELECT count(*)::int AS n FROM hop_dong
          WHERE phong_id = $1 AND trang_thai = 'HIEU_LUC' AND id <> $2`,
        [moi.phong_id, id]
      );
      if (conHd.rows[0].n === 0) {
        await c.query(`UPDATE phong SET trang_thai = 'TRONG' WHERE id = $1`, [moi.phong_id]);
      }
    }
    return moi;
  });
  res.json(ketQua);
}));

// ---------------------------------------------------------------------
// BIỂU GIÁ
// ---------------------------------------------------------------------
router.get('/bieu-gia', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const chuTroId = req.nguoiDung.vaiTro === 'CHU_TRO' ? req.nguoiDung.id : null;
  const r = await truyVan(
    `SELECT bg.*, k.ten AS ten_khu, k.phuong_xa
       FROM bieu_gia bg JOIN khu_tro k ON k.id = bg.khu_tro_id
      WHERE ($1::int IS NULL OR k.chu_tro_id = $1)
      ORDER BY bg.khu_tro_id`,
    [chuTroId]
  );
  res.json(r.rows);
}));

router.get('/bieu-gia/:khuTroId', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const khuId = soNguyen(req.params.khuTroId, { min: 1, ten: 'Mã khu trọ' });
  await layKhu(truyVan, khuId, req.nguoiDung);
  const r = await truyVan('SELECT * FROM bieu_gia WHERE khu_tro_id = $1', [khuId]);
  if (!r.rows[0]) throw new LoiApi(404, 'Khu trọ chưa có biểu giá');
  res.json(r.rows[0]);
}));

// PATCH /bieu-gia/:khuTroId - chỉ CHU_TRO (QUAN_LY gọi sẽ bị 403)
router.patch('/bieu-gia/:khuTroId', xacThuc, choPhep('CHU_TRO'), asyncHandler(async (req, res) => {
  const khuId = soNguyen(req.params.khuTroId, { min: 1, ten: 'Mã khu trọ' });
  await layKhu(truyVan, khuId, req.nguoiDung);
  const b = req.body || {};

  const giaDien = chon(b, 'gia_dien', 'giaDien');
  const giaNuoc = chon(b, 'gia_nuoc', 'giaNuoc');
  const phiRac = chon(b, 'phi_rac', 'phiRac');
  const phiGuiXe = chon(b, 'phi_gui_xe', 'phiGuiXe');

  const r = await truyVan(
    `UPDATE bieu_gia SET
       gia_dien = COALESCE($1, gia_dien),
       gia_nuoc = COALESCE($2, gia_nuoc),
       phi_rac = COALESCE($3, phi_rac),
       phi_gui_xe = COALESCE($4, phi_gui_xe)
     WHERE khu_tro_id = $5 RETURNING *`,
    [
      giaDien === undefined ? null : soNguyen(giaDien, { min: 0, ten: 'Giá điện' }),
      giaNuoc === undefined ? null : soNguyen(giaNuoc, { min: 0, ten: 'Giá nước' }),
      phiRac === undefined ? null : soNguyen(phiRac, { min: 0, ten: 'Phí rác' }),
      phiGuiXe === undefined ? null : soNguyen(phiGuiXe, { min: 0, ten: 'Phí gửi xe' }),
      khuId,
    ]
  );
  res.json(r.rows[0]);
}));

// ---------------------------------------------------------------------
// CHỈ SỐ ĐIỆN NƯỚC
// ---------------------------------------------------------------------
router.get('/chi-so-dien-nuoc', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const dk = [];
  const ts = [];
  if (req.nguoiDung.vaiTro === 'CHU_TRO') { ts.push(req.nguoiDung.id); dk.push(`k.chu_tro_id = $${ts.length}`); }
  if (req.query.khuTro) { ts.push(soNguyen(req.query.khuTro, { min: 1, ten: 'Mã khu trọ' })); dk.push(`p.khu_tro_id = $${ts.length}`); }
  if (req.query.phong) { ts.push(soNguyen(req.query.phong, { min: 1, ten: 'Mã phòng' })); dk.push(`cs.phong_id = $${ts.length}`); }
  if (req.query.thang) {
    if (!laThang(req.query.thang)) throw new LoiApi(400, 'Tháng không hợp lệ (YYYY-MM)');
    ts.push(req.query.thang); dk.push(`cs.thang = $${ts.length}::char(7)`);
  }

  const r = await truyVan(
    `SELECT cs.*, p.so_phong, p.khu_tro_id, k.ten AS ten_khu,
            nd.ho_ten AS ten_nguoi_ghi,
            (cs.dien_cuoi - cs.dien_dau) AS tieu_thu_dien,
            (cs.nuoc_cuoi - cs.nuoc_dau) AS tieu_thu_nuoc
       FROM chi_so_dien_nuoc cs
       JOIN phong p ON p.id = cs.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
       JOIN nguoi_dung nd ON nd.id = cs.ghi_boi
      ${dk.length ? 'WHERE ' + dk.join(' AND ') : ''}
      ORDER BY cs.thang DESC, p.so_phong`,
    ts
  );
  res.json(r.rows);
}));

// POST /chi-so-dien-nuoc - ĐIỂM NHẤN 1:
// - tự lấy chỉ số đầu kỳ từ bản ghi gần nhất của phòng
// - chặn chỉ số cuối < đầu (400)
// - chặn ghi trùng tháng (409)
// - cảnh báo khi điện tiêu thụ > 150% trung bình 3 tháng trước
router.post('/chi-so-dien-nuoc', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const b = req.body || {};
  const phongId = soNguyen(chon(b, 'phong_id', 'phongId'), { min: 1, ten: 'Mã phòng' });
  const thang = chon(b, 'thang');
  if (!laThang(thang)) throw new LoiApi(400, 'Tháng không hợp lệ (YYYY-MM)');

  const dienCuoi = soNguyen(chon(b, 'dien_cuoi', 'dienCuoi'), { min: 0, ten: 'Chỉ số điện cuối' });
  const nuocCuoi = soNguyen(chon(b, 'nuoc_cuoi', 'nuocCuoi'), { min: 0, ten: 'Chỉ số nước cuối' });
  const dienDauBody = chon(b, 'dien_dau', 'dienDau');
  const nuocDauBody = chon(b, 'nuoc_dau', 'nuocDau');

  const ketQua = await trongGiaoDich(async (c) => {
    const q = (sql, p) => c.query(sql, p);
    const phong = await layPhong(q, phongId, req.nguoiDung);

    const trung = await q(
      'SELECT id FROM chi_so_dien_nuoc WHERE phong_id = $1 AND thang = $2::char(7)',
      [phongId, thang]
    );
    if (trung.rows[0]) throw new LoiApi(409, `Phòng ${phong.so_phong} đã ghi chỉ số tháng ${thang}`);

    // Bản ghi gần nhất trước tháng đang ghi -> chỉ số đầu kỳ
    const truoc = await q(
      `SELECT * FROM chi_so_dien_nuoc
        WHERE phong_id = $1 AND thang < $2::char(7)
        ORDER BY thang DESC LIMIT 1`,
      [phongId, thang]
    );
    const truocDo = truoc.rows[0];
    const dienDau = truocDo
      ? truocDo.dien_cuoi
      : soNguyen(dienDauBody ?? 0, { min: 0, ten: 'Chỉ số điện đầu' });
    const nuocDau = truocDo
      ? truocDo.nuoc_cuoi
      : soNguyen(nuocDauBody ?? 0, { min: 0, ten: 'Chỉ số nước đầu' });

    if (dienCuoi < dienDau) {
      throw new LoiApi(400,
        `Chỉ số điện cuối (${dienCuoi}) không được nhỏ hơn chỉ số đầu (${dienDau})`,
        { truong: 'dien_cuoi', dien_dau: dienDau, dien_cuoi: dienCuoi });
    }
    if (nuocCuoi < nuocDau) {
      throw new LoiApi(400,
        `Chỉ số nước cuối (${nuocCuoi}) không được nhỏ hơn chỉ số đầu (${nuocDau})`,
        { truong: 'nuoc_cuoi', nuoc_dau: nuocDau, nuoc_cuoi: nuocCuoi });
    }

    // Trung bình tối đa 3 tháng gần nhất trước tháng đang ghi
    const tb = await q(
      `SELECT count(*)::int AS so_thang,
              COALESCE(avg(dien_cuoi - dien_dau), 0)::numeric AS tb_dien
         FROM (SELECT dien_dau, dien_cuoi FROM chi_so_dien_nuoc
                WHERE phong_id = $1 AND thang < $2::char(7)
                ORDER BY thang DESC LIMIT 3) x`,
      [phongId, thang]
    );

    const r = await q(
      `INSERT INTO chi_so_dien_nuoc
         (phong_id, thang, dien_dau, dien_cuoi, nuoc_dau, nuoc_cuoi, ghi_boi)
       VALUES ($1, $2::char(7), $3, $4, $5, $6, $7)
       RETURNING *`,
      [phongId, thang, dienDau, dienCuoi, nuocDau, nuocCuoi, req.nguoiDung.id]
    );

    const chiSo = {
      ...r.rows[0],
      so_phong: phong.so_phong,
      tieu_thu_dien: dienCuoi - dienDau,
      tieu_thu_nuoc: nuocCuoi - nuocDau,
    };

    let canhBao = null;
    const soThangTruoc = tb.rows[0].so_thang;
    const tbDien = Number(tb.rows[0].tb_dien);
    const hienTai = dienCuoi - dienDau;
    if (soThangTruoc > 0 && tbDien > 0 && hienTai > tbDien * 1.5) {
      canhBao = {
        loai: 'DIEN_TANG_VOT',
        thong_diep: `Điện tháng ${thang} tăng ${Math.round((hienTai / tbDien - 1) * 100)}% so với trung bình 3 tháng trước`,
        tieu_thu_hien_tai: hienTai,
        trung_binh_3_thang: Math.round(tbDien * 10) / 10,
        phan_tram_tang: Math.round((hienTai / tbDien - 1) * 1000) / 10,
      };
    }

    return { chi_so: chiSo, canh_bao: canhBao };
  });

  res.status(201).json(ketQua);
}));

// ---------------------------------------------------------------------
// HÓA ĐƠN
// ---------------------------------------------------------------------
router.get('/hoa-don', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const dk = [];
  const ts = [];
  if (req.nguoiDung.vaiTro === 'CHU_TRO') { ts.push(req.nguoiDung.id); dk.push(`k.chu_tro_id = $${ts.length}`); }
  if (req.query.khuTro) { ts.push(soNguyen(req.query.khuTro, { min: 1, ten: 'Mã khu trọ' })); dk.push(`p.khu_tro_id = $${ts.length}`); }
  if (req.query.thang) {
    if (!laThang(req.query.thang)) throw new LoiApi(400, 'Tháng không hợp lệ (YYYY-MM)');
    ts.push(req.query.thang); dk.push(`hd.thang = $${ts.length}::char(7)`);
  }
  if (req.query.trangThai) {
    ts.push(maTrangThai(req.query.trangThai, 'Trạng thái hóa đơn', ['CHUA_THU', 'MOT_PHAN', 'DA_THU', 'QUA_HAN']));
    dk.push(`hd.trang_thai = $${ts.length}`);
  }
  if (req.query.quaHan !== undefined) {
    const ngay = soNguyen(req.query.quaHan, { min: 0, max: 3650, ten: 'Số ngày quá hạn' });
    ts.push(ngay);
    dk.push(`hd.han_thanh_toan < CURRENT_DATE - $${ts.length}::int AND hd.tong_tien > hd.da_thu`);
  }

  const r = await truyVan(
    `SELECT hd.*, h.id AS hop_dong_id, p.so_phong, p.khu_tro_id, k.ten AS ten_khu,
            nd.ho_ten AS ten_nguoi_thue, nd.sdt AS sdt_nguoi_thue,
            p.gia_thue,
            (hd.tong_tien - hd.da_thu) AS con_no,
            (CURRENT_DATE - hd.han_thanh_toan)::int AS so_ngay_qua_han
       FROM hoa_don hd
       JOIN hop_dong h ON h.id = hd.hop_dong_id
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
       JOIN nguoi_dung nd ON nd.id = h.nguoi_thue_id
      ${dk.length ? 'WHERE ' + dk.join(' AND ') : ''}
      ORDER BY hd.thang DESC, p.so_phong`,
    ts
  );
  res.json(r.rows);
}));

// POST /hoa-don/phat-hanh - ĐIỂM NHẤN 2: phát hành hàng loạt trong 1 transaction
router.post('/hoa-don/phat-hanh', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const thang = req.query.thang || (req.body && req.body.thang);
  if (!laThang(thang)) throw new LoiApi(400, 'Thiếu hoặc sai tham số thang (YYYY-MM)');
  const khuTroId = soNguyen(req.query.khuTro || (req.body && req.body.khuTro), { min: 1, ten: 'Mã khu trọ' });
  await layKhu(truyVan, khuTroId, req.nguoiDung);

  const ketQua = await trongGiaoDich(async (c) => {
    const bg = await c.query('SELECT * FROM bieu_gia WHERE khu_tro_id = $1', [khuTroId]);
    const bieuGia = bg.rows[0];
    if (!bieuGia) throw new LoiApi(400, 'Khu trọ chưa có biểu giá, không thể phát hành hóa đơn');

    const ds = await c.query(
      `SELECT h.id AS hop_dong_id, h.phong_id, p.so_phong, p.gia_thue, p.khu_tro_id,
              cs.dien_dau, cs.dien_cuoi, cs.nuoc_dau, cs.nuoc_cuoi,
              hd.id AS hoa_don_id
         FROM hop_dong h
         JOIN phong p ON p.id = h.phong_id
         LEFT JOIN chi_so_dien_nuoc cs
                ON cs.phong_id = p.id AND cs.thang = $2::char(7)
         LEFT JOIN hoa_don hd
                ON hd.hop_dong_id = h.id AND hd.thang = $2::char(7)
        WHERE p.khu_tro_id = $1
          AND h.trang_thai = 'HIEU_LUC'
          AND h.bat_dau <= (to_date($2, 'YYYY-MM') + interval '1 month' - interval '1 day')::date
          AND h.ket_thuc >= to_date($2, 'YYYY-MM')
        ORDER BY p.so_phong`,
      [khuTroId, thang]
    );

    const boQua = [];
    const thieuChiSo = [];
    const canhBao = [];
    const daTao = [];
    let tongTien = 0;

    for (const h of ds.rows) {
      if (h.hoa_don_id) {
        boQua.push({ phong_id: h.phong_id, so_phong: h.so_phong, ly_do: 'Đã có hóa đơn tháng này' });
        continue;
      }
      if (h.dien_cuoi === null || h.nuoc_cuoi === null) {
        thieuChiSo.push({ phong_id: h.phong_id, so_phong: h.so_phong });
        continue;
      }

      const dienTieuThu = h.dien_cuoi - h.dien_dau;
      const nuocTieuThu = h.nuoc_cuoi - h.nuoc_dau;
      const tienDien = dienTieuThu * bieuGia.gia_dien;
      const tienNuoc = nuocTieuThu * bieuGia.gia_nuoc;
      const tong = h.gia_thue + tienDien + tienNuoc + bieuGia.phi_rac + bieuGia.phi_gui_xe;

      const hd = await c.query(
        `INSERT INTO hoa_don (hop_dong_id, thang, tong_tien, da_thu, han_thanh_toan, trang_thai)
         VALUES ($1, $2::char(7), $3, 0,
                 (to_date($2, 'YYYY-MM') + interval '1 month' + interval '9 days')::date,
                 'CHUA_THU')
         RETURNING *`,
        [h.hop_dong_id, thang, tong]
      );
      const hoaDon = hd.rows[0];

      await c.query(
        `INSERT INTO chi_tiet_hoa_don
           (hoa_don_id, ten_khoan, so_luong, don_gia, thanh_tien)
         VALUES
           ($1, 'Tiền phòng', 1, $2, $2),
           ($1, 'Tiền điện', $3, $4, $5),
           ($1, 'Tiền nước', $6, $7, $8),
           ($1, 'Phí rác', 1, $9, $9),
           ($1, 'Phí gửi xe', 1, $10, $10)`,
        [
          hoaDon.id,
          h.gia_thue,
          dienTieuThu, bieuGia.gia_dien, tienDien,
          nuocTieuThu, bieuGia.gia_nuoc, tienNuoc,
          bieuGia.phi_rac, bieuGia.phi_gui_xe,
        ]
      );

      // Cảnh báo bất thường: so với trung bình tối đa 3 tháng trước
      const tb = await c.query(
        `SELECT count(*)::int AS so_thang,
                COALESCE(avg(dien_cuoi - dien_dau), 0)::numeric AS tb_dien
           FROM (SELECT dien_dau, dien_cuoi FROM chi_so_dien_nuoc
                  WHERE phong_id = $1 AND thang < $2::char(7)
                  ORDER BY thang DESC LIMIT 3) x`,
        [h.phong_id, thang]
      );
      const tbDien = Number(tb.rows[0].tb_dien);
      if (tb.rows[0].so_thang > 0 && tbDien > 0 && dienTieuThu > tbDien * 1.5) {
        canhBao.push({
          phong_id: h.phong_id,
          so_phong: h.so_phong,
          tieu_thu_dien: dienTieuThu,
          trung_binh_3_thang: Math.round(tbDien * 10) / 10,
          phan_tram_tang: Math.round((dienTieuThu / tbDien - 1) * 1000) / 10,
        });
      }

      tongTien += tong;
      daTao.push({
        hoa_don_id: hoaDon.id,
        phong_id: h.phong_id,
        so_phong: h.so_phong,
        tong_tien: tong,
        han_thanh_toan: hoaDon.han_thanh_toan,
      });
    }

    return {
      thang,
      khu_tro_id: khuTroId,
      so_hoa_don_da_tao: daTao.length,
      tong_tien: tongTien,
      da_tao: daTao,
      bo_qua: boQua,
      thieu_chi_so: thieuChiSo,
      canh_bao_bat_thuong: canhBao,
    };
  });

  res.status(201).json(ketQua);
}));

// GET /hoa-don/:id - chi tiết hóa đơn (chủ trọ/quản lý hoặc chính người thuê)
router.get('/hoa-don/:id', xacThuc, asyncHandler(async (req, res) => {
  const id = soNguyen(req.params.id, { min: 1, ten: 'Mã hóa đơn' });
  const hd = await truyVan(
    `SELECT hd.*, h.id AS hop_dong_id, h.nguoi_thue_id, p.id AS phong_id, p.so_phong, p.khu_tro_id,
            p.gia_thue, k.ten AS ten_khu, k.chu_tro_id,
            nd.ho_ten AS ten_nguoi_thue, nd.sdt AS sdt_nguoi_thue,
            (hd.tong_tien - hd.da_thu) AS con_no
       FROM hoa_don hd
       JOIN hop_dong h ON h.id = hd.hop_dong_id
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
       JOIN nguoi_dung nd ON nd.id = h.nguoi_thue_id
      WHERE hd.id = $1`,
    [id]
  );
  const hoaDon = hd.rows[0];
  if (!hoaDon) throw new LoiApi(404, 'Không tìm thấy hóa đơn');

  if (req.nguoiDung.vaiTro === 'CHU_TRO' && hoaDon.chu_tro_id !== req.nguoiDung.id) {
    throw new LoiApi(403, 'Bạn không quản lý hóa đơn này');
  }
  if (req.nguoiDung.vaiTro === 'NGUOI_THUE' && hoaDon.nguoi_thue_id !== req.nguoiDung.id) {
    throw new LoiApi(403, 'Đây không phải hóa đơn của bạn');
  }

  const [chiTiet, chiSo, thanhToan] = await Promise.all([
    truyVan('SELECT * FROM chi_tiet_hoa_don WHERE hoa_don_id = $1 ORDER BY id', [id]),
    truyVan(
      `SELECT * FROM chi_so_dien_nuoc WHERE phong_id = $1 AND thang = $2::char(7)`,
      [hoaDon.phong_id, hoaDon.thang]
    ),
    truyVan('SELECT * FROM thanh_toan WHERE hoa_don_id = $1 ORDER BY thoi_diem DESC', [id]),
  ]);

  res.json({ ...hoaDon, chi_tiet: chiTiet.rows, chi_so: chiSo.rows[0] || null, thanh_toan: thanhToan.rows });
}));

// ---------------------------------------------------------------------
// THANH TOÁN
// ---------------------------------------------------------------------
router.get('/thanh-toan', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const dk = [];
  const ts = [];
  if (req.nguoiDung.vaiTro === 'CHU_TRO') { ts.push(req.nguoiDung.id); dk.push(`k.chu_tro_id = $${ts.length}`); }
  if (req.query.hoaDon) { ts.push(soNguyen(req.query.hoaDon, { min: 1, ten: 'Mã hóa đơn' })); dk.push(`tt.hoa_don_id = $${ts.length}`); }
  if (req.query.khuTro) { ts.push(soNguyen(req.query.khuTro, { min: 1, ten: 'Mã khu trọ' })); dk.push(`p.khu_tro_id = $${ts.length}`); }

  const r = await truyVan(
    `SELECT tt.*, hd.thang, hd.tong_tien, hd.da_thu, p.so_phong, k.ten AS ten_khu,
            nd.ho_ten AS ten_nguoi_thue, xac.ho_ten AS ten_nguoi_xac_nhan
       FROM thanh_toan tt
       JOIN hoa_don hd ON hd.id = tt.hoa_don_id
       JOIN hop_dong h ON h.id = hd.hop_dong_id
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
       JOIN nguoi_dung nd ON nd.id = h.nguoi_thue_id
       LEFT JOIN nguoi_dung xac ON xac.id = tt.xac_nhan_boi
      ${dk.length ? 'WHERE ' + dk.join(' AND ') : ''}
      ORDER BY tt.xac_nhan_boi IS NULL DESC, tt.thoi_diem DESC`,
    ts
  );
  res.json(r.rows);
}));

// PATCH /thanh-toan/:id/xac-nhan - transaction: xác nhận + cộng vào hóa đơn
router.patch('/thanh-toan/:id/xac-nhan', xacThuc, choPhep('CHU_TRO'), asyncHandler(async (req, res) => {
  const id = soNguyen(req.params.id, { min: 1, ten: 'Mã thanh toán' });

  const ketQua = await trongGiaoDich(async (c) => {
    const q = await c.query(
      `SELECT tt.*, hd.tong_tien, hd.da_thu, hd.trang_thai AS trang_thai_hoa_don,
              k.chu_tro_id
         FROM thanh_toan tt
         JOIN hoa_don hd ON hd.id = tt.hoa_don_id
         JOIN hop_dong h ON h.id = hd.hop_dong_id
         JOIN phong p ON p.id = h.phong_id
         JOIN khu_tro k ON k.id = p.khu_tro_id
        WHERE tt.id = $1
        FOR UPDATE OF tt, hd`,
      [id]
    );
    const tt = q.rows[0];
    if (!tt) throw new LoiApi(404, 'Không tìm thấy giao dịch thanh toán');
    if (tt.chu_tro_id !== req.nguoiDung.id) throw new LoiApi(403, 'Bạn không quản lý hóa đơn này');
    if (tt.xac_nhan_boi) throw new LoiApi(409, 'Giao dịch này đã được xác nhận trước đó');

    const conNo = tt.tong_tien - tt.da_thu;
    if (tt.so_tien > conNo) throw new LoiApi(400, `Số tiền vượt quá công nợ còn lại (${conNo} đồng)`);

    const capNhatTt = await c.query(
      `UPDATE thanh_toan SET xac_nhan_boi = $1 WHERE id = $2 RETURNING *`,
      [req.nguoiDung.id, id]
    );
    const moiDaThu = tt.da_thu + tt.so_tien;
    const capNhatHd = await c.query(
      `UPDATE hoa_don SET
         da_thu = $1,
         trang_thai = CASE WHEN $1 >= tong_tien THEN 'DA_THU' ELSE 'MOT_PHAN' END
       WHERE id = $2 RETURNING *`,
      [moiDaThu, tt.hoa_don_id]
    );
    return { thanh_toan: capNhatTt.rows[0], hoa_don: capNhatHd.rows[0] };
  });

  res.json(ketQua);
}));

// ---------------------------------------------------------------------
// LỊCH XEM PHÒNG (Admin xác nhận / từ chối)
// ---------------------------------------------------------------------
router.get('/lich-xem-phong', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const dk = [];
  const ts = [];
  if (req.nguoiDung.vaiTro === 'CHU_TRO') { ts.push(req.nguoiDung.id); dk.push(`k.chu_tro_id = $${ts.length}`); }
  if (req.query.khuTro) { ts.push(soNguyen(req.query.khuTro, { min: 1, ten: 'Mã khu trọ' })); dk.push(`p.khu_tro_id = $${ts.length}`); }
  if (req.query.trangThai) {
    ts.push(maTrangThai(req.query.trangThai, 'Trạng thái lịch xem', ['CHO_XAC_NHAN', 'DA_XAC_NHAN', 'TU_CHOI']));
    dk.push(`lx.trang_thai = $${ts.length}`);
  }

  const r = await truyVan(
    `SELECT lx.*, p.so_phong, p.khu_tro_id, k.ten AS ten_khu,
            nd.ho_ten AS ten_khach, nd.sdt AS sdt_khach, nd.email AS email_khach
       FROM lich_xem_phong lx
       JOIN phong p ON p.id = lx.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
       JOIN nguoi_dung nd ON nd.id = lx.khach_id
      ${dk.length ? 'WHERE ' + dk.join(' AND ') : ''}
      ORDER BY lx.trang_thai = 'CHO_XAC_NHAN' DESC, lx.thoi_gian`,
    ts
  );
  res.json(r.rows);
}));

router.patch('/lich-xem-phong/:id', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const id = soNguyen(req.params.id, { min: 1, ten: 'Mã lịch xem' });
  const trangThai = maTrangThai(chon(req.body || {}, 'trang_thai', 'trangThai'),
    'Trạng thái lịch xem', ['DA_XAC_NHAN', 'TU_CHOI']);

  const q = await truyVan(
    `SELECT lx.*, p.khu_tro_id, k.chu_tro_id
       FROM lich_xem_phong lx
       JOIN phong p ON p.id = lx.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
      WHERE lx.id = $1`,
    [id]
  );
  const lich = q.rows[0];
  if (!lich) throw new LoiApi(404, 'Không tìm thấy lịch xem phòng');
  if (req.nguoiDung.vaiTro === 'CHU_TRO' && lich.chu_tro_id !== req.nguoiDung.id) {
    throw new LoiApi(403, 'Bạn không quản lý lịch xem này');
  }

  const r = await truyVan(
    `UPDATE lich_xem_phong SET trang_thai = $1 WHERE id = $2 RETURNING *`,
    [trangThai, id]
  );
  res.json(r.rows[0]);
}));

// ---------------------------------------------------------------------
// NGƯỜI DÙNG (chọn người thuê khi tạo hợp đồng)
// ---------------------------------------------------------------------
router.get('/nguoi-dung', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const dk = [];
  const ts = [];
  if (req.query.vaiTro) {
    ts.push(maTrangThai(req.query.vaiTro, 'Vai trò', ['CHU_TRO', 'QUAN_LY', 'NGUOI_THUE']));
    dk.push(`vai_tro = $${ts.length}`);
  }
  if (req.query.q) {
    ts.push(`%${String(req.query.q).trim()}%`);
    dk.push(`(ho_ten ILIKE $${ts.length} OR email ILIKE $${ts.length} OR sdt ILIKE $${ts.length})`);
  }
  ts.push(200);

  const r = await truyVan(
    `SELECT id, email, ho_ten, sdt, cccd, vai_tro
       FROM nguoi_dung
      ${dk.length ? 'WHERE ' + dk.join(' AND ') : ''}
      ORDER BY ho_ten
      LIMIT $${ts.length}`,
    ts
  );
  res.json(r.rows);
}));

// ---------------------------------------------------------------------
// BÁO SỰ CỐ
// ---------------------------------------------------------------------
router.get('/bao-su-co', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const dk = [];
  const ts = [];
  if (req.nguoiDung.vaiTro === 'CHU_TRO') { ts.push(req.nguoiDung.id); dk.push(`k.chu_tro_id = $${ts.length}`); }
  if (req.query.khuTro) { ts.push(soNguyen(req.query.khuTro, { min: 1, ten: 'Mã khu trọ' })); dk.push(`p.khu_tro_id = $${ts.length}`); }
  if (req.query.trangThai) {
    ts.push(maTrangThai(req.query.trangThai, 'Trạng thái sự cố', ['MOI', 'DANG_XU_LY', 'DA_XU_LY']));
    dk.push(`bs.trang_thai = $${ts.length}`);
  }

  const r = await truyVan(
    `SELECT bs.*, p.so_phong, p.khu_tro_id, k.ten AS ten_khu,
            nd.ho_ten AS ten_nguoi_bao, nd.sdt AS sdt_nguoi_bao
       FROM bao_su_co bs
       JOIN phong p ON p.id = bs.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
       JOIN nguoi_dung nd ON nd.id = bs.nguoi_bao_id
      ${dk.length ? 'WHERE ' + dk.join(' AND ') : ''}
      ORDER BY bs.trang_thai = 'MOI' DESC, bs.id DESC`,
    ts
  );
  res.json(r.rows);
}));

router.patch('/bao-su-co/:id', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const id = soNguyen(req.params.id, { min: 1, ten: 'Mã sự cố' });
  const trangThai = maTrangThai(chon(req.body || {}, 'trang_thai', 'trangThai'),
    'Trạng thái sự cố', ['MOI', 'DANG_XU_LY', 'DA_XU_LY']);

  const q = await truyVan(
    `SELECT bs.*, p.khu_tro_id, k.chu_tro_id
       FROM bao_su_co bs
       JOIN phong p ON p.id = bs.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
      WHERE bs.id = $1`,
    [id]
  );
  const suCo = q.rows[0];
  if (!suCo) throw new LoiApi(404, 'Không tìm thấy sự cố');
  if (req.nguoiDung.vaiTro === 'CHU_TRO' && suCo.chu_tro_id !== req.nguoiDung.id) {
    throw new LoiApi(403, 'Bạn không quản lý sự cố này');
  }

  const r = await truyVan(
    `UPDATE bao_su_co SET
       trang_thai = $1::varchar,
       xu_ly_luc = CASE WHEN $1::varchar = 'DA_XU_LY' THEN now() ELSE NULL END
     WHERE id = $2 RETURNING *`,
    [trangThai, id]
  );
  res.json(r.rows[0]);
}));

// ---------------------------------------------------------------------
// BÁO CÁO
// ---------------------------------------------------------------------
router.get('/bao-cao/cong-no', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const dk = [];
  const ts = [];
  if (req.nguoiDung.vaiTro === 'CHU_TRO') { ts.push(req.nguoiDung.id); dk.push(`k.chu_tro_id = $${ts.length}`); }
  if (req.query.khuTro) {
    const khuId = soNguyen(req.query.khuTro, { min: 1, ten: 'Mã khu trọ' });
    await layKhu(truyVan, khuId, req.nguoiDung);
    ts.push(khuId); dk.push(`p.khu_tro_id = $${ts.length}`);
  }
  if (req.query.thang) {
    if (!laThang(req.query.thang)) throw new LoiApi(400, 'Tháng không hợp lệ (YYYY-MM)');
    ts.push(req.query.thang); dk.push(`hd.thang = $${ts.length}::char(7)`);
  }
  dk.push('hd.tong_tien > hd.da_thu');

  const tongHop = await truyVan(
    `SELECT k.id AS khu_tro_id, k.ten AS ten_khu,
            count(*)::int AS so_hoa_don,
            COALESCE(sum(hd.tong_tien - hd.da_thu), 0)::int AS tong_con_no,
            COALESCE(sum(CASE WHEN hd.han_thanh_toan < CURRENT_DATE - 10
                              THEN hd.tong_tien - hd.da_thu ELSE 0 END), 0)::int AS no_qua_10_ngay
       FROM hoa_don hd
       JOIN hop_dong h ON h.id = hd.hop_dong_id
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
      WHERE ${dk.join(' AND ')}
      GROUP BY k.id, k.ten
      ORDER BY tong_con_no DESC`,
    ts
  );

  const chiTiet = await truyVan(
    `SELECT hd.id, hd.thang, hd.tong_tien, hd.da_thu, hd.han_thanh_toan, hd.trang_thai,
            (hd.tong_tien - hd.da_thu)::int AS con_no,
            (CURRENT_DATE - hd.han_thanh_toan)::int AS so_ngay_qua_han,
            p.so_phong, k.ten AS ten_khu, nd.ho_ten AS ten_nguoi_thue, nd.sdt
       FROM hoa_don hd
       JOIN hop_dong h ON h.id = hd.hop_dong_id
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
       JOIN nguoi_dung nd ON nd.id = h.nguoi_thue_id
      WHERE ${dk.join(' AND ')}
      ORDER BY (CURRENT_DATE - hd.han_thanh_toan) DESC, hd.id`,
    ts
  );

  res.json({
    tong_hop: tongHop.rows,
    chi_tiet: chiTiet.rows,
    so_hoa_don_no: chiTiet.rows.length,
    tong_con_no: chiTiet.rows.reduce((s, x) => s + Number(x.con_no || 0), 0),
  });
}));

router.get('/bao-cao/lap-day', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const dk = [];
  const ts = [];
  if (req.nguoiDung.vaiTro === 'CHU_TRO') { ts.push(req.nguoiDung.id); dk.push(`k.chu_tro_id = $${ts.length}`); }
  if (req.query.khuTro) { ts.push(soNguyen(req.query.khuTro, { min: 1, ten: 'Mã khu trọ' })); dk.push(`k.id = $${ts.length}`); }

  const r = await truyVan(
    `SELECT k.id AS khu_tro_id, k.ten AS ten_khu,
            count(p.id)::int AS tong_phong,
            count(*) FILTER (WHERE p.trang_thai = 'TRONG')::int AS phong_trong,
            count(*) FILTER (WHERE p.trang_thai = 'DA_THUE')::int AS phong_da_thue,
            count(*) FILTER (WHERE p.trang_thai = 'DANG_SUA')::int AS phong_dang_sua,
            CASE WHEN count(p.id) = 0 THEN 0
                 ELSE round(100.0 * count(*) FILTER (WHERE p.trang_thai = 'DA_THUE') / count(p.id), 1)
            END AS ty_le_lap_day
       FROM khu_tro k
       LEFT JOIN phong p ON p.khu_tro_id = k.id
      ${dk.length ? 'WHERE ' + dk.join(' AND ') : ''}
      GROUP BY k.id, k.ten
      ORDER BY k.id`,
    ts
  );
  res.json(r.rows);
}));

// Chỉ CHU_TRO được xem doanh thu (QUAN_LY gọi -> 403)
router.get('/bao-cao/doanh-thu', xacThuc, choPhep('CHU_TRO'), asyncHandler(async (req, res) => {
  const dk = [];
  const ts = [req.nguoiDung.id];
  dk.push(`k.chu_tro_id = $1`);
  if (req.query.khuTro) { ts.push(soNguyen(req.query.khuTro, { min: 1, ten: 'Mã khu trọ' })); dk.push(`p.khu_tro_id = $${ts.length}`); }
  if (req.query.tuThang) {
    if (!laThang(req.query.tuThang)) throw new LoiApi(400, 'tuThang không hợp lệ (YYYY-MM)');
    ts.push(req.query.tuThang); dk.push(`hd.thang >= $${ts.length}::char(7)`);
  }
  if (req.query.denThang) {
    if (!laThang(req.query.denThang)) throw new LoiApi(400, 'denThang không hợp lệ (YYYY-MM)');
    ts.push(req.query.denThang); dk.push(`hd.thang <= $${ts.length}::char(7)`);
  }

  const theoKhu = await truyVan(
    `SELECT k.id AS khu_tro_id, k.ten AS ten_khu,
            COALESCE(sum(hd.tong_tien), 0)::int AS phai_thu,
            COALESCE(sum(hd.da_thu), 0)::int AS da_thu,
            COALESCE(sum(hd.tong_tien - hd.da_thu), 0)::int AS con_no,
            count(*)::int AS so_hoa_don
       FROM hoa_don hd
       JOIN hop_dong h ON h.id = hd.hop_dong_id
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
      WHERE ${dk.join(' AND ')}
      GROUP BY k.id, k.ten ORDER BY k.id`,
    ts
  );

  const theoThang = await truyVan(
    `SELECT hd.thang,
            COALESCE(sum(hd.tong_tien), 0)::int AS phai_thu,
            COALESCE(sum(hd.da_thu), 0)::int AS da_thu,
            COALESCE(sum(hd.tong_tien - hd.da_thu), 0)::int AS con_no,
            count(*)::int AS so_hoa_don
       FROM hoa_don hd
       JOIN hop_dong h ON h.id = hd.hop_dong_id
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
      WHERE ${dk.join(' AND ')}
      GROUP BY hd.thang ORDER BY hd.thang`,
    ts
  );

  res.json({
    theo_khu: theoKhu.rows,
    theo_thang: theoThang.rows,
    tong: {
      phai_thu: theoKhu.rows.reduce((s, x) => s + Number(x.phai_thu || 0), 0),
      da_thu: theoKhu.rows.reduce((s, x) => s + Number(x.da_thu || 0), 0),
      con_no: theoKhu.rows.reduce((s, x) => s + Number(x.con_no || 0), 0),
      so_hoa_don: theoKhu.rows.reduce((s, x) => s + Number(x.so_hoa_don || 0), 0),
    },
  });
}));

router.get('/bao-cao/tieu-thu-bat-thuong', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const thang = req.query.thang || thangTruoc(new Date().toISOString().slice(0, 7));
  if (!laThang(thang)) throw new LoiApi(400, 'Tháng không hợp lệ (YYYY-MM)');

  const dk = [`cs.thang = $1::char(7)`];
  const ts = [thang];
  if (req.nguoiDung.vaiTro === 'CHU_TRO') { ts.push(req.nguoiDung.id); dk.push(`k.chu_tro_id = $${ts.length}`); }
  if (req.query.khuTro) { ts.push(soNguyen(req.query.khuTro, { min: 1, ten: 'Mã khu trọ' })); dk.push(`p.khu_tro_id = $${ts.length}`); }

  const r = await truyVan(
    `WITH x AS (
       SELECT cs.phong_id, p.so_phong, p.khu_tro_id, k.ten AS ten_khu,
              cs.thang,
              (cs.dien_cuoi - cs.dien_dau) AS tieu_thu,
              (SELECT avg(dien_cuoi - dien_dau)
                 FROM (SELECT dien_dau, dien_cuoi FROM chi_so_dien_nuoc c2
                        WHERE c2.phong_id = cs.phong_id AND c2.thang < cs.thang
                        ORDER BY c2.thang DESC LIMIT 3) t) AS tb_3_thang
         FROM chi_so_dien_nuoc cs
         JOIN phong p ON p.id = cs.phong_id
         JOIN khu_tro k ON k.id = p.khu_tro_id
        WHERE ${dk.join(' AND ')}
     )
     SELECT *, round((tieu_thu / tb_3_thang * 100 - 100)::numeric, 1) AS phan_tram_tang
       FROM x
      WHERE tb_3_thang > 0 AND tieu_thu > tb_3_thang * 1.5
      ORDER BY phan_tram_tang DESC`,
    ts
  );
  res.json(r.rows);
}));

router.get('/bao-cao/tong-quan', xacThuc, choPhep(...QUAN_LY), asyncHandler(async (req, res) => {
  const laChuTro = req.nguoiDung.vaiTro === 'CHU_TRO';
  const ts = [laChuTro ? req.nguoiDung.id : null];
  const phamVi = '($1::int IS NULL OR k.chu_tro_id = $1)';

  const [phong, suCo, hoaDon] = await Promise.all([
    truyVan(
      `SELECT count(p.id)::int AS tong_phong,
              count(*) FILTER (WHERE p.trang_thai = 'DA_THUE')::int AS da_thue,
              count(*) FILTER (WHERE p.trang_thai = 'TRONG')::int AS trong,
              count(*) FILTER (WHERE p.trang_thai = 'DANG_SUA')::int AS dang_sua
         FROM phong p JOIN khu_tro k ON k.id = p.khu_tro_id
        WHERE ${phamVi}`,
      ts
    ),
    truyVan(
      `SELECT count(*) FILTER (WHERE bs.trang_thai = 'MOI')::int AS moi,
              count(*) FILTER (WHERE bs.trang_thai = 'DANG_XU_LY')::int AS dang_xu_ly
         FROM bao_su_co bs JOIN phong p ON p.id = bs.phong_id JOIN khu_tro k ON k.id = p.khu_tro_id
        WHERE ${phamVi}`,
      ts
    ),
    truyVan(
      `SELECT COALESCE(sum(hd.tong_tien), 0)::int AS phai_thu,
              COALESCE(sum(hd.da_thu), 0)::int AS da_thu,
              COALESCE(sum(hd.tong_tien - hd.da_thu), 0)::int AS con_no
         FROM hoa_don hd
         JOIN hop_dong h ON h.id = hd.hop_dong_id
         JOIN phong p ON p.id = h.phong_id
         JOIN khu_tro k ON k.id = p.khu_tro_id
        WHERE ${phamVi} AND hd.thang = to_char(CURRENT_DATE, 'YYYY-MM')::char(7)`,
      ts
    ),
  ]);

  const tra = {
    phong: phong.rows[0],
    su_co: suCo.rows[0],
  };
  // QUAN_LY không được xem số liệu doanh thu
  if (laChuTro) tra.hoa_don_thang_nay = hoaDon.rows[0];
  res.json(tra);
}));

module.exports = router;
