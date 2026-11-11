const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const express = require('express');
const cors = require('cors');
const multer = require('multer');
const { pool } = require('./db');
const { LoiApi } = require('./utils/loi');
const { asyncHandler } = require('./utils/async');

const app = express();
const NHOM = '555';

app.disable('x-powered-by');
app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// Health check cho Render + giảng viên kiểm tra từ máy khác
app.get('/health', asyncHandler(async (req, res) => {
  let db = 'ok';
  try {
    await pool.query('SELECT 1');
  } catch (e) {
    db = 'khong ket noi duoc';
    console.error('[555Rental][health] Lỗi CSDL:', e.message);
  }
  res.status(200).json({
    ok: true,
    ten: `555Rental API - Nhóm ${NHOM}`,
    phien_ban: '1.0.0',
    thoi_gian: new Date().toISOString(),
    db,
  });
}));

app.get('/', (req, res) => {
  res.json({
    ten: `555Rental API - Nhóm ${NHOM}`,
    mo_ta: 'Backend hệ thống quản lý nhà trọ - INT4211 đề 12',
    tai_lieu: '/api.md trong repository',
    health: '/health',
  });
});

// Thứ tự mount: route phía khách trước để /hoa-don/cua-toi, /hop-dong/cua-toi
// không bị route /:id của admin bắt nhầm.
app.use('/', require('./routes/khach'));
app.use('/', require('./routes/chu_tro'));
app.use('/auth', require('./routes/auth'));

app.use((req, res) => {
  res.status(404).json({ loi: `Không tìm thấy đường dẫn ${req.method} ${req.originalUrl}` });
});

// Error handler chung: mọi lỗi trả JSON tiếng Việt, không lộ stack.
function xuLyLoi(err, req, res, next) {
  if (res.headersSent) return next(err);

  if (err instanceof LoiApi || err.laApi) {
    return res.status(err.ma || 400).json({
      loi: err.message,
      ...(err.chiTiet ? { chi_tiet: err.chiTiet } : {}),
    });
  }

  if (err instanceof multer.MulterError) {
    const thongDiep = err.code === 'LIMIT_FILE_SIZE'
      ? 'Ảnh vượt quá 5 MB'
      : `Lỗi tải ảnh: ${err.message}`;
    return res.status(400).json({ loi: thongDiep });
  }

  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ loi: 'JSON trong body không hợp lệ' });
  }

  // Lỗi từ PostgreSQL: trả mã phù hợp thay vì 500 chung chung
  if (err.code === '23505') {
    return res.status(409).json({ loi: 'Dữ liệu đã tồn tại (vi phạm ràng buộc UNIQUE)' });
  }
  if (err.code === '23503') {
    return res.status(409).json({ loi: 'Dữ liệu đang được bảng khác tham chiếu, không thể xóa/sửa' });
  }
  if (err.code === '23514' || err.code === '22P02' || err.code === '22007') {
    return res.status(400).json({ loi: 'Dữ liệu vi phạm ràng buộc của cơ sở dữ liệu' });
  }

  console.error(`[555Rental][loi] ${req.method} ${req.originalUrl}:`, err);
  return res.status(500).json({ loi: 'Lỗi máy chủ, vui lòng thử lại sau' });
}

app.use(xuLyLoi);

// Chỉ khởi động khi chạy trực tiếp (test có thể import app mà không mở cổng).
if (require.main === module) {
  const port = Number(process.env.PORT || 3000);
  if (!process.env.JWT_SECRET) {
    console.warn('[555Rental] CẢNH BÁO: chưa đặt JWT_SECRET, đăng nhập sẽ lỗi 500.');
  }
  if (!process.env.DATABASE_URL) {
    console.warn('[555Rental] CẢNH BÁO: chưa đặt DATABASE_URL, API sẽ không truy vấn được CSDL.');
  }
  app.listen(port, () => {
    console.log(`[555Rental] API nhóm ${NHOM} chạy ở cổng ${port}`);
  });
}

process.on('unhandledRejection', (e) => {
  console.error('[555Rental] Promise bị từ chối mà không bắt:', e);
});

module.exports = app;
