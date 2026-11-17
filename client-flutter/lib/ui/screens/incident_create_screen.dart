import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../core/dinh_dang.dart';
import '../../models/hop_dong.dart';
import '../../models/su_co.dart';
import '../theme.dart';
import '../widgets/trang_thai.dart';

/// Form báo sự cố: chọn phòng đang thuê, loại sự cố, mô tả và ảnh (không bắt
/// buộc). Gửi JSON khi không có ảnh, gửi multipart khi có ảnh.
///
/// Tự lấy phòng từ GET /hop-dong/cua-toi (chỉ hợp đồng còn hiệu lực) để đảm bảo
/// người thuê chỉ báo sự cố cho phòng mình đang ở.
class IncidentCreateScreen extends StatefulWidget {
  const IncidentCreateScreen({super.key, this.phongMacDinh});

  /// Phòng được chọn sẵn (nếu mở từ nơi khác).
  final int? phongMacDinh;

  @override
  State<IncidentCreateScreen> createState() => _IncidentCreateScreenState();
}

class _IncidentCreateScreenState extends State<IncidentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _moTaController = TextEditingController();
  final _imagePicker = ImagePicker();

  late Future<List<HopDong>> _futureHopDong;
  int? _phongId;
  String _loai = loaiSuCo.first;
  File? _anh;
  bool _dangGui = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _futureHopDong = _taiHopDong();
  }

  @override
  void dispose() {
    _moTaController.dispose();
    super.dispose();
  }

  Future<List<HopDong>> _taiHopDong() async {
    final duLieu = await ApiService.instance.get('/hop-dong/cua-toi');
    if (duLieu is! List) {
      return const [];
    }
    final ds = duLieu
        .whereType<Map<String, dynamic>>()
        .map(HopDong.tuJson)
        .where((e) => e.trangThai == 'HIEU_LUC')
        .toList();
    if (ds.isNotEmpty) {
      final coMacDinh =
          ds.any((e) => e.phongId == widget.phongMacDinh) && widget.phongMacDinh != null;
      _phongId = coMacDinh ? widget.phongMacDinh : ds.first.phongId;
    }
    return ds;
  }

  Future<void> _chonAnh() async {
    try {
      final anh = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 75,
      );
      if (anh == null || !mounted) {
        return;
      }
      setState(() {
        _anh = File(anh.path);
      });
    } catch (loi) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loi = 'Không mở được thư viện ảnh: $loi';
      });
    }
  }

  Future<void> _gui() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_phongId == null) {
      setState(() {
        _loi = 'Bạn cần có hợp đồng đang hiệu lực để báo sự cố.';
      });
      return;
    }
    if (_dangGui) {
      return;
    }

    setState(() {
      _dangGui = true;
      _loi = null;
    });

    try {
      if (_anh != null) {
        await ApiService.instance.postMultipart(
          '/bao-su-co',
          fields: {
            'phong_id': _phongId.toString(),
            'loai': _loai,
            'mo_ta': _moTaController.text.trim(),
          },
          anh: _anh,
        );
      } else {
        await ApiService.instance.post(
          '/bao-su-co',
          body: {
            'phong_id': _phongId,
            'loai': _loai,
            'mo_ta': _moTaController.text.trim(),
          },
        );
      }
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline,
              color: AppColors.thanhCong, size: 40),
          title: const Text('Đã gửi báo cáo sự cố'),
          content: const Text(
            'Chủ trọ/quản lý sẽ tiếp nhận và xử lý. Bạn theo dõi trạng thái '
            'trong tab Sự cố.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (loi) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loi = loi.thongDiep;
      });
    } catch (loi) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loi = 'Không gửi được báo cáo: $loi';
      });
    } finally {
      if (mounted) {
        setState(() {
          _dangGui = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo sự cố')),
      body: FutureBuilder<List<HopDong>>(
        future: _futureHopDong,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const KhungDangTai(thongDiep: 'Đang tải phòng của bạn…');
          }
          if (snapshot.hasError) {
            final loi = snapshot.error;
            return ManHinhLoi(
              thongDiep: loi is ApiException
                  ? loi.thongDiep
                  : 'Không tải được hợp đồng.',
              onThuLai: () => setState(() {
                _futureHopDong = _taiHopDong();
              }),
            );
          }
          final dsHopDong = snapshot.data ?? const [];
          if (dsHopDong.isEmpty) {
            return MucRong(
              icon: Icons.home_work_outlined,
              tieuDe: 'Chưa có phòng đang thuê',
              moTa: 'Bạn cần có hợp đồng còn hiệu lực để gửi báo cáo sự cố.',
            );
          }
          return _form(dsHopDong);
        },
      ),
    );
  }

  Widget _form(List<HopDong> dsHopDong) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _phongId,
                decoration: const InputDecoration(
                  labelText: 'Phòng gặp sự cố',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
                items: dsHopDong
                    .map(
                      (hopDong) => DropdownMenuItem<int>(
                        value: hopDong.phongId,
                        child: Text(
                          'Phòng ${hopDong.soPhong} · ${hopDong.tenKhu}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _dangGui
                    ? null
                    : (giaTri) => setState(() {
                          _phongId = giaTri;
                        }),
                validator: (giaTri) =>
                    giaTri == null ? 'Vui lòng chọn phòng' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _loai,
                decoration: const InputDecoration(
                  labelText: 'Loại sự cố',
                  prefixIcon: Icon(Icons.build_outlined),
                ),
                items: loaiSuCo
                    .map(
                      (loai) => DropdownMenuItem<String>(
                        value: loai,
                        child: Text(loai),
                      ),
                    )
                    .toList(),
                onChanged: _dangGui
                    ? null
                    : (giaTri) => setState(() {
                          _loai = giaTri ?? loaiSuCo.first;
                        }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _moTaController,
                minLines: 4,
                maxLines: 7,
                maxLength: 500,
                enabled: !_dangGui,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  hintText: 'Ví dụ: Ổ điện góc bếp bị tia lửa từ sáng nay…',
                  alignLabelWithHint: true,
                ),
                validator: (giaTri) {
                  final s = (giaTri ?? '').trim();
                  if (s.isEmpty) {
                    return 'Vui lòng mô tả sự cố';
                  }
                  if (s.length < 10) {
                    return 'Mô tả cần ít nhất 10 ký tự để chủ trọ hiểu vấn đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              const Text(
                'Ảnh hiện trạng (không bắt buộc)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_anh != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        _anh!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 120,
                          color: AppColors.nguyHiemNen,
                          child: const Center(
                            child: Text(
                              'Không đọc được ảnh đã chọn',
                              style: TextStyle(color: AppColors.nguyHiem),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Bỏ ảnh',
                          onPressed: _dangGui
                              ? null
                              : () => setState(() {
                                    _anh = null;
                                  }),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _dangGui ? null : _chonAnh,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Chọn ảnh từ thư viện'),
                ),
              if (_anh != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _dangGui ? null : _chonAnh,
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Chọn ảnh khác'),
                  ),
                ),
              if (_loi != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.nguyHiemNen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _loi!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.nguyHiem,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _dangGui ? null : _gui,
                icon: _dangGui
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(_dangGui ? 'Đang gửi…' : 'Gửi báo cáo sự cố'),
              ),
              const SizedBox(height: 8),
              Text(
                'Thời điểm gửi: ${DinhDang.ngayGio(DateTime.now())}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: AppColors.chuMo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
