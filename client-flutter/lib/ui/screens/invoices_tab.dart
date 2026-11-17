import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../core/dinh_dang.dart';
import '../../models/hoa_don.dart';
import '../theme.dart';
import '../widgets/trang_thai.dart';
import 'invoice_detail_screen.dart';
import 'payment_history_screen.dart';

/// Tab Hóa đơn: tổng nợ, lọc theo trạng thái và danh sách hóa đơn của người
/// thuê (GET /hoa-don/cua-toi). Chạm vào một hóa đơn để xem chi tiết/thanh toán.
class InvoicesTab extends StatefulWidget {
  const InvoicesTab({super.key});

  @override
  State<InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<InvoicesTab> {
  late Future<List<HoaDon>> _future;
  String _loc = 'TAT_CA';

  @override
  void initState() {
    super.initState();
    _future = _taiDanhSach();
  }

  Future<List<HoaDon>> _taiDanhSach() async {
    final duLieu = await ApiService.instance.get('/hoa-don/cua-toi');
    if (duLieu is! List) {
      return const [];
    }
    final ds = duLieu
        .whereType<Map<String, dynamic>>()
        .map(HoaDon.tuJson)
        .toList()
      ..sort((a, b) => b.thang.compareTo(a.thang));
    return ds;
  }

  void _taiLai() {
    setState(() {
      _future = _taiDanhSach();
    });
  }

  List<HoaDon> _apDungLoc(List<HoaDon> ds) {
    switch (_loc) {
      case 'CON_NO':
        return ds.where((e) => e.conNo > 0).toList();
      case 'DA_DU':
        return ds.where((e) => e.conNo <= 0).toList();
      default:
        return ds;
    }
  }

  Future<void> _moChiTiet(HoaDon hoaDon) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => InvoiceDetailScreen(hoaDonId: hoaDon.id),
      ),
    );
    if (mounted) {
      _taiLai();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HoaDon>>(
      future: _future,
      builder: (context, snapshot) {
        final tatCa = snapshot.data ?? const <HoaDon>[];
        final conNo = tatCa
            .where((e) => e.conNo > 0)
            .fold<int>(0, (tong, e) => tong + e.conNo);
        final dangTai = snapshot.connectionState == ConnectionState.waiting;
        final dsLoc = _apDungLoc(tatCa);

        return Column(
          children: [
            _dauTrang(conNo, tatCa.length, dangTai),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (dangTai) {
                    return const KhungDangTai(thongDiep: 'Đang tải hóa đơn…');
                  }
                  if (snapshot.hasError) {
                    final loi = snapshot.error;
                    return ManHinhLoi(
                      thongDiep: loi is ApiException
                          ? loi.thongDiep
                          : 'Không kết nối được máy chủ.',
                      onThuLai: _taiLai,
                    );
                  }
                  if (dsLoc.isEmpty) {
                    return MucRong(
                      icon: Icons.receipt_long_outlined,
                      tieuDe: tatCa.isEmpty
                          ? 'Chưa có hóa đơn'
                          : 'Không có hóa đơn ở mục này',
                      moTa: tatCa.isEmpty
                          ? 'Hóa đơn hằng tháng sẽ xuất hiện sau khi chủ trọ phát hành.'
                          : 'Thử chọn bộ lọc khác để xem các hóa đơn còn lại.',
                      nhanNut: 'Tải lại',
                      onNhan: _taiLai,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      _taiLai();
                      await _future;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: dsLoc.length,
                      itemBuilder: (context, chiSo) => _TheHoaDon(
                        hoaDon: dsLoc[chiSo],
                        onTap: () => _moChiTiet(dsLoc[chiSo]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dauTrang(int conNo, int soHoaDon, bool dangTai) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng còn nợ',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.chuMo,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DinhDang.tien(conNo),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: conNo > 0
                            ? AppColors.nguyHiem
                            : AppColors.thanhCong,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dangTai ? 'Đang đồng bộ…' : '$soHoaDon hóa đơn',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.chuMo,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: 'Tải lại',
                    onPressed: dangTai ? null : _taiLai,
                    icon: const Icon(Icons.refresh, color: AppColors.brand),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const PaymentHistoryScreen(),
                        ),
                      );
                      if (mounted) {
                        _taiLai();
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                    ),
                    child: const Text(
                      'Lịch sử\nthanh toán',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ChipLoc(
                nhan: 'Tất cả',
                chon: _loc == 'TAT_CA',
                onTap: () => setState(() => _loc = 'TAT_CA'),
              ),
              const SizedBox(width: 8),
              _ChipLoc(
                nhan: 'Còn nợ',
                chon: _loc == 'CON_NO',
                onTap: () => setState(() => _loc = 'CON_NO'),
              ),
              const SizedBox(width: 8),
              _ChipLoc(
                nhan: 'Đã đủ',
                chon: _loc == 'DA_DU',
                onTap: () => setState(() => _loc = 'DA_DU'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipLoc extends StatelessWidget {
  const _ChipLoc({
    required this.nhan,
    required this.chon,
    required this.onTap,
  });

  final String nhan;
  final bool chon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(nhan),
      selected: chon,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

class _TheHoaDon extends StatelessWidget {
  const _TheHoaDon({required this.hoaDon, required this.onTap});

  final HoaDon hoaDon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quaHan = hoaDon.conNo > 0 && hoaDon.soNgayConLai < 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
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
                          fontSize: 14.5,
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
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    hoaDon.tenKhu,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.chuMo,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                            'Đã thu ${DinhDang.tien(hoaDon.daThu)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.chuMo,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (hoaDon.conNoTien)
                          Text(
                            'Còn ${DinhDang.tien(hoaDon.conNo)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: quaHan
                                  ? AppColors.nguyHiem
                                  : AppColors.canhBao,
                            ),
                          )
                        else
                          const Text(
                            'Đã thanh toán đủ',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.thanhCong,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          quaHan
                              ? 'Quá hạn ${-hoaDon.soNgayConLai} ngày'
                              : 'Hạn ${DinhDang.ngay(hoaDon.hanThanhToan)}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: quaHan
                                ? AppColors.nguyHiem
                                : AppColors.chuMo,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
