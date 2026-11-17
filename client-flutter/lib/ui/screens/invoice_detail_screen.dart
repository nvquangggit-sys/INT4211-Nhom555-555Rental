import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../core/dinh_dang.dart';
import '../../models/hoa_don.dart';
import '../../models/thanh_toan.dart';
import '../theme.dart';
import '../widgets/anh_mang.dart';
import '../widgets/trang_thai.dart';
import 'payment_screen.dart';

/// Chi tiết một hóa đơn: các khoản, chỉ số điện nước, lịch sử thanh toán và nút
/// gửi xác nhận chuyển khoản.
///
/// Backend không có endpoint xem 1 hóa đơn cho người thuê nên màn này tải lại
/// GET /hoa-don/cua-toi rồi lọc theo id (đảm bảo dữ liệu mới sau khi thanh toán).
class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({super.key, required this.hoaDonId});

  final int hoaDonId;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late Future<HoaDon> _future;

  @override
  void initState() {
    super.initState();
    _future = _taiHoaDon();
  }

  Future<HoaDon> _taiHoaDon() async {
    final duLieu = await ApiService.instance.get('/hoa-don/cua-toi');
    if (duLieu is List) {
      for (final dong in duLieu) {
        if (dong is Map && dong['id'] == widget.hoaDonId) {
          return HoaDon.tuJson(Map<String, dynamic>.from(dong));
        }
      }
      throw const ApiException('Không tìm thấy hóa đơn này.');
    }
    throw const ApiException('Máy chủ trả dữ liệu hóa đơn không hợp lệ.');
  }

  void _taiLai() {
    setState(() {
      _future = _taiHoaDon();
    });
  }

  Future<void> _moThanhToan(HoaDon hoaDon) async {
    final daGui = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => PaymentScreen(hoaDon: hoaDon)),
    );
    if (!mounted) {
      return;
    }
    if (daGui == true) {
      _taiLai();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hóa đơn'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _taiLai,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<HoaDon>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const KhungDangTai(thongDiep: 'Đang tải hóa đơn…');
          }
          if (snapshot.hasError) {
            final loi = snapshot.error;
            return ManHinhLoi(
              thongDiep: loi is ApiException
                  ? loi.thongDiep
                  : 'Không tải được hóa đơn.',
              onThuLai: _taiLai,
            );
          }
          final hoaDon = snapshot.data;
          if (hoaDon == null) {
            return MucRong(
              tieuDe: 'Không tìm thấy hóa đơn',
              nhanNut: 'Thử lại',
              onNhan: _taiLai,
            );
          }
          return _noiDung(hoaDon);
        },
      ),
    );
  }

  Widget _noiDung(HoaDon hoaDon) {
    return RefreshIndicator(
      onRefresh: () async {
        _taiLai();
        await _future;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _TieuDe(hoaDon: hoaDon),
          const SizedBox(height: 12),
          _BangNhacHan(hoaDon: hoaDon),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _DongTien(
                    nhan: 'Tổng tiền hóa đơn',
                    giaTri: DinhDang.tien(hoaDon.tongTien),
                    dam: true,
                  ),
                  _DongTien(
                    nhan: 'Đã thu',
                    giaTri: DinhDang.tien(hoaDon.daThu),
                    mau: AppColors.thanhCong,
                  ),
                  const Divider(height: 18),
                  _DongTien(
                    nhan: 'Còn nợ',
                    giaTri: DinhDang.tien(hoaDon.conNo),
                    dam: true,
                    mau: hoaDon.conNo > 0
                        ? AppColors.nguyHiem
                        : AppColors.thanhCong,
                    co: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _TieuDeMuc(
            tieuDe: 'Chi tiết các khoản',
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final chiTiet in hoaDon.chiTiet)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chiTiet.tenKhoan,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${_soLuong(chiTiet.soLuong)} × ${DinhDang.tien(chiTiet.donGia)}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.chuMo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DinhDang.tien(chiTiet.thanhTien),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hoaDon.chiTiet.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Hóa đơn chưa có chi tiết khoản.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.chuMo),
                      ),
                    ),
                  const Divider(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tổng cộng',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        DinhDang.tien(hoaDon.tongTien),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _TieuDeMuc(
            tieuDe: 'Chỉ số điện nước',
            icon: Icons.electric_meter_outlined,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _ChiSo(
                    nhan: 'Điện (kWh)',
                    dau: hoaDon.dienDau,
                    cuoi: hoaDon.dienCuoi,
                    tieuThu: hoaDon.tieuThuDien,
                    icon: Icons.bolt,
                  ),
                  const Divider(height: 18),
                  _ChiSo(
                    nhan: 'Nước (m³)',
                    dau: hoaDon.nuocDau,
                    cuoi: hoaDon.nuocCuoi,
                    tieuThu: hoaDon.tieuThuNuoc,
                    icon: Icons.water_drop_outlined,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _TieuDeMuc(
            tieuDe: 'Lịch sử thanh toán hóa đơn này',
            icon: Icons.history,
          ),
          const SizedBox(height: 8),
          if (hoaDon.thanhToan.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Chưa có lần thanh toán nào cho hóa đơn này.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.chuMo),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final thanhToan in hoaDon.thanhToan)
                    _DongThanhToan(thanhToan: thanhToan),
                ],
              ),
            ),
          const SizedBox(height: 18),
          if (hoaDon.conNoTien)
            FilledButton.icon(
              onPressed: () => _moThanhToan(hoaDon),
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(
                'Gửi xác nhận thanh toán ${DinhDang.tien(hoaDon.conNo)}',
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.thanhCongNen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_outlined, color: AppColors.thanhCong),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hóa đơn đã được thanh toán đủ. Cảm ơn bạn!',
                      style:
                          TextStyle(fontSize: 12.5, color: AppColors.thanhCong),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Sau khi gửi biên lai, chủ trọ kiểm tra và xác nhận trong App Admin. '
            'Số tiền đã thu sẽ cập nhật lại trên hóa đơn.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.chuMo),
          ),
        ],
      ),
    );
  }

  String _soLuong(double soLuong) {
    if (soLuong == soLuong.roundToDouble()) {
      return soLuong.toStringAsFixed(0);
    }
    return soLuong.toStringAsFixed(1);
  }
}

