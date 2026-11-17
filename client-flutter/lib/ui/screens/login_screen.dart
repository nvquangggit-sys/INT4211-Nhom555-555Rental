import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../models/nguoi_dung.dart';
import '../theme.dart';
import 'api_settings_screen.dart';
import 'home_shell.dart';
import 'register_screen.dart';

/// Màn hình đăng nhập của App Client.
///
/// - Form + validator (email đúng định dạng, mật khẩu ≥ 6 ký tự).
/// - 3 trạng thái: đang gửi (khoá nút + vòng xoay), thành công (vào trang chủ),
///   lỗi (hiện thông điệp backend kèm nút thử lại).
/// - Lưu JWT vào shared_preferences, không lưu mật khẩu.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.daHetPhien = false});

  /// `true` khi người dùng bị đẩy về đây do token hết hạn (401).
  final bool daHetPhien;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: '');
  final _matKhauController = TextEditingController(text: '');

  bool _dangGui = false;
  bool _hienMatKhau = false;
  String? _loi;

  @override
  void dispose() {
    _emailController.dispose();
    _matKhauController.dispose();
    super.dispose();
  }

  Future<void> _dangNhap() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _dangGui = true;
      _loi = null;
    });

    try {
      final duLieu = await ApiService.instance.post(
        '/auth/dang-nhap',
        body: {
          'email': _emailController.text.trim(),
          'matKhau': _matKhauController.text,
        },
      );
      if (duLieu is! Map) {
        throw const ApiException('Máy chủ trả dữ liệu đăng nhập không hợp lệ.');
      }
      final ketQua = KetQuaDangNhap.tuJson(Map<String, dynamic>.from(duLieu));
      if (ketQua.token.isEmpty) {
        throw const ApiException('Máy chủ không trả về token đăng nhập.');
      }
      await ApiService.instance.luuPhien(
        token: ketQua.token,
        id: ketQua.nguoiDung.id,
        hoTen: ketQua.nguoiDung.hoTen,
        email: ketQua.nguoiDung.email,
        vaiTro: ketQua.nguoiDung.vaiTro,
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } on PhienHetHanException {
      if (!mounted) {
        return;
      }
      setState(() {
        _loi = 'Sai email hoặc mật khẩu. Vui lòng kiểm tra lại.';
      });
    } on ApiException catch (loi) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loi = loi.thongDiep;
      });
    } catch (loi) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loi = 'Không đăng nhập được: $loi';
      });
    } finally {
      if (mounted) {
        setState(() {
          _dangGui = false;
        });
      }
    }
  }

  Future<void> _moDangKy() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const RegisterScreen()),
    );
    if (!mounted || email == null || email.isEmpty) {
      return;
    }
    setState(() {
      _emailController.text = email;
      _loi = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã tạo tài khoản $email. Hãy đăng nhập.')),
    );
  }

  void _dienTaiKhoanDemo() {
    setState(() {
      _emailController.text = 'nguoithue01@555rental.vn';
      _matKhauController.text = '123456';
      _loi = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Cài đặt địa chỉ API',
                        onPressed: _dangGui
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ApiSettingsScreen(),
                                  ),
                                ),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const _LogoApp(),
                    const SizedBox(height: 18),
                    const Text(
                      'Chào mừng trở lại!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Đăng nhập để xem phòng trống, hóa đơn và hợp đồng thuê của bạn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: AppColors.chuMo),
                    ),
                    const SizedBox(height: 20),
                    if (widget.daHetPhien)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.canhBaoNen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_clock,
                                size: 18, color: AppColors.canhBao),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.canhBao,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'nguoithue01@555rental.vn',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (giaTri) {
                        final s = (giaTri ?? '').trim();
                        if (s.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        final hopLe =
                            RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(s);
                        if (!hopLe) {
                          return 'Email không đúng định dạng';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _matKhauController,
                      obscureText: !_hienMatKhau,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_dangGui) {
                          _dangNhap();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _hienMatKhau ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                          onPressed: () => setState(() {
                            _hienMatKhau = !_hienMatKhau;
                          }),
                          icon: Icon(
                            _hienMatKhau
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (giaTri) {
                        final s = giaTri ?? '';
                        if (s.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (s.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    if (_loi != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.nguyHiemNen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 18, color: AppColors.nguyHiem),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _loi!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.nguyHiem,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _dangGui ? null : _dangNhap,
                      child: _dangGui
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Đăng nhập'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _dangGui ? null : _moDangKy,
                      child: const Text('Chưa có tài khoản? Đăng ký ngay'),
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: _dangGui ? null : _dienTaiKhoanDemo,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.brandNhat,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.science_outlined,
                                size: 18, color: AppColors.brand),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tài khoản thử: nguoithue01@555rental.vn / 123456',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.brand,
                                ),
                              ),
                            ),
                            Text(
                              'Điền',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'API: ${ApiService.instance.baseUrl}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.chuMo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoApp extends StatelessWidget {
  const _LogoApp();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.apartment_rounded,
              color: Colors.white, size: 40),
        ),
        const SizedBox(height: 10),
        const Text(
          '555Rental Khách',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
