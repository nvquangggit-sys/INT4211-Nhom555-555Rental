import 'package:flutter_test/flutter_test.dart';
import 'package:rental_client/models/hoa_don.dart';
import 'package:rental_client/models/hop_dong.dart';
import 'package:rental_client/models/lich_xem_phong.dart';
import 'package:rental_client/models/nguoi_dung.dart';
import 'package:rental_client/models/nhac_han.dart';
import 'package:rental_client/models/phong.dart';
import 'package:rental_client/models/su_co.dart';
import 'package:rental_client/models/thanh_toan.dart';

/// Kiểm thử đọc JSON thật của backend (NUMERIC trả dạng chuỗi, một số field null).
void main() {
  test('Phong đọc đúng số dạng chuỗi và tiện ích', () {
    final phong = Phong.tuJson({
      'id': 16,
      'khu_tro_id': 1,
      'so_phong': '116',
      'dien_tich': '30.0',
      'gia_thue': 3700000,
      'suc_chua': 2,
      'trang_thai': 'TRONG',
      'anh_url': 'https://picsum.photos/seed/555phong-1-16/800/600',
      'ten_khu': 'Khu trọ 555 Bình Thạnh',
      'dia_chi': '12/5 Nguyễn Xí',
      'phuong_xa': 'Phường 26, Bình Thạnh, TP.HCM',
      'tien_ich': 'Wifi, camera 24/7, giữ xe',
      'gia_dien': 3800,
      'gia_nuoc': 18000,
      'phi_rac': 30000,
      'phi_gui_xe': 100000,
      'tong_so': 9,
    });
    expect(phong.id, 16);
    expect(phong.dienTich, 30.0);
    expect(phong.conTrong, isTrue);
    expect(phong.nhanTrangThai, 'Còn trống');
    expect(phong.tongSo, 9);
    expect(phong.dsTienIch, ['Wifi', 'camera 24/7', 'giữ xe']);
  });

  test('HopDong đọc ngày ISO và tính sắp hết hạn', () {
    final hopDong = HopDong.tuJson({
      'id': 1,
      'phong_id': 1,
      'nguoi_thue_id': 3,
      'bat_dau': '2026-01-01T00:00:00.000Z',
      'ket_thuc': '2026-12-31T00:00:00.000Z',
      'tien_coc': 2500000,
      'so_nguoi': 2,
      'trang_thai': 'HIEU_LUC',
      'so_phong': '101',
      'dien_tich': '15.0',
      'gia_thue': 2500000,
      'so_ngay_con_lai': 20,
      'ten_chu_tro': 'Nguyễn Văn Chủ',
      'sdt_chu_tro': '0901000001',
    });
    expect(hopDong.nhanTrangThai, 'Đang hiệu lực');
    expect(hopDong.sapHetHan, isTrue);
    expect(hopDong.dienTich, 15.0);
    expect(hopDong.ketThuc, isNotNull);
  });

  test('HoaDon đọc chi tiết, thanh toán và tính tiêu thụ điện nước', () {
    final hoaDon = HoaDon.tuJson({
      'id': 1,
      'hop_dong_id': 1,
      'thang': '2026-10',
      'tong_tien': 3809600,
      'da_thu': 1904800,
      'han_thanh_toan': '2026-11-10T00:00:00.000Z',
      'trang_thai': 'MOT_PHAN',
      'phong_id': 1,
      'so_phong': '101',
      'ten_khu': 'Khu trọ 555 Bình Thạnh',
      'con_no': 1904800,
      'so_ngay_qua_han': 7,
      'dien_dau': 1637,
      'dien_cuoi': 1919,
      'nuoc_dau': 174,
      'nuoc_cuoi': 180,
      'chi_tiet': [
        {
          'id': 1,
          'ten_khoan': 'Tiền phòng',
          'so_luong': 1,
          'don_gia': 2500000,
          'thanh_tien': 2500000,
        },
        {
          'id': 271,
          'ten_khoan': 'Tiền điện',
          'so_luong': 282,
          'don_gia': 3800,
          'thanh_tien': 1071600,
        },
      ],
      'thanh_toan': [
        {
          'id': 1,
          'hoa_don_id': 1,
          'so_tien': 1904800,
          'hinh_thuc': 'CHUYEN_KHOAN',
          'xac_nhan_boi': 1,
          'thoi_diem': '2026-11-08T10:00:00+00:00',
          'ten_nguoi_xac_nhan': 'Nguyễn Văn Chủ',
        },
      ],
    });
    expect(hoaDon.chiTiet.length, 2);
    expect(hoaDon.chiTiet.first.tenKhoan, 'Tiền phòng');
    expect(hoaDon.thanhToan.single.daXacNhan, isTrue);
    expect(hoaDon.thanhToan.single.tenNguoiXacNhan, 'Nguyễn Văn Chủ');
    expect(hoaDon.tieuThuDien, 282);
    expect(hoaDon.tieuThuNuoc, 6);
    expect(hoaDon.conNoTien, isTrue);
    expect(hoaDon.nhanTrangThai, 'Thu một phần');
    expect(hoaDon.soNgayConLai, isA<int>());
  });

  test('ThanhToan đọc trạng thái chờ xác nhận', () {
    final thanhToan = ThanhToan.tuJson({
      'id': 235,
      'hoa_don_id': 1,
      'so_tien': 100000,
      'hinh_thuc': 'CHUYEN_KHOAN',
      'anh_bien_lai': 'https://example.com/bien-lai.png',
      'xac_nhan_boi': null,
      'thoi_diem': '2026-11-17T07:30:09.298Z',
      'thang': '2026-10',
      'so_phong': '101',
      'ten_khu': 'Khu trọ 555 Bình Thạnh',
      'ten_nguoi_xac_nhan': null,
    });
    expect(thanhToan.daXacNhan, isFalse);
    expect(thanhToan.nhanHinhThuc, 'Chuyển khoản');
    expect(thanhToan.anhBienLai, isNotNull);
  });

  test('SuCo đọc trạng thái và nhãn tiếng Việt', () {
    final suCo = SuCo.tuJson({
      'id': 12,
      'phong_id': 1,
      'nguoi_bao_id': 3,
      'loai': 'Hỏng điện',
      'mo_ta': 'Ổ điện bị tia lửa',
      'anh_url': null,
      'trang_thai': 'DANG_XU_LY',
      'xu_ly_luc': null,
    });
    expect(suCo.nhanTrangThai, 'Đang xử lý');
    expect(suCo.anhUrl, isNull);
  });

  test('LichXemPhong đọc thời gian và cờ chờ xác nhận', () {
    final lich = LichXemPhong.tuJson({
      'id': 11,
      'phong_id': 17,
      'khach_id': 3,
      'thoi_gian': '2026-11-21T02:00:00.000Z',
      'trang_thai': 'CHO_XAC_NHAN',
      'so_phong': '117',
      'gia_thue': 3700000,
      'anh_url': 'https://picsum.photos/seed/555phong-1-17/800/600',
      'ten_khu': 'Khu trọ 555 Bình Thạnh',
      'dia_chi': '12/5 Nguyễn Xí',
    });
    expect(lich.dangCho, isTrue);
    expect(lich.daXacNhan, isFalse);
    expect(lich.thoiGian, isNotNull);
  });

  test('NhacHan đọc hai danh sách và đếm việc cần làm', () {
    final nhacHan = NhacHan.tuJson({
      'hoa_don': [
        {
          'id': 1,
          'thang': '2026-10',
          'tong_tien': 3809600,
          'da_thu': 1904800,
          'con_no': 1904800,
          'trang_thai': 'MOT_PHAN',
          'han_thanh_toan': '2026-11-10T00:00:00.000Z',
          'so_ngay_con_lai': -7,
          'so_phong': '101',
          'ten_khu': 'Khu trọ 555 Bình Thạnh',
        },
      ],
      'hop_dong': [
        {
          'id': 1,
          'so_phong': '101',
          'ten_khu': 'Khu trọ 555 Bình Thạnh',
          'ket_thuc': '2026-12-31T00:00:00.000Z',
          'so_ngay_con_lai': 44,
        },
      ],
    });
    expect(nhacHan.soViecCanLam, 2);
    expect(nhacHan.hoaDon.single.quaHan, isTrue);
    expect(nhacHan.rong, isFalse);
  });

  test('NguoiDung và KetQuaDangNhap đọc đúng khóa camelCase', () {
    final ketQua = KetQuaDangNhap.tuJson({
      'token': 'jwt-token',
      'nguoiDung': {
        'id': 3,
        'email': 'nguoithue01@555rental.vn',
        'ho_ten': 'Nguyễn An',
        'sdt': '0901000001',
        'cccd': '079010000001',
        'vai_tro': 'NGUOI_THUE',
      },
    });
    expect(ketQua.token, 'jwt-token');
    expect(ketQua.nguoiDung.hoTen, 'Nguyễn An');
    expect(ketQua.nguoiDung.nhanVaiTro, 'Người thuê');
  });
}
