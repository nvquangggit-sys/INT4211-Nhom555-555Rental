const { truyVan } = require('../db');
const { LoiApi } = require('./loi');

// Lấy khu trọ và kiểm tra quyền.
// - CHU_TRO: chỉ được thao tác trên khu của chính mình.
// - QUAN_LY: được thao tác nghiệp vụ trên mọi khu (nhân viên của chủ trọ).
// - NGUOI_THUE: không dùng các hàm này.
async function layKhu(q, khuId, nguoiDung) {
  const r = await q('SELECT * FROM khu_tro WHERE id = $1', [khuId]);
  const khu = r.rows[0];
  if (!khu) throw new LoiApi(404, 'Không tìm thấy khu trọ');
  if (nguoiDung.vaiTro === 'CHU_TRO' && khu.chu_tro_id !== nguoiDung.id) {
    throw new LoiApi(403, 'Bạn không quản lý khu trọ này');
  }
  return khu;
}

async function layPhong(q, phongId, nguoiDung) {
  const r = await q(
    `SELECT p.*, k.chu_tro_id, k.ten AS ten_khu
       FROM phong p JOIN khu_tro k ON k.id = p.khu_tro_id
      WHERE p.id = $1`,
    [phongId]
  );
  const phong = r.rows[0];
  if (!phong) throw new LoiApi(404, 'Không tìm thấy phòng');
  if (nguoiDung && nguoiDung.vaiTro === 'CHU_TRO' && phong.chu_tro_id !== nguoiDung.id) {
    throw new LoiApi(403, 'Bạn không quản lý phòng này');
  }
  return phong;
}

async function layHopDong(q, hopDongId, nguoiDung) {
  const r = await q(
    `SELECT h.*, p.khu_tro_id, p.so_phong, p.gia_thue, k.chu_tro_id,
            k.ten AS ten_khu, nd.ho_ten AS ten_nguoi_thue, nd.sdt AS sdt_nguoi_thue
       FROM hop_dong h
       JOIN phong p ON p.id = h.phong_id
       JOIN khu_tro k ON k.id = p.khu_tro_id
       JOIN nguoi_dung nd ON nd.id = h.nguoi_thue_id
      WHERE h.id = $1`,
    [hopDongId]
  );
  const hopDong = r.rows[0];
  if (!hopDong) throw new LoiApi(404, 'Không tìm thấy hợp đồng');
  if (nguoiDung) {
    if (nguoiDung.vaiTro === 'CHU_TRO' && hopDong.chu_tro_id !== nguoiDung.id) {
      throw new LoiApi(403, 'Bạn không quản lý hợp đồng này');
    }
    if (nguoiDung.vaiTro === 'NGUOI_THUE' && hopDong.nguoi_thue_id !== nguoiDung.id) {
      throw new LoiApi(403, 'Đây không phải hợp đồng của bạn');
    }
  }
  return hopDong;
}

// Điều kiện lọc theo chủ trọ cho câu SQL danh sách.
// Trả về { dieuKien, thamSo } để nối bằng AND, luôn dùng tham số $n.
function phamViChuTro(nguoiDung, cot = 'k.chu_tro_id', chiSoThamSo) {
  if (nguoiDung.vaiTro === 'CHU_TRO') {
    return { dieuKien: `${cot} = $${chiSoThamSo}`, thamSo: [nguoiDung.id] };
  }
  return { dieuKien: null, thamSo: [] };
}

module.exports = { layKhu, layPhong, layHopDong, phamViChuTro };
