// Các hàm kiểm tra dữ liệu đầu vào dùng chung.
const { LoiApi } = require('./loi');

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const THANG = /^[0-9]{4}-(0[1-9]|1[0-2])$/;

const laEmail = (s) => typeof s === 'string' && EMAIL.test(s.trim());
const laThang = (s) => typeof s === 'string' && THANG.test(s.trim());

function laNgay(s) {
  if (typeof s !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
  const d = new Date(`${s}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === s;
}

function soNguyen(v, { min = null, max = null, ten = 'Giá trị' } = {}) {
  const n = typeof v === 'number' ? v : Number(v);
  if (!Number.isInteger(n)) throw new LoiApi(400, `${ten} phải là số nguyên`);
  if (min !== null && n < min) throw new LoiApi(400, `${ten} phải lớn hơn hoặc bằng ${min}`);
  if (max !== null && n > max) throw new LoiApi(400, `${ten} phải nhỏ hơn hoặc bằng ${max}`);
  return n;
}

function soThuc(v, { min = null, max = null, ten = 'Giá trị' } = {}) {
  const n = typeof v === 'number' ? v : Number(v);
  if (!Number.isFinite(n)) throw new LoiApi(400, `${ten} phải là số`);
  if (min !== null && n < min) throw new LoiApi(400, `${ten} phải lớn hơn hoặc bằng ${min}`);
  if (max !== null && n > max) throw new LoiApi(400, `${ten} phải nhỏ hơn hoặc bằng ${max}`);
  return n;
}

function chuoi(v, { ten = 'Giá trị', min = 1, max = 200, batBuoc = true } = {}) {
  if (v === undefined || v === null) {
    if (batBuoc) throw new LoiApi(400, `Thiếu ${ten}`);
    return null;
  }
  if (typeof v !== 'string') throw new LoiApi(400, `${ten} phải là chuỗi`);
  const s = v.trim();
  if (batBuoc && s.length < min) throw new LoiApi(400, `${ten} không được để trống`);
  if (s.length > max) throw new LoiApi(400, `${ten} tối đa ${max} ký tự`);
  return s;
}

// Trường không bắt buộc: chuỗi rỗng hoặc chỉ có khoảng trắng được coi như "không truyền"
// (null), tránh lỗi 400 "không được để trống" khi app gửi form rỗng.
function chuoiTuyChon(v, opts = {}) {
  if (v === undefined || v === null) return null;
  if (typeof v === 'string' && v.trim() === '') return null;
  return chuoi(v, { ...opts, batBuoc: false });
}

// Đọc query param dạng số (trả null nếu không truyền).
function laySo(v) {
  if (v === undefined || v === null || v === '') return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : NaN;
}

// "2026-11" -> "2026-10"
function thangTruoc(thang) {
  const [y, m] = String(thang).split('-').map(Number);
  const d = new Date(Date.UTC(y, m - 2, 1));
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
}

module.exports = {
  laEmail, laThang, laNgay, soNguyen, soThuc, chuoi, chuoiTuyChon, laySo, thangTruoc,
};
