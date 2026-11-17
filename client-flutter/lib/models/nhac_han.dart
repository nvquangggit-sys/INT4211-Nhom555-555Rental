import 'ho_tro.dart';

/// Một hóa đơn trong danh sách nhắc hạn (GET /nhac-han).
class NhacHanHoaDon {
  const NhacHanHoaDon({
    required this.id,
    this.thang = '',
    this.tongTien = 0,
    this.daThu = 0,
    this.conNo = 0,
    this.trangThai = '',
    this.hanThanhToan,
    this.soNgayConLai = 0,
    this.soPhong = '',
    this.tenKhu = '',
  });

  final int id;
  final String thang;
  final int tongTien;
  final int daThu;
  final int conNo;
  final String trangThai;
  final DateTime? hanThanhToan;
  final int soNgayConLai;
  final String soPhong;
  final String tenKhu;

  bool get quaHan => soNgayConLai < 0;
  bool get sapDenHan => soNgayConLai >= 0 && soNgayConLai <= 5;

  factory NhacHanHoaDon.tuJson(Map<String, dynamic> json) {
    return NhacHanHoaDon(
      id: soNguyen(json['id']),
      thang: chuoi(json['thang']),
      tongTien: soNguyen(json['tong_tien']),
      daThu: soNguyen(json['da_thu']),
      conNo: soNguyen(json['con_no']),
      trangThai: chuoi(json['trang_thai']),
      hanThanhToan: _docNgay(json['han_thanh_toan']),
      soNgayConLai: soNguyen(json['so_ngay_con_lai']),
      soPhong: chuoi(json['so_phong']),
      tenKhu: chuoi(json['ten_khu']),
    );
  }
}

/// Một hợp đồng sắp hết hạn trong danh sách nhắc hạn.
class NhacHanHopDong {
  const NhacHanHopDong({
    required this.id,
    this.soPhong = '',
    this.tenKhu = '',
    this.ketThuc,
    this.soNgayConLai = 0,
  });

  final int id;
  final String soPhong;
  final String tenKhu;
  final DateTime? ketThuc;
  final int soNgayConLai;

  factory NhacHanHopDong.tuJson(Map<String, dynamic> json) {
    return NhacHanHopDong(
      id: soNguyen(json['id']),
      soPhong: chuoi(json['so_phong']),
      tenKhu: chuoi(json['ten_khu']),
      ketThuc: _docNgay(json['ket_thuc']),
      soNgayConLai: soNguyen(json['so_ngay_con_lai']),
    );
  }
}

/// Gói dữ liệu GET /nhac-han.
class NhacHan {
  const NhacHan({this.hoaDon = const [], this.hopDong = const []});

  final List<NhacHanHoaDon> hoaDon;
  final List<NhacHanHopDong> hopDong;

  bool get rong => hoaDon.isEmpty && hopDong.isEmpty;
  int get soViecCanLam => hoaDon.length + hopDong.length;

  factory NhacHan.tuJson(Map<String, dynamic> json) {
    final dsHoaDon = json['hoa_don'];
    final dsHopDong = json['hop_dong'];
    return NhacHan(
      hoaDon: dsHoaDon is List
          ? dsHoaDon
              .whereType<Map<String, dynamic>>()
              .map(NhacHanHoaDon.tuJson)
              .toList()
          : const [],
      hopDong: dsHopDong is List
          ? dsHopDong
              .whereType<Map<String, dynamic>>()
              .map(NhacHanHopDong.tuJson)
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
