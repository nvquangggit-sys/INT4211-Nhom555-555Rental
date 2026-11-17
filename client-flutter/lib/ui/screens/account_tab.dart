import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../models/nguoi_dung.dart';
import '../theme.dart';
import '../widgets/trang_thai.dart';
import 'api_settings_screen.dart';
import 'contracts_screen.dart';
import 'login_screen.dart';
import 'my_bookings_screen.dart';
import 'payment_history_screen.dart';
import 'reminders_screen.dart';

/// Tab Tài khoản: hồ sơ người thuê, lối tắt tới hợp đồng/lịch/thanh toán,
/// cài đặt API và đăng xuất (có hộp thoại xác nhận).
class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  late Future<NguoiDung?> _futureHoSo;
  bool _dangDongBo = false;

  @override
  void initState() {
    super.initState();
    _futureHoSo = _taiHoSo();
  }

  Future<NguoiDung?> _taiHoSo() async {
    final duLieu = await ApiService.instance.get('/auth/toi');
    if (duLieu is Map) {
      final nguoiDung = NguoiDung.tuJson(Map<String, dynamic>.from(duLieu));
      await ApiService.instance.capNhatHoSo(
        id: nguoiDung.id,
        hoTen: nguoiDung.hoTen,
        email: nguoiDung.email,
        vaiTro: nguoiDung.vaiTro,
      );
      return nguoiDung;
    }
    return null;
  }

  Future<void> _dongBo() async {
    if (_dangDongBo) {
      return;
    }
    setState(() {
      _dangDongBo = true;
      _futureHoSo = _taiHoSo();
    });
    try {
      await _futureHoSo;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đồng bộ hồ sơ từ máy chủ.')),
      );
    } on ApiException catch (loi) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không đồng bộ được: ${loi.thongDiep}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _dangDongBo = false;
        });
      }
    }
  }

  Future<void> _dangXuat() async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text(
          'Bạn sẽ cần đăng nhập lại để xem hóa đơn và hợp đồng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (dongY != true || !mounted) {
      return;
    }
    await ApiService.instance.dangXuat();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _mo(Widget manHinh) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => manHinh),
    );
  }

  void _thongTinUngDung() {
    showAboutDialog(
      context: context,
      applicationName: '555Rental Khách',
      applicationVersion: '1.0.0 (build 1)',
      applicationIcon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.apartment_rounded,
            color: Colors.white, size: 30),
      ),
      applicationLegalese:
          'Đồ án cuối kỳ INT4211 – Nhóm 555 – Đề 12: Hệ thống quản lý nhà trọ.\n'
          'App dành cho người thuê, dùng chung backend với App Admin.',
      children: [
        const SizedBox(height: 16),
        Text('API: ${ApiService.instance.baseUrl}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _TheHoSo(
          futureHoSo: _futureHoSo,
          dangDongBo: _dangDongBo,
          onDongBo: _dongBo,
          onThuLai: () => setState(() {
            _futureHoSo = _taiHoSo();
          }),
        ),
        const SizedBox(height: 18),
        const Text(
          'Thuê phòng của tôi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _DongMenu(
                icon: Icons.description_outlined,
                tieuDe: 'Hợp đồng thuê',
                moTa: 'Thời hạn, tiền cọc, cảnh báo sắp hết hạn',
                onTap: () => _mo(const ContractsScreen()),
              ),
              const Divider(height: 1),
              _DongMenu(
                icon: Icons.event_available_outlined,
                tieuDe: 'Lịch xem phòng',
                moTa: 'Theo dõi, hủy hoặc hoàn tác lịch đã đặt',
                onTap: () => _mo(const MyBookingsScreen()),
              ),
              const Divider(height: 1),
              _DongMenu(
                icon: Icons.payments_outlined,
                tieuDe: 'Lịch sử thanh toán',
                moTa: 'Các lần gửi biên lai và xác nhận của chủ trọ',
                onTap: () => _mo(const PaymentHistoryScreen()),
              ),
              const Divider(height: 1),
              _DongMenu(
                icon: Icons.notifications_active_outlined,
                tieuDe: 'Nhắc hạn',
                moTa: 'Hóa đơn đến hạn và hợp đồng sắp hết hạn',
                onTap: () => _mo(const RemindersScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Cài đặt',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _DongMenu(
                icon: Icons.link,
                tieuDe: 'Địa chỉ API',
                moTa: ApiService.instance.baseUrl,
                onTap: () => _mo(const ApiSettingsScreen()),
              ),
              const Divider(height: 1),
              _DongMenu(
                icon: Icons.info_outline,
                tieuDe: 'Thông tin ứng dụng',
                moTa: '555Rental Khách · phiên bản 1.0.0',
                onTap: _thongTinUngDung,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _dangXuat,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.nguyHiem,
            side: const BorderSide(color: AppColors.nguyHiem),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Đăng xuất'),
        ),
        const SizedBox(height: 14),
        const Text(
          '555Rental Khách · Đồ án INT4211 – Nhóm 555\n'
          'Dữ liệu hiển thị từ backend Render của nhóm.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: AppColors.chuMo),
        ),
      ],
    );
  }
}

