import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rental_client/ui/screens/login_screen.dart';
import 'package:rental_client/ui/screens/register_screen.dart';
import 'package:rental_client/ui/theme.dart';

/// Kiểm thử giao diện form: validator chạy trước khi gọi API nên không cần mạng.
void main() {
  Future<void> moManHinh(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: taoTheme(), home: home));
  }

  testWidgets('LoginScreen báo lỗi khi bỏ trống email và mật khẩu',
      (tester) async {
    await moManHinh(tester, const LoginScreen());

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();

    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
  });

  testWidgets('LoginScreen báo lỗi định dạng email và mật khẩu ngắn',
      (tester) async {
    await moManHinh(tester, const LoginScreen());

    final oNhap = find.byType(TextFormField);
    await tester.enterText(oNhap.at(0), 'abc');
    await tester.enterText(oNhap.at(1), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();

    expect(find.text('Email không đúng định dạng'), findsOneWidget);
    expect(find.text('Mật khẩu phải có ít nhất 6 ký tự'), findsOneWidget);
  });

  testWidgets('Nút tài khoản thử điền sẵn email và mật khẩu demo',
      (tester) async {
    await moManHinh(tester, const LoginScreen());

    await tester.tap(find.text(
      'Tài khoản thử: nguoithue01@555rental.vn / 123456',
    ));
    await tester.pump();

    expect(find.text('nguoithue01@555rental.vn'), findsWidgets);
    expect(find.text('123456'), findsOneWidget);
  });

  testWidgets('RegisterScreen báo lỗi khi nhập lại mật khẩu không khớp',
      (tester) async {
    await moManHinh(tester, const RegisterScreen());

    final oNhap = find.byType(TextFormField);
    await tester.enterText(oNhap.at(0), 'Khách Thu 555');
    await tester.enterText(oNhap.at(1), 'khach555@example.com');
    await tester.enterText(oNhap.at(2), '0912345678');
    await tester.enterText(oNhap.at(3), '123456');
    await tester.enterText(oNhap.at(4), '654321');
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo tài khoản'));
    await tester.pump();

    expect(find.text('Mật khẩu nhập lại không khớp'), findsOneWidget);
  });

  testWidgets('RegisterScreen trả về màn trước bằng nút quay lại',
      (tester) async {
    await moManHinh(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const RegisterScreen(),
                ),
              ),
              child: const Text('Mở đăng ký'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo tài khoản người thuê'), findsOneWidget);

    await tester.tap(find.text('Đã có tài khoản? Quay lại đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Mở đăng ký'), findsOneWidget);
  });
}
