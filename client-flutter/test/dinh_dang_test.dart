import 'package:flutter_test/flutter_test.dart';
import 'package:rental_client/core/dinh_dang.dart';

/// Kiểm thử các hàm định dạng dùng chung (không cần mạng).
void main() {
  group('DinhDang.tien', () {
    test('định dạng tiền VND có dấu chấm phân cách nghìn', () {
      expect(DinhDang.tien(3809600), '3.809.600 đ');
      expect(DinhDang.tien(0), '0 đ');
      expect(DinhDang.tien(null), '0 đ');
    });

    test('rút gọn triệu/tỷ cho thẻ tóm tắt', () {
      expect(DinhDang.tienNgan(2500000), '2.5 triệu');
      expect(DinhDang.tienNgan(1200000000), '1.2 tỷ');
      expect(DinhDang.tienNgan(45000), '45 nghìn');
    });
  });

  group('DinhDang ngày tháng', () {
    test('ngày dạng dd/MM/yyyy', () {
      expect(DinhDang.ngay(DateTime(2026, 10, 10)), '10/10/2026');
      expect(DinhDang.ngay(null), '--');
    });

    test('tháng hóa đơn từ chuỗi YYYY-MM', () {
      expect(DinhDang.thang('2026-10'), 'Tháng 10/2026');
      expect(DinhDang.thang(null), '--');
    });

    test('đọc ngày ISO an toàn', () {
      final ngay = DinhDang.docNgay('2026-11-10T00:00:00.000Z');
      expect(ngay, isNotNull);
      expect(DinhDang.docNgay('không phải ngày'), isNull);
      expect(DinhDang.docNgay(null), isNull);
    });
  });

  group('DinhDang.nhacHan', () {
    test('còn ngày, đến hạn hôm nay, quá hạn', () {
      expect(DinhDang.nhacHan(12), 'còn 12 ngày');
      expect(DinhDang.nhacHan(0), 'đến hạn hôm nay');
      expect(DinhDang.nhacHan(-3), 'đã quá hạn 3 ngày');
    });

    test('tính số ngày còn lại theo ngày (bỏ phần giờ)', () {
      final homNay = DateTime.now();
      final sau3Ngay = DateTime(homNay.year, homNay.month, homNay.day)
          .add(const Duration(days: 3));
      expect(DinhDang.soNgayConLai(sau3Ngay), 3);
    });
  });

  test('rút gọn văn bản dài', () {
    final vanBan = 'a' * 120;
    expect(DinhDang.rutGon(vanBan, doDai: 100).length, 101);
    expect(DinhDang.rutGon('  ngắn   gọn  '), 'ngắn gọn');
  });
}
