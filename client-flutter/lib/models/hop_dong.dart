import 'ho_tro.dart';

/// Hợp đồng thuê của chính người đang đăng nhập (GET /hop-dong/cua-toi).
class HopDong {
  const HopDong({
    required this.id,
    required this.phongId,
    required this.nguoiThueId,
    this.batDau,
    this.ketThuc,
    this.tienCoc = 0,
    this.soNguoi = 1,
    this.trangThai = '',
    this.soPhong = '',
    this.dienTich = 0,
    this.giaThue = 0,
    this.anhUrl,
    this.tenKhu = '',
    this.diaChi = '',
    this.phuongXa = '',
    this.tenChuTro = '',
    this.sdtChuTro = '',
    this.soNgayConLai = 0,
  });

  final int id;
  final int phongId;
  final int nguoiThueId;
  final DateTime? batDau;
  final DateTime? ketThuc;
  final int tienCoc;
  final int soNguoi;
  final String trangThai;
  final String soPhong;
  final double dienTich;
  final int giaThue;
  final String? anhUrl;
  final String tenKhu;
  final String diaChi;
  final String phuongXa;
  final String tenChuTro;
  final String sdtChuTro;

  /// Số ngày còn lại tới ngày hết hạn (âm = đã hết hạn).
  final int soNgayConLai;

  bool get sapHetHan => soNgayConLai >= 0 && soNgayConLai <= 30;

  String get nhanTrangThai {
    switch (trangThai) {
      case 'HIEU_LUC':
        return 'Đang hiệu lực';
      case 'HET_HAN':
        return 'Hết hạn';
      case 'DA_HUY':
        return 'Đã hủy';
      default:
        return trangThai;
    }
  }

  factory HopDong.tuJson(Map<String, dynamic> json) {
    return HopDong(
      id: soNguyen(json['id']),
      phongId: soNguyen(json['phong_id']),
      nguoiThueId: soNguyen(json['nguoi_thue_id']),
      batDau: _docNgay(json['bat_dau']),
      ketThuc: _docNgay(json['ket_thuc']),
      tienCoc: soNguyen(json['tien_coc']),
      soNguoi: soNguyen(json['so_nguoi']),
      trangThai: chuoi(json['trang_thai']),
      soPhong: chuoi(json['so_phong']),
      dienTich: soThuc(json['dien_tich']),
      giaThue: soNguyen(json['gia_thue']),
      anhUrl: json['anh_url']?.toString(),
      tenKhu: chuoi(json['ten_khu']),
      diaChi: chuoi(json['dia_chi']),
      phuongXa: chuoi(json['phuong_xa']),
      tenChuTro: chuoi(json['ten_chu_tro']),
      sdtChuTro: chuoi(json['sdt_chu_tro']),
      soNgayConLai: soNguyen(json['so_ngay_con_lai']),
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
