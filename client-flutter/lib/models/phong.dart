import 'ho_tro.dart';

/// Một phòng trọ trả về từ GET /phong (công khai, không cần đăng nhập).
class Phong {
  const Phong({
    required this.id,
    required this.khuTroId,
    required this.soPhong,
    required this.dienTich,
    required this.giaThue,
    required this.sucChua,
    required this.trangThai,
    this.anhUrl,
    this.tenKhu = '',
    this.diaChi = '',
    this.phuongXa = '',
    this.tienIch = '',
    this.giaDien = 0,
    this.giaNuoc = 0,
    this.phiRac = 0,
    this.phiGuiXe = 0,
    this.tongSo = 0,
    this.tenChuTro = '',
    this.sdtChuTro = '',
  });

  final int id;
  final int khuTroId;
  final String soPhong;
  final double dienTich;
  final int giaThue;
  final int sucChua;
  final String trangThai;
  final String? anhUrl;
  final String tenKhu;
  final String diaChi;
  final String phuongXa;
  final String tienIch;
  final int giaDien;
  final int giaNuoc;
  final int phiRac;
  final int phiGuiXe;

  /// Chỉ có ở GET /phong/:id (dùng cho màn chi tiết).
  final String tenChuTro;
  final String sdtChuTro;

  /// Tổng số phòng khớp bộ lọc (backend trả kèm trong mỗi dòng).
  final int tongSo;

  bool get conTrong => trangThai == 'TRONG';

  String get nhanTrangThai {
    switch (trangThai) {
      case 'TRONG':
        return 'Còn trống';
      case 'DA_THUE':
        return 'Đã thuê';
      case 'DANG_SUA':
        return 'Đang sửa chữa';
      default:
        return trangThai;
    }
  }

  factory Phong.tuJson(Map<String, dynamic> json) {
    return Phong(
      id: soNguyen(json['id']),
      khuTroId: soNguyen(json['khu_tro_id']),
      soPhong: chuoi(json['so_phong']),
      dienTich: soThuc(json['dien_tich']),
      giaThue: soNguyen(json['gia_thue']),
      sucChua: soNguyen(json['suc_chua']),
      trangThai: chuoi(json['trang_thai']),
      anhUrl: json['anh_url']?.toString(),
      tenKhu: chuoi(json['ten_khu']),
      diaChi: chuoi(json['dia_chi']),
      phuongXa: chuoi(json['phuong_xa']),
      tienIch: chuoi(json['tien_ich']),
      giaDien: soNguyen(json['gia_dien']),
      giaNuoc: soNguyen(json['gia_nuoc']),
      phiRac: soNguyen(json['phi_rac']),
      phiGuiXe: soNguyen(json['phi_gui_xe']),
      tongSo: soNguyen(json['tong_so']),
      tenChuTro: chuoi(json['ten_chu_tro']),
      sdtChuTro: chuoi(json['sdt_chu_tro']),
    );
  }

  /// Danh sách tiện ích tách từ chuỗi "Wifi, camera 24/7, ...".
  List<String> get dsTienIch => tienIch
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}
