import 'ho_tro.dart';

/// Lịch xem phòng khách đã đặt (GET /lich-xem-phong/cua-toi).
class LichXemPhong {
  const LichXemPhong({
    required this.id,
    required this.phongId,
    required this.khachId,
    this.thoiGian,
    this.trangThai = '',
    this.soPhong = '',
    this.giaThue = 0,
    this.anhUrl,
    this.tenKhu = '',
    this.diaChi = '',
  });

  final int id;
  final int phongId;
  final int khachId;
  final DateTime? thoiGian;
  final String trangThai;
  final String soPhong;
  final int giaThue;
  final String? anhUrl;
  final String tenKhu;
  final String diaChi;

  bool get dangCho => trangThai == 'CHO_XAC_NHAN';
  bool get daXacNhan => trangThai == 'DA_XAC_NHAN';

  String get nhanTrangThai {
    switch (trangThai) {
      case 'CHO_XAC_NHAN':
        return 'Chờ xác nhận';
      case 'DA_XAC_NHAN':
        return 'Đã xác nhận';
      case 'TU_CHOI':
        return 'Bị từ chối';
      case 'DA_HUY':
        return 'Đã hủy';
      default:
        return trangThai;
    }
  }

  factory LichXemPhong.tuJson(Map<String, dynamic> json) {
    return LichXemPhong(
      id: soNguyen(json['id']),
      phongId: soNguyen(json['phong_id']),
      khachId: soNguyen(json['khach_id']),
      thoiGian: _docNgay(json['thoi_gian']),
      trangThai: chuoi(json['trang_thai']),
      soPhong: chuoi(json['so_phong']),
      giaThue: soNguyen(json['gia_thue']),
      anhUrl: json['anh_url']?.toString(),
      tenKhu: chuoi(json['ten_khu']),
      diaChi: chuoi(json['dia_chi']),
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
