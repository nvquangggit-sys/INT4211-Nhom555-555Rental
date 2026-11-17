import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../core/dinh_dang.dart';
import '../../models/hop_dong.dart';
import '../theme.dart';
import '../widgets/anh_mang.dart';
import '../widgets/trang_thai.dart';

/// Màn hình "Hợp đồng thuê của tôi" (GET /hop-dong/cua-toi).
///
/// Hợp đồng còn ≤ 30 ngày sẽ hiện cảnh báo màu cam kèm hướng dẫn gia hạn và
/// thanh tiến trình thời hạn hợp đồng (yêu cầu C3 của đề).
class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  late Future<List<HopDong>> _future;

  @override
  void initState() {
    super.initState();
    _future = _taiDanhSach();
  }

  Future<List<HopDong>> _taiDanhSach() async {
    final duLieu = await ApiService.instance.get('/hop-dong/cua-toi');
    if (duLieu is! List) {
      return const [];
    }
    return duLieu
        .whereType<Map<String, dynamic>>()
        .map(HopDong.tuJson)
        .toList();
  }

  void _taiLai() {
    setState(() {
      _future = _taiDanhSach();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hợp đồng thuê của tôi'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _taiLai,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<HopDong>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const KhungDangTai(thongDiep: 'Đang tải hợp đồng…');
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
          final ds = snapshot.data ?? const [];
          if (ds.isEmpty) {
            return MucRong(
              icon: Icons.description_outlined,
              tieuDe: 'Chưa có hợp đồng thuê',
              moTa: 'Khi chủ trọ lập hợp đồng cho phòng bạn thuê, thông tin sẽ '
                  'xuất hiện tại đây.',
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              itemCount: ds.length,
              itemBuilder: (context, chiSo) =>
                  _TheHopDong(hopDong: ds[chiSo]),
            ),
          );
        },
      ),
    );
  }
}

class _TheHopDong extends StatelessWidget {
  const _TheHopDong({required this.hopDong});

  final HopDong hopDong;

  int get _soNgay {
    if (hopDong.soNgayConLai != 0) {
      return hopDong.soNgayConLai;
    }
    return DinhDang.soNgayConLai(hopDong.ketThuc);
  }

  double get _tienDo {
    final batDau = hopDong.batDau;
    final ketThuc = hopDong.ketThuc;
    if (batDau == null || ketThuc == null) {
      return 0;
    }
    final tong = ketThuc.difference(batDau).inSeconds;
    if (tong <= 0) {
      return 1;
    }
    final daQua = DateTime.now().difference(batDau).inSeconds;
    return (daQua / tong).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final sapHetHan = _soNgay >= 0 && _soNgay <= 30;
    final daHetHan = _soNgay < 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnhMang(
                    url: hopDong.anhUrl,
                    chieuCao: 72,
                    chieuRong: 80,
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
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            NhanTrangThai(
                              ma: hopDong.trangThai,
                              nhan: hopDong.nhanTrangThai,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hopDong.diaChi,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.chuMo,
                          ),
                        ),
                        Text(
                          hopDong.phuongXa,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.chuMo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.nen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Moc(
                            nhan: 'Bắt đầu',
                            giaTri: DinhDang.ngay(hopDong.batDau),
                          ),
                        ),
                        const Icon(Icons.arrow_forward,
                            size: 18, color: AppColors.chuMo),
                        Expanded(
                          child: _Moc(
                            nhan: 'Kết thúc',
                            giaTri: DinhDang.ngay(hopDong.ketThuc),
                            canhBao: sapHetHan || daHetHan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _tienDo,
                        minHeight: 8,
                        backgroundColor: AppColors.vien,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          daHetHan
                              ? AppColors.nguyHiem
                              : sapHetHan
                                  ? AppColors.canhBao
                                  : AppColors.brand,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${DinhDang.nhacHan(_soNgay)} (còn ${_soNgay < 0 ? 0 : _soNgay} ngày)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: daHetHan
                              ? AppColors.nguyHiem
                              : sapHetHan
                                  ? AppColors.canhBao
                                  : AppColors.chuMo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _OThongTin(
                      nhan: 'Giá thuê',
                      giaTri: DinhDang.tien(hopDong.giaThue),
                    ),
                  ),
                  Expanded(
                    child: _OThongTin(
                      nhan: 'Tiền cọc',
                      giaTri: DinhDang.tien(hopDong.tienCoc),
                    ),
                  ),
                  Expanded(
                    child: _OThongTin(
                      nhan: 'Số người',
                      giaTri: '${hopDong.soNguoi}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DongThongTin(
                nhan: 'Diện tích',
                giaTri: '${hopDong.dienTich.toStringAsFixed(1)} m²',
                icon: Icons.crop_free,
              ),
              DongThongTin(
                nhan: 'Chủ trọ',
                giaTri: hopDong.tenChuTro,
                icon: Icons.person_outline,
              ),
              DongThongTin(
                nhan: 'Điện thoại',
                giaTri: hopDong.sdtChuTro,
                icon: Icons.call_outlined,
              ),
              if (sapHetHan) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.canhBaoNen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 20, color: AppColors.canhBao),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hợp đồng sắp hết hạn (${DinhDang.nhacHan(_soNgay)}). '
                          'Vui lòng liên hệ chủ trọ ${hopDong.sdtChuTro} để gia hạn '
                          'trước ngày ${DinhDang.ngay(hopDong.ketThuc)}.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.canhBao,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (daHetHan) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.nguyHiemNen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Hợp đồng đã hết hạn ${-_soNgay} ngày. Liên hệ chủ trọ để '
                    'làm thủ tục gia hạn hoặc trả phòng.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.nguyHiem,
                    ),
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

class _Moc extends StatelessWidget {
  const _Moc({
    required this.nhan,
    required this.giaTri,
    this.canhBao = false,
  });

  final String nhan;
  final String giaTri;
  final bool canhBao;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nhan,
          style: const TextStyle(fontSize: 11.5, color: AppColors.chuMo),
        ),
        Text(
          giaTri,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: canhBao ? AppColors.canhBao : AppColors.chu,
          ),
        ),
      ],
    );
  }
}

class _OThongTin extends StatelessWidget {
  const _OThongTin({required this.nhan, required this.giaTri});

  final String nhan;
  final String giaTri;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nhan,
          style: const TextStyle(fontSize: 11.5, color: AppColors.chuMo),
        ),
        const SizedBox(height: 2),
        Text(
          giaTri,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
