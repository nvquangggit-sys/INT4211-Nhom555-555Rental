import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../core/dinh_dang.dart';
import '../../models/phong.dart';
import '../theme.dart';
import '../widgets/anh_mang.dart';

/// Form đặt lịch xem phòng: chọn ngày (DatePicker), giờ (TimePicker), ghi chú.
///
/// Gọi POST /lich-xem-phong. Thành công trả `true` về màn chi tiết phòng bằng
/// `Navigator.pop(true)` (yêu cầu "Navigator có trả kết quả" của đề).
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.phong});

  final Phong phong;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ghiChuController = TextEditingController();

  late DateTime _ngay;
  TimeOfDay _gio = const TimeOfDay(hour: 9, minute: 0);
  bool _dangGui = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    final ngayMai = DateTime.now().add(const Duration(days: 1));
    _ngay = DateTime(ngayMai.year, ngayMai.month, ngayMai.day);
  }

  @override
  void dispose() {
    _ghiChuController.dispose();
    super.dispose();
  }

  DateTime get _thoiGian => DateTime(
        _ngay.year,
        _ngay.month,
        _ngay.day,
        _gio.hour,
        _gio.minute,
      );

  Future<void> _chonNgay() async {
    final homNay = DateTime.now();
    final chon = await showDatePicker(
      context: context,
      initialDate: _ngay,
      firstDate: DateTime(homNay.year, homNay.month, homNay.day),
      lastDate: homNay.add(const Duration(days: 60)),
      helpText: 'Chọn ngày xem phòng',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (chon == null || !mounted) {
      return;
    }
    setState(() {
      _ngay = chon;
      _loi = null;
    });
  }

  Future<void> _chonGio() async {
    final chon = await showTimePicker(
      context: context,
      initialTime: _gio,
      helpText: 'Chọn giờ xem phòng',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (chon == null || !mounted) {
      return;
    }
    setState(() {
      _gio = chon;
      _loi = null;
    });
  }

  Future<void> _gui() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final thoiGian = _thoiGian;
    if (thoiGian.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
      setState(() {
        _loi = 'Vui lòng chọn thời gian sau hiện tại ít nhất 30 phút.';
      });
      return;
    }

    if (_dangGui) {
      return; // chống bấm hai lần
    }

    setState(() {
      _dangGui = true;
      _loi = null;
    });

    try {
      await ApiService.instance.post(
        '/lich-xem-phong',
        body: {
          'phong_id': widget.phong.id,
          'thoi_gian': thoiGian.toUtc().toIso8601String(),
          'ghi_chu': _ghiChuController.text.trim(),
        },
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu xem phòng.')),
      );
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
        _loi = 'Không gửi được yêu cầu: $loi';
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
      appBar: AppBar(title: const Text('Đặt lịch xem phòng')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        AnhMang(
                          url: widget.phong.anhUrl,
                          chieuCao: 64,
                          chieuRong: 64,
                          boGoc: 12,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phòng ${widget.phong.soPhong} · ${widget.phong.tenKhu}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DinhDang.tien(widget.phong.giaThue)}/tháng · '
                                '${widget.phong.dienTich.toStringAsFixed(0)} m²',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.chuMo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Thời gian xem phòng',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _dangGui ? null : _chonNgay,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(DinhDang.ngay(_ngay)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _dangGui ? null : _chonGio,
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          '${_gio.hour.toString().padLeft(2, '0')}:'
                          '${_gio.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Đã chọn: ${DinhDang.ngayGio(_thoiGian)} (giờ máy bạn)',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.chuMo),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ghiChuController,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú cho chủ trọ (không bắt buộc)',
                    hintText: 'Ví dụ: Tôi muốn xem phòng buổi sáng thứ Bảy…',
                    alignLabelWithHint: true,
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 18, color: AppColors.nguyHiem),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loi!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.nguyHiem,
                            ),
                          ),
                        ),
                      ],
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
                  label: Text(_dangGui ? 'Đang gửi…' : 'Gửi yêu cầu'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chủ trọ xác nhận lịch qua App Admin 555Rental. Bạn xem lại '
                  'trong mục Tài khoản → Lịch xem phòng.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.chuMo),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
