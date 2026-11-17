import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../core/dinh_dang.dart';
import '../../models/su_co.dart';
import '../theme.dart';
import '../widgets/anh_mang.dart';
import '../widgets/trang_thai.dart';
import 'incident_create_screen.dart';

/// Tab Sự cố: theo dõi các báo cáo đã gửi và trạng thái xử lý của chủ trọ
/// (GET /bao-su-co/cua-toi). Nút FAB "Báo sự cố" nằm ở HomeShell.
class IncidentsTab extends StatefulWidget {
  const IncidentsTab({super.key});

  @override
  State<IncidentsTab> createState() => IncidentsTabState();
}

class IncidentsTabState extends State<IncidentsTab> {
  late Future<List<SuCo>> _future;
  String _loc = 'TAT_CA';

  @override
  void initState() {
    super.initState();
    _future = _taiDanhSach();
  }

  Future<List<SuCo>> _taiDanhSach() async {
    final duLieu = await ApiService.instance.get('/bao-su-co/cua-toi');
    if (duLieu is! List) {
      return const [];
    }
    final ds = duLieu
        .whereType<Map<String, dynamic>>()
        .map(SuCo.tuJson)
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    return ds;
  }

  /// Gọi được từ HomeShell (sau khi FAB gửi báo cáo thành công).
  Future<void> taiLai() async {
    setState(() {
      _future = _taiDanhSach();
    });
  }

  List<SuCo> _locDs(List<SuCo> ds) {
    switch (_loc) {
      case 'CHO_XU_LY':
        return ds
            .where((e) => e.trangThai == 'MOI' || e.trangThai == 'DANG_XU_LY')
            .toList();
      case 'DA_XU_LY':
        return ds.where((e) => e.trangThai == 'DA_XU_LY').toList();
      default:
        return ds;
    }
  }

