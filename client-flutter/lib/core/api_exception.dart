/// Lỗi giao tiếp với backend Nhóm 555.
///
/// Backend luôn trả JSON dạng `{"loi": "..."}` khi có lỗi nên lớp này giữ
/// nguyên thông điệp tiếng Việt do backend quyết định (quy tắc: mọi quyết định
/// nghiệp vụ nằm ở backend, app chỉ hiển thị).
class ApiException implements Exception {
  const ApiException(this.thongDiep, {this.maLoi});

  /// Thông điệp hiển thị cho người dùng.
  final String thongDiep;

  /// Mã HTTP nếu có (400, 403, 404, 409, 500...).
  final int? maLoi;

  @override
  String toString() => thongDiep;
}

/// Token hết hạn hoặc không hợp lệ (HTTP 401).
///
/// Khi gặp lỗi này app xóa phiên trong shared_preferences và đưa người dùng
/// về màn hình đăng nhập (xem `main.dart` -> `khiHetPhien`).
class PhienHetHanException extends ApiException {
  const PhienHetHanException()
      : super('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.',
            maLoi: 401);
}
