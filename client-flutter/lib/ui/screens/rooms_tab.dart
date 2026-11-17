import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../core/dinh_dang.dart';
import '../../models/phong.dart';
import '../theme.dart';
import '../widgets/anh_mang.dart';
import '../widgets/trang_thai.dart';
import 'room_detail_screen.dart';

/// Tab Tìm phòng: lọc khu vực / khoảng giá / diện tích rồi hiển thị danh sách
/// bằng `ListView.builder` từ API công khai GET /phong.
///
/// Future chỉ được tạo trong `initState` và mỗi lần bấm nút "Lọc" (đúng yêu cầu
/// đề: không gọi lại API ở mỗi lần rebuild).
class RoomsTab extends StatefulWidget {
  const RoomsTab({super.key});

  @override
  State<RoomsTab> createState() => _RoomsTabState();
}

class _RoomsTabState extends State<RoomsTab> {
  final _khuVucController = TextEditingController();
  final _giaTuController = TextEditingController();
  final _giaDenController = TextEditingController();
  final _dienTichController = TextEditingController();

  late Future<List<Phong>> _futurePhong;
  bool _hienBoLoc = false;
  int _soPhong = 0;

  @override
  void initState() {
    super.initState();
    _futurePhong = _taiDanhSach();
  }

  @override
  void dispose() {
    _khuVucController.dispose();
    _giaTuController.dispose();
    _giaDenController.dispose();
    _dienTichController.dispose();
    super.dispose();
  }

  Future<List<Phong>> _taiDanhSach() async {
    final duLieu = await ApiService.instance.get('/phong', query: {
      'khuVuc': _khuVucController.text.trim(),
      'giaTu': _giaTuController.text.trim(),
      'giaDen': _giaDenController.text.trim(),
      'dienTichTu': _dienTichController.text.trim(),
      'trangThai': 'TRONG',
      'limit': '60',
    });
    if (duLieu is! List) {
      return const [];
    }
    final ds = duLieu
        .whereType<Map<String, dynamic>>()
        .map(Phong.tuJson)
        .toList();
    if (mounted) {
      setState(() {
        _soPhong = ds.isEmpty ? 0 : ds.first.tongSo;
      });
    }
    return ds;
  }

  void _loc() {
    FocusScope.of(context).unfocus();
    setState(() {
      _futurePhong = _taiDanhSach();
    });
  }

  void _xoaBoLoc() {
    _khuVucController.clear();
    _giaTuController.clear();
    _giaDenController.clear();
    _dienTichController.clear();
    _loc();
  }

  Future<void> _moChiTiet(Phong phong) async {
    final daDatLich = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => RoomDetailScreen(phong: phong),
      ),
    );
    if (!mounted) {
      return;
    }
    if (daDatLich == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã gửi yêu cầu xem phòng ${phong.soPhong}. Theo dõi ở mục Lịch xem phòng.',
          ),
        ),
      );
      _loc();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _thanhLoc(),
        Expanded(
          child: FutureBuilder<List<Phong>>(
            future: _futurePhong,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const KhungDangTai(thongDiep: 'Đang tìm phòng trống…');
              }
              if (snapshot.hasError) {
                final loi = snapshot.error;
                return ManHinhLoi(
                  thongDiep: loi is ApiException
                      ? loi.thongDiep
                      : 'Không kết nối được máy chủ.',
                  onThuLai: _loc,
                );
              }
              final ds = snapshot.data ?? const [];
              if (ds.isEmpty) {
                return MucRong(
                  icon: Icons.search_off,
                  tieuDe: 'Không tìm thấy phòng phù hợp',
                  moTa: 'Thử mở rộng khoảng giá hoặc bỏ lọc khu vực.',
                  nhanNut: 'Xóa bộ lọc',
                  onNhan: _xoaBoLoc,
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  _loc();
                  await _futurePhong;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: ds.length + 1,
                  itemBuilder: (context, chiSo) {
                    if (chiSo == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _soPhong > 0
                              ? '$_soPhong phòng trống phù hợp'
                              : '${ds.length} phòng trống',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.chuMo,
                          ),
                        ),
                      );
                    }
                    final phong = ds[chiSo - 1];
                    return _ThePhong(
                      phong: phong,
                      onTap: () => _moChiTiet(phong),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _thanhLoc() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _khuVucController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _loc(),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Khu vực, tên đường…',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loc,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text('Lọc'),
              ),
              IconButton(
                tooltip: _hienBoLoc ? 'Ẩn bộ lọc' : 'Lọc theo giá, diện tích',
                onPressed: () => setState(() {
                  _hienBoLoc = !_hienBoLoc;
                }),
                icon: Icon(
                  _hienBoLoc ? Icons.tune : Icons.tune_outlined,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
          if (_hienBoLoc) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _giaTuController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Giá từ (đ)',
                      hintText: '2000000',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _giaDenController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Giá đến (đ)',
                      hintText: '5000000',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _dienTichController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'DT từ (m²)',
                      hintText: '20',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.money_off, size: 16),
                  label: const Text('Dưới 3 triệu'),
                  onPressed: () {
                    _giaTuController.text = '';
                    _giaDenController.text = '3000000';
                    _loc();
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.timelapse, size: 16),
                  label: const Text('3–5 triệu'),
                  onPressed: () {
                    _giaTuController.text = '3000000';
                    _giaDenController.text = '5000000';
                    _loc();
                  },
                ),
                const Spacer(),
                TextButton(
                  onPressed: _xoaBoLoc,
                  child: const Text('Xóa lọc'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ThePhong extends StatelessWidget {
  const _ThePhong({required this.phong, required this.onTap});

  final Phong phong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnhMang(
                  url: phong.anhUrl,
                  chieuCao: 96,
                  chieuRong: 108,
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
                              'Phòng ${phong.soPhong} · ${phong.tenKhu}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          NhanTrangThai(
                            ma: phong.trangThai,
                            nhan: phong.nhanTrangThai,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DinhDang.tien(phong.giaThue),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${phong.dienTich.toStringAsFixed(0)} m² · tối đa ${phong.sucChua} người',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.chuMo),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phong.diaChi.isEmpty ? phong.phuongXa : phong.diaChi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.chuMo),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
