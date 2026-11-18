import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_exception.dart';

/// Lớp gọi API dùng chung cho toàn bộ app Client (Nhóm 555 – đề 12).
///
/// Trách nhiệm:
/// - Giữ `baseUrl` (mặc định là backend Render của nhóm, đổi được trong app).
/// - Gắn `Authorization: Bearer <token>` lấy từ shared_preferences.
/// - Timeout 90 giây vì Render Free ngủ sau 15 phút, lần gọi đầu rất chậm.
/// - Giải mã UTF-8 bằng `utf8.decode(bodyBytes)` để tiếng Việt không lỗi font.
/// - Ném [PhienHetHanException] khi gặp 401 để app tự đưa về màn đăng nhập.
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  /// Địa chỉ API production của nhóm (Render).
  static const String baseUrlMacDinh = 'https://rental-nhom555-api.onrender.com';

  /// Render Free ngủ sau 15 phút nên đặt 90 giây theo yêu cầu đề.
  static const Duration thoiGianCho = Duration(seconds: 90);

  static const String _khoaBaseUrl = 'api_base_url';
  static const String _khoaToken = 'token';
  static const String _khoaId = 'nguoi_dung_id';
  static const String _khoaHoTen = 'ho_ten';
  static const String _khoaEmail = 'email';
  static const String _khoaVaiTro = 'vai_tro';

  SharedPreferences? _prefs;
  Future<void>? _dangNap;

  String _baseUrl = baseUrlMacDinh;
  String? _token;
  int? _nguoiDungId;
  String? _hoTen;
  String? _email;
  String? _vaiTro;

  /// Callback do `main.dart` gắn vào: xóa phiên và điều hướng về đăng nhập.
  VoidCallback? khiHetPhien;

  String get baseUrl => _baseUrl;
  String get hoTen => _hoTen ?? 'Người dùng';
  String get email => _email ?? '';
  String get vaiTro => _vaiTro ?? 'NGUOI_THUE';
  int? get nguoiDungId => _nguoiDungId;
  bool get daDangNhap => (_token ?? '').isNotEmpty;

  /// Nạp token + cấu hình từ bộ nhớ máy. Gọi một lần lúc khởi động.
  Future<void> khoiTao() => _dangNap ??= _nap();

  Future<void> _nap() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    _baseUrl = _chuanHoaUrl(prefs.getString(_khoaBaseUrl) ?? baseUrlMacDinh);
    _token = prefs.getString(_khoaToken);
    _nguoiDungId = prefs.getInt(_khoaId);
    _hoTen = prefs.getString(_khoaHoTen);
    _email = prefs.getString(_khoaEmail);
    _vaiTro = prefs.getString(_khoaVaiTro);
  }

  /// Lưu phiên sau khi đăng nhập / đăng ký thành công.
  Future<void> luuPhien({
    required String token,
    required int id,
    required String hoTen,
    required String email,
    required String vaiTro,
  }) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    _token = token;
    _nguoiDungId = id;
    _hoTen = hoTen;
    _email = email;
    _vaiTro = vaiTro;
    await prefs.setString(_khoaToken, token);
    await prefs.setInt(_khoaId, id);
    await prefs.setString(_khoaHoTen, hoTen);
    await prefs.setString(_khoaEmail, email);
    await prefs.setString(_khoaVaiTro, vaiTro);
  }

  /// Cập nhật hồ sơ hiển thị sau khi gọi GET /auth/toi (giữ nguyên token).
  Future<void> capNhatHoSo({
    required int id,
    required String hoTen,
    required String email,
    required String vaiTro,
  }) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    _nguoiDungId = id;
    _hoTen = hoTen;
    _email = email;
    _vaiTro = vaiTro;
    await prefs.setInt(_khoaId, id);
    await prefs.setString(_khoaHoTen, hoTen);
    await prefs.setString(_khoaEmail, email);
    await prefs.setString(_khoaVaiTro, vaiTro);
  }

  /// Đăng xuất: xóa token nhưng giữ lại địa chỉ API đã cấu hình.
  Future<void> dangXuat() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove(_khoaToken);
    await prefs.remove(_khoaId);
    await prefs.remove(_khoaHoTen);
    await prefs.remove(_khoaEmail);
    await prefs.remove(_khoaVaiTro);
    _token = null;
    _nguoiDungId = null;
    _hoTen = null;
    _email = null;
    _vaiTro = null;
  }

  /// Đổi địa chỉ backend (hữu ích khi demo bằng backend local).
  Future<void> luuBaseUrl(String url) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    _baseUrl = _chuanHoaUrl(url);
    await prefs.setString(_khoaBaseUrl, _baseUrl);
  }

  String _chuanHoaUrl(String url) {
    var s = url.trim();
    if (s.isEmpty) {
      return baseUrlMacDinh;
    }
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'https://$s';
    }
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  Map<String, String> _headers({bool json = true}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json; charset=utf-8',
        'User-Agent': '555Rental-Client-Flutter',
        if ((_token ?? '').isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (query == null || query.isEmpty) {
      return uri;
    }
    final hopLe = <String, String>{};
    query.forEach((khoa, giaTri) {
      if (giaTri == null) {
        return;
      }
      final s = giaTri.toString().trim();
      if (s.isNotEmpty) {
        hopLe[khoa] = s;
      }
    });
    return uri.replace(queryParameters: hopLe);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    await khoiTao();
    return _goi(() async {
      final res = await http
          .get(_uri(path, query), headers: _headers(json: false))
          .timeout(thoiGianCho);
      return _xuLy(res);
    });
  }

  Future<dynamic> post(String path, {Object? body}) async {
    await khoiTao();
    return _goi(() async {
      final res = await http
          .post(_uri(path),
              headers: _headers(),
              body: jsonEncode(body ?? const <String, dynamic>{}))
          .timeout(thoiGianCho);
      return _xuLy(res);
    });
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    await khoiTao();
    return _goi(() async {
      final res = await http
          .patch(_uri(path),
              headers: _headers(),
              body: jsonEncode(body ?? const <String, dynamic>{}))
          .timeout(thoiGianCho);
      return _xuLy(res);
    });
  }

  Future<dynamic> delete(String path) async {
    await khoiTao();
    return _goi(() async {
      final res = await http
          .delete(_uri(path), headers: _headers(json: false))
          .timeout(thoiGianCho);
      return _xuLy(res);
    });
  }

  /// Gửi form nhiều phần (multipart) kèm ảnh: biên lai chuyển khoản, ảnh sự cố.
  ///
  /// [tenTruongAnh] là tên field backend mong đợi (`anh`).
  Future<dynamic> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    File? anh,
    String tenTruongAnh = 'anh',
  }) async {
    await khoiTao();
    return _goi(() async {
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll(_headers(json: false))
        ..fields.addAll(fields);
      if (anh != null) {
        request.files.add(
          await http.MultipartFile.fromPath(tenTruongAnh, anh.path),
        );
      }
      final streamed = await request.send().timeout(thoiGianCho);
      final res = await http.Response.fromStream(streamed);
      return _xuLy(res);
    });
  }

  Future<dynamic> _goi(Future<dynamic> Function() ham) async {
    try {
      return await ham();
    } on PhienHetHanException {
      // Nhiều request có thể cùng nhận 401. Chỉ request đầu tiên (lúc token còn)
      // được điều hướng; các request sau không đẩy thêm màn đăng nhập.
      final conPhien = (_token ?? '').isNotEmpty;
      await dangXuat();
      if (conPhien) {
        khiHetPhien?.call();
      }
      rethrow;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Máy chủ chưa phản hồi sau 90 giây (Render có thể đang ngủ đông). '
        'Vui lòng thử lại.',
      );
    } on SocketException {
      throw const ApiException(
        'Không kết nối được máy chủ. Kiểm tra Wi-Fi/4G rồi thử lại.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Mất kết nối khi đang gửi dữ liệu. Vui lòng thử lại.',
      );
    } on FormatException {
      throw const ApiException('Máy chủ trả dữ liệu không đúng định dạng.');
    }
  }

  dynamic _xuLy(http.Response res) {
    final coNoiDung = res.bodyBytes.isNotEmpty;
    dynamic body;
    if (coNoiDung) {
      try {
        body = jsonDecode(utf8.decode(res.bodyBytes));
      } on FormatException {
        body = null;
      }
    }

    if (res.statusCode == 401 && (_token ?? '').isNotEmpty) {
      throw const PhienHetHanException();
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    var thongDiep = 'Máy chủ báo lỗi (${res.statusCode}).';
    if (body is Map && body['loi'] is String) {
      thongDiep = body['loi'] as String;
    }
    throw ApiException(thongDiep, maLoi: res.statusCode);
  }
}
