/// Hàm đọc số an toàn cho các lớp mô hình.
///
/// Backend PostgreSQL trả NUMERIC dưới dạng chuỗi (ví dụ `dien_tich: "15.0"`)
/// nên app phải chấp nhận cả số lẫn chuỗi để không văng khi parse.
int soNguyen(dynamic giaTri) {
  if (giaTri is int) {
    return giaTri;
  }
  if (giaTri is num) {
    return giaTri.round();
  }
  return int.tryParse('${giaTri ?? ''}') ?? 0;
}

double soThuc(dynamic giaTri) {
  if (giaTri is num) {
    return giaTri.toDouble();
  }
  return double.tryParse('${giaTri ?? ''}') ?? 0;
}

String chuoi(dynamic giaTri, [String macDinh = '']) {
  if (giaTri == null) {
    return macDinh;
  }
  return giaTri.toString();
}