  Future<void> _moForm() async {
    final daGui = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const IncidentCreateScreen()),
    );
    if (daGui == true && mounted) {
      await taiLai();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SuCo>>(
      future: _future,
      builder: (context, snapshot) {
        final tatCa = snapshot.data ?? const <SuCo>[];
        final dangXuLy = tatCa
            .where((e) => e.trangThai == 'MOI' || e.trangThai == 'DANG_XU_LY')
            .length;
        final daXuLy = tatCa.where((e) => e.trangThai == 'DA_XU_LY').length;
        final ds = _locDs(tatCa);

        return Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SoLieu(
                          nhan: 'Tổng báo cáo',
                          giaTri: '${tatCa.length}',
                          mau: AppColors.brand,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SoLieu(
                          nhan: 'Đang xử lý',
                          giaTri: '$dangXuLy',
                          mau: AppColors.canhBao,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SoLieu(
                          nhan: 'Đã xử lý',
                          giaTri: '$daXuLy',
                          mau: AppColors.thanhCong,
                        ),
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
                        nhan: 'Chờ xử lý',
                        chon: _loc == 'CHO_XU_LY',
                        onTap: () => setState(() => _loc = 'CHO_XU_LY'),
                      ),
                      const SizedBox(width: 8),
                      _ChipLoc(
                        nhan: 'Đã xử lý',
                        chon: _loc == 'DA_XU_LY',
                        onTap: () => setState(() => _loc = 'DA_XU_LY'),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Tải lại',
                        onPressed: taiLai,
                        icon: const Icon(Icons.refresh, color: AppColors.brand),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const KhungDangTai(thongDiep: 'Đang tải sự cố…');
                  }
                  if (snapshot.hasError) {
                    final loi = snapshot.error;
                    return ManHinhLoi(
                      thongDiep: loi is ApiException
                          ? loi.thongDiep
                          : 'Không kết nối được máy chủ.',
                      onThuLai: taiLai,
                    );
                  }
                  if (ds.isEmpty) {
                    return MucRong(
                      icon: Icons.build_circle_outlined,
                      tieuDe: tatCa.isEmpty
                          ? 'Chưa có báo cáo sự cố'
                          : 'Không có báo cáo ở mục này',
                      moTa: tatCa.isEmpty
                          ? 'Khi phòng gặp sự cố (điện, nước, khóa cửa…), hãy '
                              'gửi báo cáo để chủ trọ xử lý.'
                          : 'Chọn bộ lọc khác để xem các báo cáo còn lại.',
                      nhanNut: tatCa.isEmpty ? 'Báo sự cố' : 'Tải lại',
                      onNhan: tatCa.isEmpty ? _moForm : taiLai,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      await taiLai();
                      await _future;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      itemCount: ds.length,
                      itemBuilder: (context, chiSo) =>
                          _TheSuCo(suCo: ds[chiSo]),
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
}

class _SoLieu extends StatelessWidget {
  const _SoLieu({
    required this.nhan,
    required this.giaTri,
    required this.mau,
  });

  final String nhan;
  final String giaTri;
  final Color mau;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: mau.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            giaTri,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: mau,
            ),
          ),
          Text(
            nhan,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: AppColors.chuMo),
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
      label: Text(nhan, style: const TextStyle(fontSize: 12)),
      selected: chon,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

class _TheSuCo extends StatelessWidget {
  const _TheSuCo({required this.suCo});

  final SuCo suCo;

  @override
  Widget build(BuildContext context) {
    final daXuLy = suCo.trangThai == 'DA_XU_LY';
    final dangXuLy = suCo.trangThai == 'DANG_XU_LY';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                suCo.loai,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            NhanTrangThai(
                              ma: suCo.trangThai,
                              nhan: suCo.nhanTrangThai,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          suCo.soPhong.isEmpty
                              ? 'Mã #${suCo.id}'
                              : 'Phòng ${suCo.soPhong}${suCo.tenKhu.isEmpty ? '' : ' · ${suCo.tenKhu}'}',
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
              const SizedBox(height: 8),
              Text(
                suCo.moTa,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),
              if ((suCo.anhUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _xemAnh(context, suCo.anhUrl!),
                  child: AnhMang(
                    url: suCo.anhUrl,
                    chieuCao: 150,
                    boGoc: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _Buoc(
                    icon: Icons.send_outlined,
                    nhan: 'Đã gửi',
                    dat: true,
                    mau: AppColors.brand,
                  ),
                  _DuongNoi(dat: dangXuLy || daXuLy),
                  _Buoc(
                    icon: Icons.build_outlined,
                    nhan: 'Đang xử lý',
                    dat: dangXuLy || daXuLy,
                    mau: AppColors.canhBao,
                  ),
                  _DuongNoi(dat: daXuLy),
                  _Buoc(
                    icon: Icons.verified_outlined,
                    nhan: 'Hoàn tất',
                    dat: daXuLy,
                    mau: AppColors.thanhCong,
                  ),
                ],
              ),
              if (suCo.xuLyLuc != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Cập nhật lần cuối: ${DinhDang.ngayGio(suCo.xuLyLuc)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.chuMo,
                  ),
                ),
              ],
              if (suCo.trangThai == 'TU_CHOI') ...[
                const SizedBox(height: 6),
                const Text(
                  'Báo cáo bị từ chối. Vui lòng liên hệ trực tiếp chủ trọ.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.nguyHiem),
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
                      'Ảnh hiện trạng',
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

class _Buoc extends StatelessWidget {
  const _Buoc({
    required this.icon,
    required this.nhan,
    required this.dat,
    required this.mau,
  });

  final IconData icon;
  final String nhan;
  final bool dat;
  final Color mau;

  @override
  Widget build(BuildContext context) {
    final mauHienTai = dat ? mau : AppColors.vien;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: mauHienTai.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: mauHienTai),
        ),
        const SizedBox(height: 3),
        Text(
          nhan,
          style: TextStyle(
            fontSize: 9.5,
            color: dat ? mau : AppColors.chuMo,
            fontWeight: dat ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _DuongNoi extends StatelessWidget {
  const _DuongNoi({required this.dat});

  final bool dat;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: dat ? AppColors.brand : AppColors.vien,
      ),
    );
  }
}
