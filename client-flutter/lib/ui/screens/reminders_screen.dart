import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../core/dinh_dang.dart';
import '../../models/nhac_han.dart';
import '../theme.dart';
import '../widgets/trang_thai.dart';
import 'contracts_screen.dart';
import 'invoice_detail_screen.dart';

/// Màn hình nhắc hạn: hóa đơn sắp đến hạn/quá hạn và hợp đồng sắp hết hạn
/// (GET /nhac-han — backend tính sẵn `so_ngay_con_lai`).
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late Future<NhacHan> _future;

  @override
  void initState() {
    super.initState();
    _future = _taiDuLieu();
  }

  Future<NhacHan> _taiDuLieu() async {
    final duLieu = await ApiService.instance.get('/nhac-han');
    if (duLieu is Map) {
      return NhacHan.tuJson(Map<String, dynamic>.from(duLieu));
    }
    return const NhacHan();
  }

  Future<void> _taiLai() async {
    setState(() {
      _future = _taiDuLieu();
    });
    try {
      await _future;
    } catch (_) {
      // FutureBuilder hiển thị lỗi.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhắc hạn thanh toán'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _taiLai,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<NhacHan>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const KhungDangTai(thongDiep: 'Đang kiểm tra nhắc hạn…');
          }
          if (snapshot.hasError) {
            final loi = snapshot.error;
            return ManHinhLoi(
              thongDiep: loi is ApiException
                  ? loi.thongDiep
                  : 'Không tải được nhắc hạn.',
              onThuLai: _taiLai,
            );
          }
          final duLieu = snapshot.data ?? const NhacHan();
          if (duLieu.rong) {
            return RefreshIndicator(
              onRefresh: _taiLai,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  MucRong(
                    icon: Icons.task_alt,
                    tieuDe: 'Không có việc nào sắp đến hạn',
                    moTa: 'Hóa đơn và hợp đồng của bạn đều đang trong hạn an toàn.',
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _taiLai,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                _TongQuan(duLieu: duLieu),
                if (duLieu.hoaDon.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const _TieuDeMuc(
                    tieuDe: 'Hóa đơn cần thanh toán',
                    icon: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 8),
                  for (final hoaDon in duLieu.hoaDon)
                    _TheNhacHoaDon(
                      hoaDon: hoaDon,
                      onTap: () async {
                        await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) =>
                                InvoiceDetailScreen(hoaDonId: hoaDon.id),
                          ),
                        );
                        if (mounted) {
                          await _taiLai();
                        }
                      },
                    ),
                ],
                if (duLieu.hopDong.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const _TieuDeMuc(
                    tieuDe: 'Hợp đồng sắp hết hạn',
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 8),
                  for (final hopDong in duLieu.hopDong)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.event_note,
                            color: AppColors.canhBao),
                        title: Text(
                          'Phòng ${hopDong.soPhong} · ${hopDong.tenKhu}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'Hết hạn ${DinhDang.ngay(hopDong.ketThuc)} · '
                          '${DinhDang.nhacHan(hopDong.soNgayConLai)}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const ContractsScreen(),
                            ),
                          );
                          if (mounted) {
                            await _taiLai();
                          }
                        },
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TongQuan extends StatelessWidget {
  const _TongQuan({required this.duLieu});

  final NhacHan duLieu;

  @override
  Widget build(BuildContext context) {
    final coQuaHan = duLieu.hoaDon.any((e) => e.quaHan);
    final tongNo = duLieu.hoaDon.fold<int>(0, (tong, e) => tong + e.conNo);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: coQuaHan ? AppColors.nguyHiemNen : AppColors.canhBaoNen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            coQuaHan ? Icons.warning_amber_rounded : Icons.notifications_active,
            color: coQuaHan ? AppColors.nguyHiem : AppColors.canhBao,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${duLieu.soViecCanLam} việc cần xử lý',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: coQuaHan ? AppColors.nguyHiem : AppColors.canhBao,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tongNo > 0
                      ? 'Tổng còn nợ ${DinhDang.tien(tongNo)}'
                      : 'Không còn nợ hóa đơn nào',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Thanh toán đúng hạn giúp tránh phí phạt và gián đoạn dịch vụ.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.chuMo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TieuDeMuc extends StatelessWidget {
  const _TieuDeMuc({required this.tieuDe, required this.icon});

  final String tieuDe;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brand),
        const SizedBox(width: 6),
        Text(
          tieuDe,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TheNhacHoaDon extends StatelessWidget {
  const _TheNhacHoaDon({required this.hoaDon, required this.onTap});

  final NhacHanHoaDon hoaDon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quaHan = hoaDon.quaHan;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          quaHan ? Icons.error_outline : Icons.schedule,
          color: quaHan ? AppColors.nguyHiem : AppColors.canhBao,
        ),
        title: Text(
          'Hóa đơn ${DinhDang.thang(hoaDon.thang)} · Phòng ${hoaDon.soPhong}',
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Còn nợ ${DinhDang.tien(hoaDon.conNo)} · '
          '${DinhDang.nhacHan(hoaDon.soNgayConLai)}',
          style: TextStyle(
            fontSize: 12.5,
            color: quaHan ? AppColors.nguyHiem : AppColors.chuMo,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