class _TheHoSo extends StatelessWidget {
  const _TheHoSo({
    required this.futureHoSo,
    required this.dangDongBo,
    required this.onDongBo,
    required this.onThuLai,
  });

  final Future<NguoiDung?> futureHoSo;
  final bool dangDongBo;
  final VoidCallback onDongBo;
  final VoidCallback onThuLai;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<NguoiDung?>(
          future: futureHoSo,
          builder: (context, snapshot) {
            final nguoiDung = snapshot.data;
            final ten = nguoiDung?.hoTen ?? ApiService.instance.hoTen;
            final email = nguoiDung?.email ?? ApiService.instance.email;
            final vaiTro = nguoiDung?.vaiTro ?? ApiService.instance.vaiTro;
            final sdt = nguoiDung?.sdt ?? '';
            final cccd = nguoiDung?.cccd ?? '';
            final dangTai =
                snapshot.connectionState == ConnectionState.waiting;
            return Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.brandNhat,
                      child: Text(
                        ten.trim().isEmpty
                            ? 'K'
                            : ten.trim().substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ten,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.chuMo,
                            ),
                          ),
                          const SizedBox(height: 4),
                          NhanTrangThai(
                            ma: vaiTro == 'NGUOI_THUE'
                                ? 'HIEU_LUC'
                                : 'DA_THUE',
                            nhan: vaiTro == 'NGUOI_THUE'
                                ? 'Người thuê'
                                : vaiTro,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đồng bộ hồ sơ',
                      onPressed: dangDongBo ? null : onDongBo,
                      icon: dangDongBo
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync, color: AppColors.brand),
                    ),
                  ],
                ),
                if (dangTai) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                if (snapshot.hasError) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.canhBaoNen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off,
                            size: 16, color: AppColors.canhBao),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Đang dùng hồ sơ lưu trên máy (chưa đồng bộ được).',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.canhBao,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onThuLai,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (sdt.isNotEmpty || cccd.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  if (sdt.isNotEmpty)
                    DongThongTin(
                      nhan: 'Số điện thoại',
                      giaTri: sdt,
                      icon: Icons.phone_outlined,
                    ),
                  if (cccd.isNotEmpty)
                    DongThongTin(
                      nhan: 'CCCD',
                      giaTri: cccd,
                      icon: Icons.badge_outlined,
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DongMenu extends StatelessWidget {
  const _DongMenu({
    required this.icon,
    required this.tieuDe,
    required this.moTa,
    required this.onTap,
  });

  final IconData icon;
  final String tieuDe;
  final String moTa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.brandNhat,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 19, color: AppColors.brand),
      ),
      title: Text(
        tieuDe,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        moTa,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11.5, color: AppColors.chuMo),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}
