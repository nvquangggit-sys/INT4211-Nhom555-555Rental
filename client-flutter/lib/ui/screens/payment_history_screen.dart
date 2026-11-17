import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../core/dinh_dang.dart';
import '../../models/thanh_toan.dart';
import '../theme.dart';
import '../widgets/anh_mang.dart';
import '../widgets/trang_thai.dart';

/// Lịch sử thanh toán của người thuê (GET /thanh-toan/cua-toi).
///
/// Mỗi dòng cho biết số tiền, hóa đơn tương ứng, hình thức, trạng thái xác nhận
/// và ảnh biên lai (chạm để xem lớn).
class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late Future<List<ThanhToan>> _future;
  String _loc = 'TAT_CA';

  @override
  void initState() {
    super.initState();
    _future = _taiDanhSach();
  }

  Future<List<ThanhToan>> _taiDanhSach() async {
    final duLieu = await ApiService.instance.get('/thanh-toan/cua-toi');
    if (duLieu is! List) {
      return const [];
    }
    final ds = duLieu
        .whereType<Map<String, dynamic>>()
        .map(ThanhToan.tuJson)
        .toList()
      ..sort((a, b) {
        final ta = a.thoiDiem ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.thoiDiem ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
    return ds;
  }

  void _taiLai() {
    setState(() {
      _future = _taiDanhSach();
    });
  }

  List<ThanhToan> _locDs(List<ThanhToan> ds) {
    switch (_loc) {
      case 'DA_XAC_NHAN':
        return ds.where((e) => e.daXacNhan).toList();
      case 'CHO_XAC_NHAN':
        return ds.where((e) => !e.daXacNhan).toList();
      default:
        return ds;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử thanh toán'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _taiLai,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<ThanhToan>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const KhungDangTai(thongDiep: 'Đang tải lịch sử…');
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
          final tatCa = snapshot.data ?? const [];
          if (tatCa.isEmpty) {
            return MucRong(
              icon: Icons.history,
              tieuDe: 'Chưa có giao dịch nào',
              moTa: 'Khi bạn gửi xác nhận thanh toán, giao dịch sẽ hiện tại đây.',
              nhanNut: 'Tải lại',
              onNhan: _taiLai,
            );
          }
          final ds = _locDs(tatCa);
          final daXacNhan = tatCa.where((e) => e.daXacNhan).length;
          final choXacNhan = tatCa.length - daXacNhan;
          return Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    _ChipLoc(
                      nhan: 'Tất cả (${tatCa.length})',
                      chon: _loc == 'TAT_CA',
                      onTap: () => setState(() => _loc = 'TAT_CA'),
                    ),
                    const SizedBox(width: 8),
                    _ChipLoc(
                      nhan: 'Đã xác nhận ($daXacNhan)',
                      chon: _loc == 'DA_XAC_NHAN',
                      onTap: () => setState(() => _loc = 'DA_XAC_NHAN'),
                    ),
                    const SizedBox(width: 8),
                    _ChipLoc(
                      nhan: 'Chờ ($choXacNhan)',
                      chon: _loc == 'CHO_XAC_NHAN',
                      onTap: () => setState(() => _loc = 'CHO_XAC_NHAN'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ds.isEmpty
                    ? const MucRong(
                        icon: Icons.filter_alt_off_outlined,
                        tieuDe: 'Không có giao dịch ở mục này',
                        moTa: 'Chọn bộ lọc khác để xem các giao dịch còn lại.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          _taiLai();
                          await _future;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: ds.length,
                          itemBuilder: (context, chiSo) => _TheGiaoDich(
                            thanhToan: ds[chiSo],
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
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
      label: Text(nhan, style: const TextStyle(fontSize: 12)),
      selected: chon,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

class _TheGiaoDich extends StatelessWidget {
  const _TheGiaoDich({required this.thanhToan});

  final ThanhToan thanhToan;

  @override
  Widget build(BuildContext context) {
    final daXacNhan = thanhToan.daXacNhan;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: daXacNhan
                          ? AppColors.thanhCongNen
                          : AppColors.canhBaoNen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      daXacNhan
                          ? Icons.check_circle_outline
                          : Icons.hourglass_top,
                      size: 20,
                      color: daXacNhan
                          ? AppColors.thanhCong
                          : AppColors.canhBao,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DinhDang.tien(thanhToan.soTien),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brand,
                          ),
                        ),
                        Text(
                          'Hóa đơn ${DinhDang.thang(thanhToan.thang)} · '
                          'Phòng ${thanhToan.soPhong}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.chuMo,
                          ),
                        ),
                        Text(
                          '${thanhToan.nhanHinhThuc} · '
                          '${DinhDang.ngayGio(thanhToan.thoiDiem)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.chuMo,
                          ),
                        ),
                      ],
                    ),
                  ),
                  NhanTrangThai(
                    ma: daXacNhan ? 'DA_THU' : 'CHO_XAC_NHAN',
                    nhan: daXacNhan ? 'Đã xác nhận' : 'Chờ xác nhận',
                  ),
                ],
              ),
              if (daXacNhan && thanhToan.tenNguoiXacNhan.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Xác nhận bởi ${thanhToan.tenNguoiXacNhan}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.chuMo,
                    ),
                  ),
                ),
              ],
              if ((thanhToan.anhBienLai ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _xemAnh(context, thanhToan.anhBienLai!),
                      child: AnhMang(
                        url: thanhToan.anhBienLai,
                        chieuCao: 64,
                        chieuRong: 64,
                        boGoc: 10,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Ảnh biên lai đính kèm — chạm để xem lớn.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.chuMo,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _xemAnh(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Biên lai thanh toán',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: AnhMang(url: url, chieuCao: 380, boGoc: 12),
            ),
          ],
        ),
      ),
    );
  }
}
