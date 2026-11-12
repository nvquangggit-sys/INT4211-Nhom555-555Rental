const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { truyVan } = require('../db');
const { asyncHandler } = require('../utils/async');
const { LoiApi } = require('../utils/loi');
const { xacThuc } = require('../middleware/auth');
const { laEmail, chuoi } = require('../utils/kiem-tra');

const MAT_KHAU_TOI_THIEU = 6;

function taoToken(u) {
  if (!process.env.JWT_SECRET) {
    throw new LoiApi(500, 'Máy chủ chưa cấu hình JWT_SECRET');
  }
  return jwt.sign(
    { id: u.id, vaiTro: u.vai_tro, hoTen: u.ho_ten, email: u.email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_HAN || '7d' }
  );
}

function thongTinNguoiDung(u) {
  return {
    id: u.id,
    email: u.email,
    ho_ten: u.ho_ten,
    sdt: u.sdt,
    cccd: u.cccd,
    vai_tro: u.vai_tro,
  };
}

// POST /auth/dang-ky - mặc định tạo tài khoản NGUOI_THUE.
router.post('/dang-ky', asyncHandler(async (req, res) => {
  const { email, matKhau, hoTen, sdt, cccd } = req.body || {};

  if (!laEmail(email)) throw new LoiApi(400, 'Email không hợp lệ');
  const emailSach = email.trim().toLowerCase();
  if (emailSach.length > 120) throw new LoiApi(400, 'Email tối đa 120 ký tự');
  const mk = chuoi(matKhau, { ten: 'Mật khẩu', max: 100 });
  if (mk.length < MAT_KHAU_TOI_THIEU) {
    throw new LoiApi(400, `Mật khẩu phải có ít nhất ${MAT_KHAU_TOI_THIEU} ký tự`);
  }
  const ten = chuoi(hoTen, { ten: 'Họ tên', max: 100 });
  const sdtSach = sdt ? chuoi(sdt, { ten: 'Số điện thoại', max: 15 }) : null;
  const cccdSach = cccd ? chuoi(cccd, { ten: 'CCCD', max: 12 }) : null;

  const hash = await bcrypt.hash(mk, 10);
  try {
    const r = await truyVan(
      `INSERT INTO nguoi_dung (email, mat_khau_hash, ho_ten, sdt, cccd, vai_tro)
       VALUES ($1, $2, $3, $4, $5, 'NGUOI_THUE')
       RETURNING id, email, ho_ten, sdt, cccd, vai_tro`,
      [emailSach, hash, ten, sdtSach, cccdSach]
    );
    const nguoiDung = r.rows[0];
    res.status(201).json({ nguoiDung, token: taoToken(nguoiDung) });
  } catch (e) {
    if (e.code === '23505') throw new LoiApi(409, 'Email (hoặc CCCD) đã tồn tại');
    throw e;
  }
}));

// POST /auth/dang-nhap
router.post('/dang-nhap', asyncHandler(async (req, res) => {
  const { email, matKhau } = req.body || {};
  if (!laEmail(email) || typeof matKhau !== 'string' || !matKhau) {
    throw new LoiApi(400, 'Thiếu email hoặc mật khẩu');
  }

  const r = await truyVan(
    `SELECT id, email, mat_khau_hash, ho_ten, sdt, cccd, vai_tro
       FROM nguoi_dung WHERE email = $1`,
    [email.trim().toLowerCase()]
  );
  const u = r.rows[0];

  // Thông báo giống nhau cho cả hai trường hợp, tránh lộ email nào đã tồn tại
  const dung = u && (await bcrypt.compare(matKhau, u.mat_khau_hash));
  if (!dung) throw new LoiApi(401, 'Email hoặc mật khẩu không đúng');

  res.json({
    token: taoToken(u),
    nguoiDung: thongTinNguoiDung(u),
  });
}));

// GET /auth/toi - lấy hồ sơ từ token, dùng khi app mở lại
router.get('/toi', xacThuc, asyncHandler(async (req, res) => {
  const r = await truyVan(
    `SELECT id, email, ho_ten, sdt, cccd, vai_tro FROM nguoi_dung WHERE id = $1`,
    [req.nguoiDung.id]
  );
  if (!r.rows[0]) throw new LoiApi(404, 'Không tìm thấy người dùng');
  res.json(r.rows[0]);
}));

module.exports = router;
