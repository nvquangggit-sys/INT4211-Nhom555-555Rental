import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../theme.dart';

/// Màn hình đăng ký tài khoản người thuê.
///
/// Trả email vừa đăng ký về màn đăng nhập bằng `Navigator.pop(email)`
/// (yêu cầu "Navigator có trả kết quả về màn trước" của đề).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hoTenController = TextEditingController();
  final _emailController = TextEditingController();
  final _sdtController = TextEditingController();
  final _matKhauController = TextEditingController();
  final _xacNhanController = TextEditingController();

  bool _dangGui = false;
  bool _hienMatKhau = false;
  String? _loi;

  @override
  void dispose() {
    _hoTenController.dispose();
    _emailController.dispose();
    _sdtController.dispose();
    _matKhauController.dispose();
    _xacNhanController.dispose();
    super.dispose();
  }

  Future<void> _dangKy() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _dangGui = true;
      _loi = null;
    });

    try {
      await ApiService.instance.post(
        '/auth/dang-ky',
        body: {
          'email': _emailController.text.trim(),
          'matKhau': _matKhauController.text,
          'hoTen': _hoTenController.text.trim(),
          'sdt': _sdtController.text.trim(),
        },
      );
      if (!mounted) {
        return;
      }
      final email = _emailController.text.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công! Hãy đăng nhập.')),
      );
      Navigator.of(context).pop(email);
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
        _loi = 'Không đăng ký được: $loi';
      });
    } finally {
      if (mounted) {
        setState(() {
          _dangGui = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tài khoản')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tạo tài khoản người thuê',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tài khoản dùng chung dữ liệu với App Admin của chủ trọ.',
                    style: TextStyle(fontSize: 13, color: AppColors.chuMo),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _hoTenController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (giaTri) {
                      final s = (giaTri ?? '').trim();
                      if (s.isEmpty) {
                        return 'Vui lòng nhập họ tên';
                      }
                      if (s.length < 2) {
                        return 'Họ tên quá ngắn';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: (giaTri) {
                      final s = (giaTri ?? '').trim();
                      if (s.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(s)) {
                        return 'Email không đúng định dạng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sdtController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (giaTri) {
                      final s = (giaTri ?? '').trim();
                      if (s.isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }
                      if (!RegExp(r'^0\d{9,10}$').hasMatch(s)) {
                        return 'Số điện thoại phải bắt đầu bằng 0, gồm 10–11 số';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _matKhauController,
                    obscureText: !_hienMatKhau,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _xacNhanController,
                    obscureText: !_hienMatKhau,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Nhập lại mật khẩu',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                    validator: (giaTri) {
                      if ((giaTri ?? '').isEmpty) {
                        return 'Vui lòng nhập lại mật khẩu';
                      }
                      if (giaTri != _matKhauController.text) {
                        return 'Mật khẩu nhập lại không khớp';
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
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _dangGui ? null : _dangKy,
                    child: _dangGui
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Tạo tài khoản'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _dangGui
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Đã có tài khoản? Quay lại đăng nhập'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
