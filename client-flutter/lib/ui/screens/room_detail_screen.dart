import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../core/dinh_dang.dart';
import '../../models/phong.dart';
import '../theme.dart';
import '../widgets/anh_mang.dart';
import '../widgets/trang_thai.dart';
import 'booking_screen.dart';

/// Chi tiết phòng: ảnh lớn, thông tin thuê, bảng giá điện nước, tiện ích và nút
/// đặt lịch xem phòng.
///
/// Dữ liệu lấy mới từ GET /phong/:id (có thêm tên/SĐT chủ trọ so với danh sách).
/// Khi đặt lịch thành công, màn này `Navigator.pop(true)` để tab Tìm phòng tải
/// lại danh sách phòng trống.
class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key, required this.phong});

  /// Dữ liệu từ danh sách, dùng để hiển thị ngay trong lúc chờ API chi tiết.
  final Phong phong;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Future<Phong> _futureChiTiet;

  @override
  void initState() {
    super.initState();
    _futureChiTiet = _taiChiTiet();
  }

  Future<Phong> _taiChiTiet() async {
    final duLieu = await ApiService.instance.get('/phong/${widget.phong.id}');
    if (duLieu is Map) {
      return Phong.tuJson(Map<String, dynamic>.from(duLieu));
    }
    throw const ApiException('Máy chủ trả dữ liệu phòng không hợp lệ.');
  }

  void _thuLai() {
    setState(() {
      _futureChiTiet = _taiChiTiet();
    });
  }

  Future<void> _datLich(Phong phong) async {
    final daDat = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => BookingScreen(phong: phong)),
    );
    if (!mounted) {
      return;
    }
    if (daDat == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Phòng ${widget.phong.soPhong}')),
      body: FutureBuilder<Phong>(
        future: _futureChiTiet,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const KhungDangTai(thongDiep: 'Đang tải chi tiết phòng…');
          }
          if (snapshot.hasError) {
            final loi = snapshot.error;
            return ManHinhLoi(
              thongDiep: loi is ApiException
                  ? loi.thongDiep
                  : 'Không tải được chi tiết phòng.',
              onThuLai: _thuLai,
            );
          }
          final phong = snapshot.data ?? widget.phong;
          return _noiDung(phong);
        },
      ),
    );
  }

  Widget _noiDung(Phong phong) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            children: [
              AnhMang(
                url: phong.anhUrl,
                chieuCao: 220,
                boGoc: 18,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phòng ${phong.soPhong}',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${phong.tenKhu} · ${phong.diaChi}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.chuMo,
                          ),
                        ),
                        Text(
                          phong.phuongXa,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.chuMo,
                          ),
                        ),
                      ],
                    ),
                  ),
                  NhanTrangThai(
                    ma: phong.trangThai,
                    nhan: phong.nhanTrangThai,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    DinhDang.tien(phong.giaThue),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand,
                    ),
                  ),
                  const Text(
                    '/tháng',
                    style: TextStyle(fontSize: 13, color: AppColors.chuMo),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      DongThongTin(
                        nhan: 'Diện tích',
                        giaTri: '${phong.dienTich.toStringAsFixed(1)} m²',
                        icon: Icons.crop_free,
                      ),
                      DongThongTin(
                        nhan: 'Sức chứa',
                        giaTri: 'Tối đa ${phong.sucChua} người',
                        icon: Icons.groups_outlined,
                      ),
                      DongThongTin(
                        nhan: 'Khu trọ',
                        giaTri: phong.tenKhu,
                        icon: Icons.apartment_outlined,
                      ),
                      if (phong.tenChuTro.isNotEmpty)
                        DongThongTin(
                          nhan: 'Chủ trọ',
                          giaTri: phong.tenChuTro,
                          icon: Icons.person_outline,
                        ),
                      if (phong.sdtChuTro.isNotEmpty)
                        DongThongTin(
                          nhan: 'Điện thoại chủ trọ',
                          giaTri: phong.sdtChuTro,
                          icon: Icons.call_outlined,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Chi phí hằng tháng',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      DongThongTin(
                        nhan: 'Giá điện',
                        giaTri: '${DinhDang.tien(phong.giaDien)}/kWh',
                      ),
                      DongThongTin(
                        nhan: 'Giá nước',
                        giaTri: '${DinhDang.tien(phong.giaNuoc)}/m³',
                      ),
                      DongThongTin(
                        nhan: 'Phí rác',
                        giaTri: '${DinhDang.tien(phong.phiRac)}/tháng',
                      ),
                      DongThongTin(
                        nhan: 'Phí gửi xe',
                        giaTri: '${DinhDang.tien(phong.phiGuiXe)}/tháng',
                      ),
                      const Divider(height: 16),
                      const Text(
                        'Tiền điện, nước tính theo chỉ số đồng hồ chủ trọ ghi hằng tháng.',
                        style: TextStyle(fontSize: 12, color: AppColors.chuMo),
                      ),
                    ],
                  ),
                ),
              ),
              if (phong.dsTienIch.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Tiện ích',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: phong.dsTienIch
                      .map(
                        (tienIch) => Chip(
                          avatar: const Icon(Icons.check_circle_outline,
                              size: 16, color: AppColors.thanhCong),
                          label: Text(tienIch),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandNhat,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.brand),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đặt lịch xem phòng miễn phí. Chủ trọ sẽ xác nhận lịch và '
                        'liên hệ lại theo số điện thoại tài khoản của bạn.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.brand),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _thanhDatLich(phong),
      ],
    );
  }

  Widget _thanhDatLich(Phong phong) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.vien)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DinhDang.tien(phong.giaThue),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand,
                    ),
                  ),
                  const Text(
                    'mỗi tháng',
                    style: TextStyle(fontSize: 11.5, color: AppColors.chuMo),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: phong.conTrong ? () => _datLich(phong) : null,
                icon: const Icon(Icons.event_available),
                label: Text(
                  phong.conTrong ? 'Đặt lịch xem phòng' : 'Phòng đã được thuê',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