class _TieuDe extends StatelessWidget {
  const _TieuDe({required this.hoaDon});

  final HoaDon hoaDon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hóa đơn ${DinhDang.thang(hoaDon.thang)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Phòng ${hoaDon.soPhong} · ${hoaDon.tenKhu}',
                style: const TextStyle(fontSize: 13, color: AppColors.chuMo),
              ),
              Text(
                'Hạn thanh toán: ${DinhDang.ngay(hoaDon.hanThanhToan)}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.chuMo),
              ),
            ],
          ),
        ),
        NhanTrangThai(ma: hoaDon.trangThai, nhan: hoaDon.nhanTrangThai),
      ],
    );
  }
}

class _BangNhacHan extends StatelessWidget {
  const _BangNhacHan({required this.hoaDon});

  final HoaDon hoaDon;

  @override
  Widget build(BuildContext context) {
    if (!hoaDon.conNoTien) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.thanhCongNen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Hóa đơn đã thanh toán đủ.',
          style: TextStyle(fontSize: 12.5, color: AppColors.thanhCong),
        ),
      );
    }

    final soNgay = hoaDon.soNgayConLai;
    final quaHan = soNgay < 0;
    final mau = quaHan
        ? AppColors.nguyHiem
        : soNgay <= 5
            ? AppColors.canhBao
            : AppColors.thongTin;
    final nen = quaHan
        ? AppColors.nguyHiemNen
        : soNgay <= 5
            ? AppColors.canhBaoNen
            : AppColors.thongTinNen;
    final thongDiep = quaHan
        ? 'Hóa đơn đã quá hạn ${-soNgay} ngày. Vui lòng thanh toán sớm để '
            'tránh bị nhắc nợ.'
        : soNgay == 0
            ? 'Hôm nay là ngày đến hạn thanh toán.'
            : 'Còn $soNgay ngày đến hạn thanh toán.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: nen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            quaHan ? Icons.warning_amber_rounded : Icons.alarm,
            size: 20,
            color: mau,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              thongDiep,
              style: TextStyle(fontSize: 12.5, color: mau, height: 1.35),
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

class _DongTien extends StatelessWidget {
  const _DongTien({
    required this.nhan,
    required this.giaTri,
    this.dam = false,
    this.mau,
    this.co = 14,
  });

  final String nhan;
  final String giaTri;
  final bool dam;
  final Color? mau;
  final double co;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              nhan,
              style: TextStyle(
                fontSize: 13.5,
                color: dam ? AppColors.chu : AppColors.chuMo,
                fontWeight: dam ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            giaTri,
            style: TextStyle(
              fontSize: co,
              fontWeight: dam ? FontWeight.w800 : FontWeight.w600,
              color: mau ?? AppColors.chu,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChiSo extends StatelessWidget {
  const _ChiSo({
    required this.nhan,
    required this.dau,
    required this.cuoi,
    required this.tieuThu,
    required this.icon,
  });

  final String nhan;
  final int dau;
  final int cuoi;
  final int tieuThu;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brand),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nhan,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Chỉ số đầu: $dau · Chỉ số cuối: $cuoi',
                style: const TextStyle(fontSize: 12, color: AppColors.chuMo),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$tieuThu',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.brand,
              ),
            ),
            const Text(
              'tiêu thụ',
              style: TextStyle(fontSize: 11, color: AppColors.chuMo),
            ),
          ],
        ),
      ],
    );
  }
}

class _DongThanhToan extends StatelessWidget {
  const _DongThanhToan({required this.thanhToan});

  final ThanhToan thanhToan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            thanhToan.daXacNhan
                ? Icons.check_circle_outline
                : Icons.hourglass_top,
            size: 20,
            color: thanhToan.daXacNhan
                ? AppColors.thanhCong
                : AppColors.canhBao,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DinhDang.tien(thanhToan.soTien)} · ${thanhToan.nhanHinhThuc}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${DinhDang.ngayGio(thanhToan.thoiDiem)} · '
                  '${thanhToan.daXacNhan ? 'Chủ trọ đã xác nhận' : 'Chờ chủ trọ xác nhận'}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.chuMo,
                  ),
                ),
              ],
            ),
          ),
          if ((thanhToan.anhBienLai ?? '').isNotEmpty)
            GestureDetector(
              onTap: () => _xemAnh(context, thanhToan.anhBienLai!),
              child: AnhMang(
                url: thanhToan.anhBienLai,
                chieuCao: 44,
                chieuRong: 44,
                boGoc: 8,
              ),
            ),
        ],
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
                      'Biên lai chuyển khoản',
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
