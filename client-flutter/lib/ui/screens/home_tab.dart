import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../core/dinh_dang.dart';
import '../../models/hoa_don.dart';
import '../../models/hop_dong.dart';
import '../../models/nhac_han.dart';
import '../theme.dart';
import '../widgets/anh_mang.dart';
import '../widgets/trang_thai.dart';
import 'contracts_screen.dart';
import 'invoice_detail_screen.dart';
import 'reminders_screen.dart';

/// Tab Trang chủ: lời chào, banner nhắc hạn, lối tắt và tóm tắt hợp đồng/hóa đơn.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onMoTab});

  /// Đổi tab trong HomeShell (0 = trang chủ, 1 = tìm phòng, 2 = hóa đơn, 3 = sự cố).
  final void Function(int chiSo) onMoTab;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<NhacHan> _futureNhacHan;
  late Future<List<HopDong>> _futureHopDong;
  late Future<List<HoaDon>> _futureHoaDon;

  @override
  void initState() {
    super.initState();
    _taiLai();
  }

  void _taiLai() {
    setState(() {
      _futureNhacHan = _layNhacHan();
      _futureHopDong = _layHopDong();
      _futureHoaDon = _layHoaDon();
    });
  }

  Future<NhacHan> _layNhacHan() async {
    final duLieu = await ApiService.instance.get('/nhac-han');
    if (duLieu is Map) {
      return NhacHan.tuJson(Map<String, dynamic>.from(duLieu));
    }
    return const NhacHan();
  }

  Future<List<HopDong>> _layHopDong() async {
    final duLieu = await ApiService.instance.get('/hop-dong/cua-toi');
    if (duLieu is List) {
      return duLieu
          .whereType<Map<String, dynamic>>()
          .map(HopDong.tuJson)
          .toList();
    }
    return const [];
  }

  Future<List<HoaDon>> _layHoaDon() async {
    final duLieu = await ApiService.instance.get('/hoa-don/cua-toi');
    if (duLieu is List) {
      return duLieu
          .whereType<Map<String, dynamic>>()
          .map(HoaDon.tuJson)
          .toList();
    }
    return const [];
  }

  Future<void> _keoDeTaiLai() async {
    setState(() {
      _futureNhacHan = _layNhacHan();
      _futureHopDong = _layHopDong();
      _futureHoaDon = _layHoaDon();
    });
    try {
      await Future.wait([_futureNhacHan, _futureHopDong, _futureHoaDon]);
    } catch (_) {
      // Lỗi đã được từng FutureBuilder hiển thị.
    }
  }

  void _moChiTietHoaDon(HoaDon hoaDon) {
    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => InvoiceDetailScreen(hoaDonId: hoaDon.id),
          ),
        )
        .then((_) {
          if (mounted) {
            _taiLai();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _keoDeTaiLai,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _LoiChao(ten: ApiService.instance.hoTen),
          const SizedBox(height: 14),
          FutureBuilder<NhacHan>(
            future: _futureNhacHan,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _BannerDangTai();
              }
              if (snapshot.hasError) {
                return _BannerLoi(
                  thongDiep: _thongDiepLoi(snapshot.error),
                  onThuLai: _taiLai,
                );
              }
              final duLieu = snapshot.data ?? const NhacHan();
              return _BannerNhacHan(
                duLieu: duLieu,
                onXemTatCa: () async {
                  final daXem = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => const RemindersScreen(),
                    ),
                  );
                  if (!mounted) {
                    return;
                  }
                  if (daXem == true) {
                    _taiLai();
                  }
                },
                onMoHoaDon: () => widget.onMoTab(2),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn cần gì hôm nay?',
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TheSoLieu(
                  nhan: 'Tìm phòng',
                  giaTri: 'Xem phòng trống',
                  icon: Icons.search,
                  onTap: () => widget.onMoTab(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TheSoLieu(
                  nhan: 'Hợp đồng',
                  giaTri: 'Điều khoản thuê',
                  icon: Icons.description_outlined,
                  mau: AppColors.thongTin,
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const ContractsScreen(),
                      ),
                    );
                    if (mounted) {
                      _taiLai();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TheSoLieu(
                  nhan: 'Hóa đơn',
                  giaTri: 'Xem & thanh toán',
                  icon: Icons.receipt_long_outlined,
                  mau: AppColors.canhBao,
                  onTap: () => widget.onMoTab(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TheSoLieu(
                  nhan: 'Sự cố',
                  giaTri: 'Báo hỏng hóc',
                  icon: Icons.build_outlined,
                  mau: AppColors.nguyHiem,
                  onTap: () => widget.onMoTab(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hợp đồng của tôi',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const ContractsScreen(),
                    ),
                  );
                  if (mounted) {
                    _taiLai();
                  }
                },
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          FutureBuilder<List<HopDong>>(
            future: _futureHopDong,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 110,
                  child: KhungDangTai(thongDiep: 'Đang tải hợp đồng…'),
                );
              }
              if (snapshot.hasError) {
                return _BannerLoi(
                  thongDiep: _thongDiepLoi(snapshot.error),
                  onThuLai: _taiLai,
                );
              }
              final ds = snapshot.data ?? const [];
              if (ds.isEmpty) {
                return const _TheTrong(
                  icon: Icons.description_outlined,
                  tieuDe: 'Chưa có hợp đồng',
                  moTa: 'Khi chủ trọ lập hợp đồng, thông tin sẽ hiện ở đây.',
                );
              }
              final hopDong = ds.first;
              return _TheHopDong(
                hopDong: hopDong,
                onTap: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const ContractsScreen(),
                    ),
                  );
                  if (mounted) {
                    _taiLai();
                  }
                },
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hóa đơn gần nhất',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => widget.onMoTab(2),
                child: const Text('Tất cả hóa đơn'),
              ),
            ],
          ),
          FutureBuilder<List<HoaDon>>(
            future: _futureHoaDon,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: KhungDangTai(thongDiep: 'Đang tải hóa đơn…'),
                );
              }
              if (snapshot.hasError) {
                return _BannerLoi(
                  thongDiep: _thongDiepLoi(snapshot.error),
                  onThuLai: _taiLai,
                );
              }
              final ds = snapshot.data ?? const [];
              if (ds.isEmpty) {
                return const _TheTrong(
                  icon: Icons.receipt_long_outlined,
                  tieuDe: 'Chưa có hóa đơn',
                  moTa: 'Hóa đơn tháng sẽ xuất hiện sau khi chủ trọ phát hành.',
                );
              }
              final hoaDon = ds.first;
              return _TheHoaDon(
                hoaDon: hoaDon,
                onTap: () => _moChiTietHoaDon(hoaDon),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _thongDiepLoi(Object? loi) {
  if (loi is ApiException) {
    return loi.thongDiep;
  }
  return 'Không kết nối được máy chủ. Kéo xuống để thử lại.';
}

class _LoiChao extends StatelessWidget {
  const _LoiChao({required this.ten});

  final String ten;

  @override
  Widget build(BuildContext context) {
    final gio = DateTime.now().hour;
    final loiChao = gio < 11
        ? 'Chào buổi sáng'
        : gio < 14
            ? 'Chào buổi trưa'
            : gio < 18
                ? 'Chào buổi chiều'
                : 'Chào buổi tối';
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.brandNhat,
          child: Text(
            ten.trim().isEmpty ? 'K' : ten.trim().substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
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
                '$loiChao,',
                style: const TextStyle(fontSize: 13, color: AppColors.chuMo),
              ),
              Text(
                ten,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BannerDangTai extends StatelessWidget {
  const _BannerDangTai();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: AppColors.brandNhat,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

class _BannerLoi extends StatelessWidget {
  const _BannerLoi({required this.thongDiep, required this.onThuLai});

  final String thongDiep;
  final VoidCallback onThuLai;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.nguyHiemNen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.nguyHiem),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              thongDiep,
              style: const TextStyle(fontSize: 12.5, color: AppColors.nguyHiem),
            ),
          ),
          TextButton(onPressed: onThuLai, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _BannerNhacHan extends StatelessWidget {
  const _BannerNhacHan({
    required this.duLieu,
    required this.onXemTatCa,
    required this.onMoHoaDon,
  });

  final NhacHan duLieu;
  final VoidCallback onXemTatCa;
  final VoidCallback onMoHoaDon;

  @override
  Widget build(BuildContext context) {
    if (duLieu.rong) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.thanhCongNen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_outlined, color: AppColors.thanhCong),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bạn không có khoản nào sắp đến hạn. Mọi thứ đang ổn!',
                style:
                    TextStyle(fontSize: 12.5, color: AppColors.thanhCong),
              ),
            ),
          ],
        ),
      );
    }

    final hoaDon = duLieu.hoaDon.isNotEmpty ? duLieu.hoaDon.first : null;
    final hopDong = duLieu.hopDong.isNotEmpty ? duLieu.hopDong.first : null;
    final quaHan = hoaDon != null && hoaDon.quaHan;

    return InkWell(
      onTap: onXemTatCa,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: quaHan ? AppColors.nguyHiemNen : AppColors.canhBaoNen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  quaHan ? Icons.warning_amber_rounded : Icons.notifications_active_outlined,
                  color: quaHan ? AppColors.nguyHiem : AppColors.canhBao,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bạn có ${duLieu.soViecCanLam} việc cần xử lý',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: quaHan ? AppColors.nguyHiem : AppColors.canhBao,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: quaHan ? AppColors.nguyHiem : AppColors.canhBao),
              ],
            ),
            if (hoaDon != null) ...[
              const SizedBox(height: 6),
              Text(
                'Hóa đơn ${DinhDang.thang(hoaDon.thang)} ${DinhDang.nhacHan(hoaDon.soNgayConLai)}'
                ' • còn nợ ${DinhDang.tien(hoaDon.conNo)}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.chu),
              ),
            ],
            if (hopDong != null) ...[
              const SizedBox(height: 4),
              Text(
                'Hợp đồng phòng ${hopDong.soPhong} ${DinhDang.nhacHan(hopDong.soNgayConLai)}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.chu),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (hoaDon != null)
                  TextButton(
                    onPressed: onMoHoaDon,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Xem hóa đơn'),
                  ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: onXemTatCa,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Xem nhắc hạn'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TheTrong extends StatelessWidget {
  const _TheTrong({
    required this.icon,
    required this.tieuDe,
    required this.moTa,
  });

  final IconData icon;
  final String tieuDe;
  final String moTa;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.chuMo),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tieuDe,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    moTa,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.chuMo),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TheHopDong extends StatelessWidget {
  const _TheHopDong({required this.hopDong, required this.onTap});

  final HopDong hopDong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnhMang(
                    url: hopDong.anhUrl,
                    chieuCao: 64,
                    chieuRong: 64,
                    boGoc: 12,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Phòng ${hopDong.soPhong} · ${hopDong.tenKhu}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            NhanTrangThai(
                              ma: hopDong.trangThai,
                              nhan: hopDong.nhanTrangThai,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DinhDang.tien(hopDong.giaThue)}/tháng · cọc ${DinhDang.tien(hopDong.tienCoc)}',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.chuMo),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hết hạn ${DinhDang.ngay(hopDong.ketThuc)} '
                          '(${DinhDang.nhacHan(_soNgayHopDong(hopDong))})',
                          style: TextStyle(
                            fontSize: 12,
                            color: hopDong.sapHetHan
                                ? AppColors.canhBao
                                : AppColors.chuMo,
                            fontWeight: hopDong.sapHetHan
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hopDong.sapHetHan) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.canhBaoNen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Hợp đồng sắp hết hạn (${DinhDang.nhacHan(hopDong.soNgayConLai)}). '
                    'Liên hệ chủ trọ để gia hạn.',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.canhBao),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

int _soNgayHopDong(HopDong hopDong) {
  if (hopDong.soNgayConLai != 0) {
    return hopDong.soNgayConLai;
  }
  return DinhDang.soNgayConLai(hopDong.ketThuc);
}

class _TheHoaDon extends StatelessWidget {
  const _TheHoaDon({required this.hoaDon, required this.onTap});

  final HoaDon hoaDon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${DinhDang.thang(hoaDon.thang)} · Phòng ${hoaDon.soPhong}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  NhanTrangThai(
                    ma: hoaDon.trangThai,
                    nhan: hoaDon.nhanTrangThai,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DinhDang.tien(hoaDon.tongTien),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brand,
                          ),
                        ),
                        Text(
                          'Hạn ${DinhDang.ngay(hoaDon.hanThanhToan)} · '
                          '${DinhDang.nhacHan(hoaDon.soNgayConLai)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.chuMo),
                        ),
                      ],
                    ),
                  ),
                  if (hoaDon.conNoTien)
                    Text(
                      'Còn nợ ${DinhDang.tien(hoaDon.conNo)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.nguyHiem,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab tìm phòng (RoomsTab) và tab hóa đơn (InvoicesTab) được khai báo ở file
/// riêng và nhúng trong HomeShell.
