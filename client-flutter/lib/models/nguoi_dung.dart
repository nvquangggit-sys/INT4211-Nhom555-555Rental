import 'ho_tro.dart';

/// Tài khoản đang đăng nhập (GET /auth/toi, kết quả /auth/dang-nhap).
class NguoiDung {
  const NguoiDung({
    required this.id,
    required this.email,
    required this.hoTen,
    this.sdt = '',
    this.cccd = '',
    this.vaiTro = 'NGUOI_THUE',
  });

  final int id;
  final String email;
  final String hoTen;
  final String sdt;
  final String cccd;
  final String vaiTro;

  String get nhanVaiTro {
    switch (vaiTro) {
      case 'CHU_TRO':
        return 'Chủ trọ';
      case 'QUAN_LY':
        return 'Quản lý khu trọ';
      case 'NGUOI_THUE':
        return 'Người thuê';
      default:
        return vaiTro;
    }
  }

  factory NguoiDung.tuJson(Map<String, dynamic> json) {
    return NguoiDung(
      id: soNguyen(json['id']),
      email: chuoi(json['email']),
      hoTen: chuoi(json['ho_ten'], 'Người dùng'),
      sdt: chuoi(json['sdt']),
      cccd: chuoi(json['cccd']),
      vaiTro: chuoi(json['vai_tro'], 'NGUOI_THUE'),
    );
  }
}

/// Kết quả POST /auth/dang-nhap: `{ token, nguoiDung }`.
class KetQuaDangNhap {
  const KetQuaDangNhap({required this.token, required this.nguoiDung});

  final String token;
  final NguoiDung nguoiDung;

  factory KetQuaDangNhap.tuJson(Map<String, dynamic> json) {
    final nguoiDungJson = json['nguoiDung'] ?? json['nguoi_dung'];
    return KetQuaDangNhap(
      token: chuoi(json['token']),
      nguoiDung: nguoiDungJson is Map<String, dynamic>
          ? NguoiDung.tuJson(nguoiDungJson)
          : const NguoiDung(id: 0, email: '', hoTen: 'Người dùng'),
    );
  }
}
