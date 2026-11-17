import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/api_service.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/login_screen.dart';
import 'ui/theme.dart';

/// Khóa Navigator toàn cục để đưa người dùng về màn đăng nhập khi token hết hạn
/// (mọi request nhận 401 đều đi qua `ApiService.khiHetPhien`).
final GlobalKey<NavigatorState> khoaDieuHuong = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nạp token + địa chỉ API đã lưu trước khi dựng giao diện.
  await ApiService.instance.khoiTao();
  ApiService.instance.khiHetPhien = _khiHetPhien;

  runApp(const UngDung555Rental());
}

void _khiHetPhien() {
  final dieuHuong = khoaDieuHuong.currentState;
  if (dieuHuong == null) {
    return;
  }
  dieuHuong.pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => const LoginScreen(daHetPhien: true),
    ),
    (route) => false,
  );
}

class UngDung555Rental extends StatelessWidget {
  const UngDung555Rental({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '555Rental Khách',
      debugShowCheckedModeBanner: false,
      navigatorKey: khoaDieuHuong,
      theme: taoTheme(),
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ApiService.instance.daDangNhap
          ? const HomeShell()
          : const LoginScreen(),
    );
  }
}
