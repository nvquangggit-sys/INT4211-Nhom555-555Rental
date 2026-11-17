import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../theme.dart';
import 'account_tab.dart';
import 'api_settings_screen.dart';
import 'contracts_screen.dart';
import 'home_tab.dart';
import 'incident_create_screen.dart';
import 'incidents_tab.dart';
import 'invoices_tab.dart';
import 'login_screen.dart';
import 'my_bookings_screen.dart';
import 'payment_history_screen.dart';
import 'reminders_screen.dart';
import 'rooms_tab.dart';

/// Khung chính sau khi đăng nhập: NavigationBar 5 tab + Drawer + FAB báo sự cố.
///
/// Dùng `IndexedStack` để giữ trạng thái từng tab (không tải lại khi chuyển tab).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const List<String> _tieuDe = [
    '555Rental · Trang chủ',
    'Tìm phòng trống',
    'Hóa đơn của tôi',
    'Sự cố của tôi',
    'Tài khoản',
  ];

  final GlobalKey<IncidentsTabState> _khoaSuCo =
      GlobalKey<IncidentsTabState>();

  int _chiSo = 0;
  int _soNhacHan = 0;

  @override
  void initState() {
    super.initState();
    _demNhacHan();
  }

  Future<void> _demNhacHan() async {
    try {
      final duLieu = await ApiService.instance.get('/nhac-han');
      if (!mounted || duLieu is! Map) {
        return;
      }
      final soHoaDon =
          duLieu['hoa_don'] is List ? (duLieu['hoa_don'] as List).length : 0;
      final soHopDong =
          duLieu['hop_dong'] is List ? (duLieu['hop_dong'] as List).length : 0;
      setState(() {
        _soNhacHan = soHoaDon + soHopDong;
      });
    } on ApiException {
      // Không quan trọng: badge chỉ là thông tin phụ.
    } catch (_) {
      // Bỏ qua lỗi mạng khi đếm nhắc hạn.
    }
  }

  void _chonTab(int chiSo) {
    setState(() {
      _chiSo = chiSo;
    });
  }

  Future<void> _moNhacHan() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const RemindersScreen()),
    );
    if (mounted) {
      await _demNhacHan();
    }
  }

  Future<void> _moFormSuCo() async {
    final daGui = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const IncidentCreateScreen()),
    );
    if (daGui == true && mounted) {
      await _khoaSuCo.currentState?.taiLai();
    }
  }

  Future<void> _mo(Widget manHinh) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => manHinh),
    );
    if (mounted) {
      await _demNhacHan();
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

  void _chonTuDrawer(int chiSo) {
    Navigator.of(context).pop();
    _chonTab(chiSo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tieuDe[_chiSo]),
        actions: [
          IconButton(
            tooltip: 'Nhắc hạn',
            onPressed: _moNhacHan,
            icon: _soNhacHan > 0
                ? Badge.count(
                    count: _soNhacHan,
                    backgroundColor: AppColors.canhBao,
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      drawer: _taoDrawer(),
      body: IndexedStack(
        index: _chiSo,
        children: [
          HomeTab(onMoTab: _chonTab),
          const RoomsTab(),
          const InvoicesTab(),
          IncidentsTab(key: _khoaSuCo),
          const AccountTab(),
        ],
      ),
      floatingActionButton: _chiSo == 3
          ? FloatingActionButton.extended(
              onPressed: _moFormSuCo,
              backgroundColor: AppColors.nguyHiem,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('Báo sự cố'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _chiSo,
        onDestinationSelected: _chonTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Tìm phòng',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Hóa đơn',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Sự cố',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  Widget _taoDrawer() {
    final ten = ApiService.instance.hoTen;
    final email = ApiService.instance.email;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDam],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.apartment_rounded,
                          color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        '555Rental Khách',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white24,
                        child: Text(
                          ten.trim().isEmpty
                              ? 'K'
                              : ten.trim().substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _MucDrawer(
              icon: Icons.home_outlined,
              nhan: 'Trang chủ',
              chon: _chiSo == 0,
              onTap: () => _chonTuDrawer(0),
            ),
            _MucDrawer(
              icon: Icons.search_outlined,
              nhan: 'Tìm phòng',
              chon: _chiSo == 1,
              onTap: () => _chonTuDrawer(1),
            ),
            _MucDrawer(
              icon: Icons.receipt_long_outlined,
              nhan: 'Hóa đơn',
              chon: _chiSo == 2,
              onTap: () => _chonTuDrawer(2),
            ),
            _MucDrawer(
              icon: Icons.build_outlined,
              nhan: 'Sự cố',
              chon: _chiSo == 3,
              onTap: () => _chonTuDrawer(3),
            ),
            _MucDrawer(
              icon: Icons.person_outline,
              nhan: 'Tài khoản',
              chon: _chiSo == 4,
              onTap: () => _chonTuDrawer(4),
            ),
            const Divider(height: 1),
            _MucDrawer(
              icon: Icons.description_outlined,
              nhan: 'Hợp đồng thuê',
              onTap: () {
                Navigator.of(context).pop();
                _mo(const ContractsScreen());
              },
            ),
            _MucDrawer(
              icon: Icons.event_available_outlined,
              nhan: 'Lịch xem phòng',
              onTap: () {
                Navigator.of(context).pop();
                _mo(const MyBookingsScreen());
              },
            ),
            _MucDrawer(
              icon: Icons.payments_outlined,
              nhan: 'Lịch sử thanh toán',
              onTap: () {
                Navigator.of(context).pop();
                _mo(const PaymentHistoryScreen());
              },
            ),
            _MucDrawer(
              icon: Icons.notifications_active_outlined,
              nhan: 'Nhắc hạn',
              onTap: () {
                Navigator.of(context).pop();
                _moNhacHan();
              },
            ),
            const Divider(height: 1),
            _MucDrawer(
              icon: Icons.link,
              nhan: 'Địa chỉ API',
              onTap: () {
                Navigator.of(context).pop();
                _mo(const ApiSettingsScreen());
              },
            ),
            _MucDrawer(
              icon: Icons.logout,
              nhan: 'Đăng xuất',
              mauChu: AppColors.nguyHiem,
              onTap: () {
                Navigator.of(context).pop();
                _dangXuat();
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Text(
                'Đồ án INT4211 – Nhóm 555\nĐề 12: Hệ thống quản lý nhà trọ',
                style: TextStyle(fontSize: 11, color: AppColors.chuMo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MucDrawer extends StatelessWidget {
  const _MucDrawer({
    required this.icon,
    required this.nhan,
    required this.onTap,
    this.chon = false,
    this.mauChu,
  });

  final IconData icon;
  final String nhan;
  final VoidCallback onTap;
  final bool chon;
  final Color? mauChu;

  @override
  Widget build(BuildContext context) {
    final mau = mauChu ?? (chon ? AppColors.brand : AppColors.chu);
    return ListTile(
      onTap: onTap,
      selected: chon,
      selectedTileColor: AppColors.brandNhat,
      leading: Icon(icon, size: 21, color: mau),
      title: Text(
        nhan,
        style: TextStyle(
          fontSize: 14,
          fontWeight: chon ? FontWeight.w700 : FontWeight.w500,
          color: mau,
        ),
      ),
    );
  }
}
