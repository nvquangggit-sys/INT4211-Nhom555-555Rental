import 'ho_tro.dart';

/// Báo sự cố do người thuê gửi (GET /bao-su-co/cua-toi).
class SuCo {
  const SuCo({
    required this.id,
    required this.phongId,
    required this.nguoiBaoId,
    this.loai = '',
    this.moTa = '',
    this.anhUrl,
    this.trangThai = '',
    this.xuLyLuc,
    this.soPhong = '',
    this.tenKhu = '',
    this.tenNguoiBao = '',
    this.sdtNguoiBao = '',
  });

  final int id;
  final int phongId;
  final int nguoiBaoId;
  final String loai;
  final String moTa;
  final String? anhUrl;
  final String trangThai;
  final DateTime? xuLyLuc;
  final String soPhong;
  final String tenKhu;
  final String tenNguoiBao;
  final String sdtNguoiBao;

  String get nhanTrangThai {
    switch (trangThai) {
      case 'MOI':
        return 'Chờ tiếp nhận';
      case 'DANG_XU_LY':
        return 'Đang xử lý';
      case 'DA_XU_LY':
        return 'Đã xử lý';
      case 'TU_CHOI':
        return 'Từ chối';
      default:
        return trangThai;
    }
  }

  factory SuCo.tuJson(Map<String, dynamic> json) {
    return SuCo(
      id: soNguyen(json['id']),
      phongId: soNguyen(json['phong_id']),
      nguoiBaoId: soNguyen(json['nguoi_bao_id']),
      loai: chuoi(json['loai']),
      moTa: chuoi(json['mo_ta']),
      anhUrl: json['anh_url']?.toString(),
      trangThai: chuoi(json['trang_thai']),
      xuLyLuc: _docNgay(json['xu_ly_luc']),
      soPhong: chuoi(json['so_phong']),
      tenKhu: chuoi(json['ten_khu']),
      tenNguoiBao: chuoi(json['ten_nguoi_bao']),
      sdtNguoiBao: chuoi(json['sdt_nguoi_bao']),
    );
  }
}

/// Các loại sự cố cho form gửi báo cáo.
const List<String> loaiSuCo = <String>[
  'Hỏng điện',
  'Dột / thấm nước',
  'Nước yếu / mất nước',
  'Hỏng khóa / cửa',
  'Vệ sinh chung',
  'Khác',
];

DateTime? _docNgay(dynamic giaTri) {
  if (giaTri == null) {
    return null;
  }
  if (giaTri is DateTime) {
    return giaTri;
  }
  return DateTime.tryParse(giaTri.toString());
}
