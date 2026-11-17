import 'ho_tro.dart';
import 'thanh_toan.dart';

/// Một dòng trong chi tiết hóa đơn (tiền phòng, điện, nước, rác, gửi xe).
class ChiTietHoaDon {
  const ChiTietHoaDon({
    required this.id,
    required this.tenKhoan,
    required this.soLuong,
    required this.donGia,
    required this.thanhTien,
  });

  final int id;
  final String tenKhoan;
  final double soLuong;
  final int donGia;
  final int thanhTien;

  factory ChiTietHoaDon.tuJson(Map<String, dynamic> json) {
    return ChiTietHoaDon(
      id: soNguyen(json['id']),
      tenKhoan: chuoi(json['ten_khoan']),
      soLuong: soThuc(json['so_luong']),
      donGia: soNguyen(json['don_gia']),
      thanhTien: soNguyen(json['thanh_tien']),
    );
  }
}

/// Hóa đơn tháng của người thuê (GET /hoa-don/cua-toi).
class HoaDon {
  const HoaDon({
    required this.id,
    required this.hopDongId,
    required this.thang,
    required this.tongTien,
    required this.daThu,
    this.hanThanhToan,
    this.trangThai = '',
    this.phongId = 0,
    this.soPhong = '',
    this.tenKhu = '',
    this.conNo = 0,
    this.soNgayQuaHan = 0,
    this.dienDau = 0,
    this.dienCuoi = 0,
    this.nuocDau = 0,
    this.nuocCuoi = 0,
    this.chiTiet = const [],
    this.thanhToan = const [],
  });

  final int id;
  final int hopDongId;
  final String thang;
  final int tongTien;
  final int daThu;
  final DateTime? hanThanhToan;
  final String trangThai;
  final int phongId;
  final String soPhong;
  final String tenKhu;
  final int conNo;
  final int soNgayQuaHan;

  // Chỉ số điện nước đầu – cuối kỳ (backend trả kèm trong từng hóa đơn).
  final int dienDau;
  final int dienCuoi;
  final int nuocDau;
  final int nuocCuoi;

  final List<ChiTietHoaDon> chiTiet;
  final List<ThanhToan> thanhToan;

  int get tieuThuDien => dienCuoi >= dienDau ? dienCuoi - dienDau : 0;
  int get tieuThuNuoc => nuocCuoi >= nuocDau ? nuocCuoi - nuocDau : 0;
  bool get conNoTien => conNo > 0;

  /// Số ngày còn lại tới hạn thanh toán (âm = quá hạn).
  int get soNgayConLai {
    final han = hanThanhToan;
    if (han == null) {
      return 0;
    }
    final homNay = DateTime.now();
    final dauNgay = DateTime(homNay.year, homNay.month, homNay.day);
    final dich = DateTime(han.toLocal().year, han.toLocal().month, han.toLocal().day);
    return dich.difference(dauNgay).inDays;
  }

  String get nhanTrangThai {
    switch (trangThai) {
      case 'CHUA_THU':
        return 'Chưa thu';
      case 'MOT_PHAN':
        return 'Thu một phần';
      case 'DA_THU':
        return 'Đã thu đủ';
      case 'QUA_HAN':
        return 'Quá hạn';
      default:
        return trangThai;
    }
  }

  factory HoaDon.tuJson(Map<String, dynamic> json) {
    final dsChiTiet = json['chi_tiet'];
    final dsThanhToan = json['thanh_toan'];
    return HoaDon(
      id: soNguyen(json['id']),
      hopDongId: soNguyen(json['hop_dong_id']),
      thang: chuoi(json['thang']),
      tongTien: soNguyen(json['tong_tien']),
      daThu: soNguyen(json['da_thu']),
      hanThanhToan: _docNgay(json['han_thanh_toan']),
      trangThai: chuoi(json['trang_thai']),
      phongId: soNguyen(json['phong_id']),
      soPhong: chuoi(json['so_phong']),
      tenKhu: chuoi(json['ten_khu']),
      conNo: soNguyen(json['con_no']),
      soNgayQuaHan: soNguyen(json['so_ngay_qua_han']),
      dienDau: soNguyen(json['dien_dau']),
      dienCuoi: soNguyen(json['dien_cuoi']),
      nuocDau: soNguyen(json['nuoc_dau']),
      nuocCuoi: soNguyen(json['nuoc_cuoi']),
      chiTiet: dsChiTiet is List
          ? dsChiTiet
              .whereType<Map<String, dynamic>>()
              .map(ChiTietHoaDon.tuJson)
              .toList()
          : const [],
      thanhToan: dsThanhToan is List
          ? dsThanhToan
              .whereType<Map<String, dynamic>>()
              .map(ThanhToan.tuJson)
              .toList()
          : const [],
    );
  }
}

DateTime? _docNgay(dynamic giaTri) {
  if (giaTri == null) {
    return null;
  }
  if (giaTri is DateTime) {
    return giaTri;
  }
  return DateTime.tryParse(giaTri.toString());
}
