import 'ho_tro.dart';

/// Một lần thanh toán / xác nhận chuyển khoản (GET /thanh-toan/cua-toi).
class ThanhToan {
  const ThanhToan({
    required this.id,
    required this.hoaDonId,
    required this.soTien,
    this.hinhThuc = 'CHUYEN_KHOAN',
    this.anhBienLai,
    this.xacNhanBoi,
    this.thoiDiem,
    this.thang = '',
    this.tongTien = 0,
    this.daThu = 0,
    this.conNo = 0,
    this.soPhong = '',
    this.tenKhu = '',
    this.tenNguoiXacNhan = '',
  });

  final int id;
  final int hoaDonId;
  final int soTien;
  final String hinhThuc;
  final String? anhBienLai;
  final int? xacNhanBoi;
  final DateTime? thoiDiem;
  final String thang;
  final int tongTien;
  final int daThu;
  final int conNo;
  final String soPhong;
  final String tenKhu;
  final String tenNguoiXacNhan;

  bool get daXacNhan => xacNhanBoi != null;

  String get nhanHinhThuc {
    switch (hinhThuc) {
      case 'CHUYEN_KHOAN':
        return 'Chuyển khoản';
      case 'TIEN_MAT':
        return 'Tiền mặt';
      default:
        return hinhThuc;
    }
  }

  factory ThanhToan.tuJson(Map<String, dynamic> json) {
    return ThanhToan(
      id: soNguyen(json['id']),
      hoaDonId: soNguyen(json['hoa_don_id']),
      soTien: soNguyen(json['so_tien']),
      hinhThuc: chuoi(json['hinh_thuc'], 'CHUYEN_KHOAN'),
      anhBienLai: json['anh_bien_lai']?.toString(),
      xacNhanBoi: json['xac_nhan_boi'] == null
          ? null
          : soNguyen(json['xac_nhan_boi']),
      thoiDiem: _docNgay(json['thoi_diem']),
      thang: chuoi(json['thang']),
      tongTien: soNguyen(json['tong_tien']),
      daThu: soNguyen(json['da_thu']),
      conNo: soNguyen(json['con_no']),
      soPhong: chuoi(json['so_phong']),
      tenKhu: chuoi(json['ten_khu']),
      tenNguoiXacNhan: chuoi(json['ten_nguoi_xac_nhan']),
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
