import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../theme.dart';

/// Đổi địa chỉ backend (hữu ích khi demo bằng máy local hoặc Render ngủ).
///
/// Có nút "Kiểm tra kết nối" gọi GET /health đúng như checklist tự kiểm 18 mục.
class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: ApiService.instance.baseUrl);

  bool _dangKiemTra = false;
  String? _ketQua;
  bool _thanhCong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _luu() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Địa chỉ API không được để trống')),
      );
      return;
    }
    await ApiService.instance.luuBaseUrl(url);
    if (!mounted) {
      return;
    }
    _controller.text = ApiService.instance.baseUrl;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã lưu API: ${ApiService.instance.baseUrl}')),
    );
  }

  Future<void> _kiemTra() async {
    setState(() {
      _dangKiemTra = true;
      _ketQua = null;
    });
    try {
      final duLieu = await ApiService.instance.get('/health');
      if (!mounted) {
        return;
      }
      setState(() {
        _thanhCong = true;
        _ketQua = duLieu is Map
            ? 'Kết nối OK: ${duLieu['ten'] ?? 'máy chủ 555Rental'} '
                '(phiên bản ${duLieu['phien_ban'] ?? '?'}, CSDL: ${duLieu['db'] ?? '?'})'
            : 'Kết nối OK';
      });
    } on ApiException catch (loi) {
      if (!mounted) {
        return;
      }
      setState(() {
        _thanhCong = false;
        _ketQua = loi.thongDiep;
      });
    } finally {
      if (mounted) {
        setState(() {
          _dangKiemTra = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt địa chỉ API')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Địa chỉ backend',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: ApiService.baseUrlMacDinh,
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Mặc định là backend Render của nhóm 555. Khi chạy backend trên '
              'máy, đổi thành http://10.0.2.2:3000 (máy ảo Android) hoặc '
              'http://<IP-LAN>:3000 (máy thật).',
              style: TextStyle(fontSize: 12, color: AppColors.chuMo),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _dangKiemTra ? null : _kiemTra,
              icon: _dangKiemTra
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.network_check),
              label: Text(
                _dangKiemTra ? 'Đang kiểm tra…' : 'Kiểm tra kết nối /health',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _dangKiemTra ? null : _luu,
              child: const Text('Lưu địa chỉ'),
            ),
            if (_ketQua != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _thanhCong
                      ? AppColors.thanhCongNen
                      : AppColors.nguyHiemNen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _ketQua!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _thanhCong
                        ? AppColors.thanhCong
                        : AppColors.nguyHiem,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                await ApiService.instance.luuBaseUrl(ApiService.baseUrlMacDinh);
                if (!mounted) {
                  return;
                }
                setState(() {
                  _controller.text = ApiService.instance.baseUrl;
                });
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Khôi phục mặc định'),
            ),
          ],
        ),
      ),
    );
  }
}
