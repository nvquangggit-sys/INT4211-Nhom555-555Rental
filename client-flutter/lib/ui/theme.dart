import 'package:flutter/material.dart';

/// Bảng màu + theme Material 3 cho app Client 555Rental.
class AppColors {
  AppColors._();

  static const Color brand = Color(0xFF0F766E); // teal 700
  static const Color brandDam = Color(0xFF0B4F4A);
  static const Color brandNhat = Color(0xFFE6F4F1);
  static const Color nen = Color(0xFFF5F7F7);
  static const Color chu = Color(0xFF1F2A2A);
  static const Color chuMo = Color(0xFF5F6B6B);
  static const Color vien = Color(0xFFE0E6E6);
  static const Color thanhCong = Color(0xFF15803D);
  static const Color thanhCongNen = Color(0xFFE7F6EC);
  static const Color canhBao = Color(0xFFB45309);
  static const Color canhBaoNen = Color(0xFFFDF3E3);
  static const Color nguyHiem = Color(0xFFB91C1C);
  static const Color nguyHiemNen = Color(0xFFFDECEC);
  static const Color thongTin = Color(0xFF1D4ED8);
  static const Color thongTinNen = Color(0xFFE8EEFE);
}

/// Màu chữ cho từng trạng thái nghiệp vụ backend trả về.
Color mauTrangThai(String ma) {
  switch (ma) {
    case 'TRONG':
    case 'DA_THU':
    case 'DA_XU_LY':
    case 'DA_XAC_NHAN':
    case 'HIEU_LUC':
      return AppColors.thanhCong;
    case 'MOT_PHAN':
    case 'DANG_XU_LY':
    case 'CHO_XAC_NHAN':
    case 'DANG_SUA':
      return AppColors.canhBao;
    case 'QUA_HAN':
    case 'TU_CHOI':
    case 'DA_HUY':
    case 'MOI':
      return AppColors.nguyHiem;
    case 'DA_THUE':
      return AppColors.thongTin;
    default:
      return AppColors.chuMo;
  }
}

/// Nền nhạt tương ứng màu chữ trạng thái.
Color nenTrangThai(String ma) {
  final mau = mauTrangThai(ma);
  if (mau == AppColors.thanhCong) {
    return AppColors.thanhCongNen;
  }
  if (mau == AppColors.canhBao) {
    return AppColors.canhBaoNen;
  }
  if (mau == AppColors.nguyHiem) {
    return AppColors.nguyHiemNen;
  }
  if (mau == AppColors.thongTin) {
    return AppColors.thongTinNen;
  }
  return const Color(0xFFEFF3F3);
}

ThemeData taoTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.brand,
    secondary: AppColors.canhBao,
    surface: Colors.white,
  );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.nen,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.brand,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.vien),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.brandNhat,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final chon = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11.5,
          fontWeight: chon ? FontWeight.w700 : FontWeight.w500,
          color: chon ? AppColors.brand : AppColors.chuMo,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final chon = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: chon ? AppColors.brand : AppColors.chuMo,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.vien),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.vien),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.nguyHiem),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.nguyHiem, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        side: const BorderSide(color: AppColors.brand),
        foregroundColor: AppColors.brand,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.brandDam,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.vien, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: AppColors.brandNhat,
      side: const BorderSide(color: AppColors.vien),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: const TextStyle(fontSize: 13),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.chu,
      displayColor: AppColors.chu,
    ),
  );
}
