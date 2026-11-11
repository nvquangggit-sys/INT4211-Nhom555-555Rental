const fs = require('fs/promises');
const path = require('path');
const crypto = require('crypto');
const multer = require('multer');
const { LoiApi } = require('./loi');

// Giữ ảnh trong RAM rồi đẩy lên Supabase Storage (không lưu base64 vào CSDL).
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // tối đa 5 MB
  fileFilter: (req, file, cb) => {
    if (!/^image\/(jpeg|png|webp|gif)$/.test(file.mimetype)) {
      return cb(new LoiApi(400, 'Chỉ nhận tệp ảnh JPEG, PNG, WEBP hoặc GIF'));
    }
    return cb(null, true);
  },
});

const DUOI = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'image/gif': 'gif' };

function tenTep(file, thuMuc) {
  const duoi = DUOI[file.mimetype] || 'jpg';
  return `${thuMuc}/${Date.now()}-${crypto.randomUUID()}.${duoi}`;
}

async function luuSupabase(file, khoa) {
  const base = process.env.SUPABASE_URL.replace(/\/$/, '');
  const bucket = process.env.SUPABASE_BUCKET || 'anh';
  const url = `${base}/storage/v1/object/${bucket}/${khoa}`;

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.SUPABASE_SERVICE_KEY}`,
      'Content-Type': file.mimetype,
      'x-upsert': 'true',
    },
    body: file.buffer,
  });

  if (!res.ok) {
    const noiDung = await res.text().catch(() => '');
    throw new LoiApi(502, 'Không tải được ảnh lên Supabase Storage', noiDung.slice(0, 300));
  }
  return `${base}/storage/v1/object/public/${bucket}/${khoa}`;
}

async function luuNoiBo(file, khoa) {
  const goc = path.join(__dirname, '..', '..', 'uploads');
  const dich = path.join(goc, khoa);
  await fs.mkdir(path.dirname(dich), { recursive: true });
  await fs.writeFile(dich, file.buffer);
  const tienTo = (process.env.PUBLIC_BASE_URL || '').replace(/\/$/, '');
  return `${tienTo}/uploads/${khoa}`;
}

// Trả về URL ảnh. Ưu tiên Supabase Storage; nếu chưa cấu hình thì lưu đĩa
// để chạy thử ở máy cá nhân. Production bắt buộc dùng Supabase Storage.
async function luuAnh(file, thuMuc = 'khac') {
  if (!file) throw new LoiApi(400, 'Thiếu tệp ảnh');
  const khoa = tenTep(file, thuMuc);
  if (process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_KEY) {
    return { url: await luuSupabase(file, khoa), nguon: 'supabase' };
  }
  if (process.env.NODE_ENV === 'production') {
    throw new LoiApi(500, 'Chưa cấu hình SUPABASE_URL và SUPABASE_SERVICE_KEY');
  }
  return { url: await luuNoiBo(file, khoa), nguon: 'local' };
}

module.exports = { upload, luuAnh };
