const jwt = require('jsonwebtoken');
const { LoiApi } = require('../utils/loi');

// Middleware xác thực: thiếu / sai / hết hạn token đều trả 401.
function xacThuc(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : null;
  if (!token) return next(new LoiApi(401, 'Thiếu token đăng nhập'));
  try {
    req.nguoiDung = jwt.verify(token, process.env.JWT_SECRET);
    return next();
  } catch (e) {
    return next(new LoiApi(401, 'Token không hợp lệ hoặc đã hết hạn'));
  }
}

// Phân quyền theo vai trò ở BACKEND, không chỉ ẩn nút trên app.
function choPhep(...vaiTroChoPhep) {
  return (req, res, next) => {
    if (!req.nguoiDung) return next(new LoiApi(401, 'Thiếu token đăng nhập'));
    if (!vaiTroChoPhep.includes(req.nguoiDung.vaiTro)) {
      return next(new LoiApi(403, 'Không có quyền thực hiện chức năng này'));
    }
    return next();
  };
}

module.exports = { xacThuc, choPhep };
