import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../core/dinh_dang.dart';
import '../../models/lich_xem_phong.dart';
import '../theme.dart';
import '../widgets/anh_mang.dart';
import '../widgets/trang_thai.dart';

/// Danh sách lịch xem phòng khách đã đặt (GET /lich-xem-phong/cua-toi).
///
/// Hủy lịch: DELETE /lich-xem-phong/:id (backend chỉ cho phép hủy lịch của chính
/// mình và chỉ khi còn "Chờ xác nhận"). Sau khi hủy hiện SnackBar có nút
/// "Hoàn tác" để tạo lại lịch với đúng phòng và thời gian cũ.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late Future<List<LichXemPhong>> _future;
  bool _dangXuLy = false;

  @override
  void initState() {
    super.initState();
    _future = _taiDanhSach();
  }

  Future<List<LichXemPhong>> _taiDanhSach() async {
    final duLieu = await ApiService.instance.get('/lich-xem-phong/cua-toi');
    if (duLieu is! List) {
      return const [];
    }
    final ds = duLieu
        .whereType<Map<String, dynamic>>()
        .map(LichXemPhong.tuJson)
        .toList()
      ..sort((a, b) {
        final ta = a.thoiGian ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.thoiGian ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
    return ds;
  }

  void _taiLai() {
    setState(() {
      _future = _taiDanhSach();
    });
  }

  Future<void> _xacNhanHuy(LichXemPhong lich) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy lịch xem phòng?'),
        content: Text(
          'Lịch xem phòng ${lich.soPhong} lúc ${DinhDang.ngayGio(lich.thoiGian)} '
          'sẽ bị hủy. Bạn có thể hoàn tác ngay sau đó.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Giữ lịch'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );
    if (dongY != true || !mounted) {
      return;
    }
    await _huy(lich);
  }

  Future<void> _huy(LichXemPhong lich) async {
    if (_dangXuLy) {
      return;
    }
    setState(() {
      _dangXuLy = true;
    });
    try {
      await ApiService.instance.delete('/lich-xem-phong/${lich.id}');
      if (!mounted) {
        return;
      }
      _taiLai();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã hủy lịch xem phòng ${lich.soPhong}.'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Hoàn tác',
            onPressed: () => _hoanTac(lich),
          ),
        ),
      );
    } on ApiException catch (loi) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không hủy được lịch: ${loi.thongDiep}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _dangXuLy = false;
        });
      }
    }
  }

  /// Hoàn tác = gửi lại yêu cầu xem phòng với cùng phòng và thời gian.
  Future<void> _hoanTac(LichXemPhong lich) async {
    try {
      await ApiService.instance.post(
        '/lich-xem-phong',
        body: {
          'phong_id': lich.phongId,
          'thoi_gian': lich.thoiGian?.toUtc().toIso8601String(),
          'ghi_chu': 'Khôi phục lịch xem phòng đã hủy',
        },
      );
      if (!mounted) {
        return;
      }
      _taiLai();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hoàn tác, lịch xem phòng được tạo lại.')),
      );
    } on ApiException catch (loi) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không hoàn tác được: ${loi.thongDiep}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch xem phòng của tôi'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _dangXuLy ? null : _taiLai,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<LichXemPhong>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const KhungDangTai(thongDiep: 'Đang tải lịch xem phòng…');
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
              icon: Icons.event_busy_outlined,
              tieuDe: 'Chưa có lịch xem phòng',
              moTa: 'Vào tab Tìm phòng, chọn phòng còn trống rồi bấm '
                  '"Đặt lịch xem phòng".',
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: ds.length,
              itemBuilder: (context, chiSo) {
                final lich = ds[chiSo];
                return _TheLich(
                  lich: lich,
                  dangXuLy: _dangXuLy,
                  onHuy: () => _xacNhanHuy(lich),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _TheLich extends StatelessWidget {
  const _TheLich({
    required this.lich,
    required this.dangXuLy,
    required this.onHuy,
  });

  final LichXemPhong lich;
  final bool dangXuLy;
  final VoidCallback onHuy;

  @override
  Widget build(BuildContext context) {
    final sapToi = (lich.thoiGian ?? DateTime.now()).isAfter(DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnhMang(
                    url: lich.anhUrl,
                    chieuCao: 68,
                    chieuRong: 76,
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
                                'Phòng ${lich.soPhong} · ${lich.tenKhu}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            NhanTrangThai(
                              ma: lich.trangThai,
                              nhan: lich.nhanTrangThai,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 14, color: AppColors.chuMo),
                            const SizedBox(width: 4),
                            Text(
                              DinhDang.ngayGio(lich.thoiGian),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.chuMo,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lich.diaChi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              if (lich.dangCho && sapToi) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: dangXuLy ? null : onHuy,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        foregroundColor: AppColors.nguyHiem,
                        side: const BorderSide(color: AppColors.nguyHiem),
                      ),
                      icon: const Icon(Icons.event_busy, size: 18),
                      label: const Text('Hủy lịch'),
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
}
