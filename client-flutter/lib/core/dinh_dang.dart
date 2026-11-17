import 'package:intl/intl.dart';

/// Các hàm định dạng dùng chung: tiền VND, ngày tháng, tháng hóa đơn.
class DinhDang {
  DinhDang._();

  static final NumberFormat _tien = NumberFormat.decimalPattern('vi_VN');

  /// 3809600 -> "3.809.600 đ"
  static String tien(num? giaTri) {
    if (giaTri == null) {
      return '0 đ';
    }
    return '${_tien.format(giaTri.round())} đ';
  }

  /// 3809600 -> "3,8 triệu" (dùng cho thẻ tóm tắt).
  static String tienNgan(num? giaTri) {
    final so = (giaTri ?? 0).toDouble();
    if (so >= 1000000000) {
      return '${(so / 1000000000).toStringAsFixed(1)} tỷ';
    }
    if (so >= 1000000) {
      return '${(so / 1000000).toStringAsFixed(1)} triệu';
    }
    if (so >= 1000) {
      return '${(so / 1000).toStringAsFixed(0)} nghìn';
    }
    return _tien.format(so.round());
  }

  /// "2026-10-10T00:00:00.000Z" -> 10/10/2026
  static String ngay(DateTime? thoiDiem) {
    if (thoiDiem == null) {
      return '--';
    }
    return DateFormat('dd/MM/yyyy').format(thoiDiem.toLocal());
  }

  /// 12/11/2026 09:00
  static String ngayGio(DateTime? thoiDiem) {
    if (thoiDiem == null) {
      return '--';
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(thoiDiem.toLocal());
  }

  /// "2026-10" -> "Tháng 10/2026"
  static String thang(String? thang) {
    if (thang == null || !thang.contains('-')) {
      return thang ?? '--';
    }
    final phan = thang.split('-');
    if (phan.length < 2) {
      return thang;
    }
    return 'Tháng ${int.tryParse(phan[1]) ?? phan[1]}/${phan[0]}';
  }

  /// Đọc ngày từ JSON một cách an toàn (backend có thể trả null).
  static DateTime? docNgay(dynamic giaTri) {
    if (giaTri == null) {
      return null;
    }
    if (giaTri is DateTime) {
      return giaTri;
    }
    final s = giaTri.toString();
    if (s.isEmpty) {
      return null;
    }
    return DateTime.tryParse(s);
  }

  /// Số ngày còn lại tới [moc]; âm nghĩa là đã quá hạn.
  static int soNgayConLai(DateTime? moc) {
    if (moc == null) {
      return 0;
    }
    final homNay = DateTime.now();
    final dauNgay = DateTime(homNay.year, homNay.month, homNay.day);
    final dich = DateTime(moc.toLocal().year, moc.toLocal().month, moc.toLocal().day);
    return dich.difference(dauNgay).inDays;
  }

  /// Câu nhắc hạn thân thiện: "còn 12 ngày" / "đã quá hạn 3 ngày" / "hết hạn hôm nay".
  static String nhacHan(int soNgay) {
    if (soNgay > 0) {
      return 'còn $soNgay ngày';
    }
    if (soNgay == 0) {
      return 'đến hạn hôm nay';
    }
    return 'đã quá hạn ${-soNgay} ngày';
  }

  /// Rút gọn mô tả dài trong danh sách.
  static String rutGon(String? vanBan, {int doDai = 90}) {
    final s = (vanBan ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.length <= doDai) {
      return s;
    }
    return '${s.substring(0, doDai)}…';
  }
}
