import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_exception.dart';
import '../../core/api_service.dart';
import '../../core/dinh_dang.dart';
import '../../models/hoa_don.dart';
import '../theme.dart';

/// Màn hình xác nhận thanh toán: nhập số tiền, chọn hình thức, đính kèm ảnh
/// biên lai rồi gửi multipart tới POST /thanh-toan.
///
/// - `ImagePicker` lấy ảnh từ thư viện.
/// - Khi đang gửi, nút bị khóa để không gửi trùng (chống double submit).
/// - Thành công trả `true` về màn chi tiết hóa đơn bằng `Navigator.pop(true)`.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.hoaDon});

  final HoaDon hoaDon;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _soTienController = TextEditingController();
  final _imagePicker = ImagePicker();

  String _hinhThuc = 'CHUYEN_KHOAN';
  File? _anhBienLai;
  bool _dangGui = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    final conNo = widget.hoaDon.conNo > 0
        ? widget.hoaDon.conNo
        : widget.hoaDon.tongTien;
    _soTienController.text = conNo.toString();
  }

  @override
  void dispose() {
    _soTienController.dispose();
    super.dispose();
  }

  int get _soTien => int.tryParse(_soTienController.text.trim()) ?? 0;

  Future<void> _chonAnh() async {
    try {
      final anh = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        imageQuality: 80,
      );
      if (anh == null || !mounted) {
        return;
      }
      setState(() {
        _anhBienLai = File(anh.path);
        _loi = null;
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
    if (_dangGui) {
      return;
    }
    if (_hinhThuc == 'CHUYEN_KHOAN' && _anhBienLai == null) {
      setState(() {
        _loi = 'Vui lòng đính kèm ảnh biên lai chuyển khoản.';
      });
      return;
    }

    setState(() {
      _dangGui = true;
      _loi = null;
    });

    try {
      final ketQua = await ApiService.instance.postMultipart(
        '/thanh-toan',
        fields: {
          'hoa_don_id': widget.hoaDon.id.toString(),
          'so_tien': _soTien.toString(),
          'hinh_thuc': _hinhThuc,
        },
        anh: _anhBienLai,
      );
      if (!mounted) {
        return;
      }
      var thongDiep = 'Đã gửi xác nhận thanh toán, chờ chủ trọ kiểm tra.';
      if (ketQua is Map && ketQua['thong_diep'] is String) {
        thongDiep = ketQua['thong_diep'] as String;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline,
              color: AppColors.thanhCong, size: 40),
          title: const Text('Đã gửi xác nhận'),
          content: Text(thongDiep),
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
        _loi = 'Không gửi được xác nhận: $loi';
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
    final hoaDon = widget.hoaDon;
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận thanh toán')),
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
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hóa đơn ${DinhDang.thang(hoaDon.thang)} · Phòng ${hoaDon.soPhong}',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Dong(
                          nhan: 'Tổng tiền',
                          giaTri: DinhDang.tien(hoaDon.tongTien),
                        ),
                        _Dong(
                          nhan: 'Đã thu',
                          giaTri: DinhDang.tien(hoaDon.daThu),
                        ),
                        _Dong(
                          nhan: 'Còn nợ',
                          giaTri: DinhDang.tien(hoaDon.conNo),
                          mau: AppColors.nguyHiem,
                          dam: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Số tiền thanh toán',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _soTienController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: !_dangGui,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền (đ)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (giaTri) {
                    final so = int.tryParse((giaTri ?? '').trim()) ?? 0;
                    if (so <= 0) {
                      return 'Số tiền phải lớn hơn 0';
                    }
                    if (hoaDon.conNo > 0 && so > hoaDon.conNo) {
                      return 'Số tiền vượt quá số còn nợ '
                          '(${DinhDang.tien(hoaDon.conNo)})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ActionChip(
                      label: const Text('Trả toàn bộ'),
                      onPressed: _dangGui
                          ? null
                          : () => setState(() {
                                _soTienController.text =
                                    (hoaDon.conNo > 0
                                            ? hoaDon.conNo
                                            : hoaDon.tongTien)
                                        .toString();
                              }),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('Một nửa'),
                      onPressed: _dangGui
                          ? null
                          : () => setState(() {
                                final conNo = hoaDon.conNo > 0
                                    ? hoaDon.conNo
                                    : hoaDon.tongTien;
                                _soTienController.text =
                                    (conNo ~/ 2).toString();
                              }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hình thức thanh toán',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'CHUYEN_KHOAN',
                      label: Text('Chuyển khoản'),
                      icon: Icon(Icons.account_balance_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'TIEN_MAT',
                      label: Text('Tiền mặt'),
                      icon: Icon(Icons.money),
                    ),
                  ],
                  selected: {_hinhThuc},
                  onSelectionChanged: _dangGui
                      ? null
                      : (luaChon) => setState(() {
                            _hinhThuc = luaChon.first;
                            _loi = null;
                          }),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandNhat,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: AppColors.brand),
                          SizedBox(width: 6),
                          Text(
                            'Nội dung chuyển khoản gợi ý',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        'P${hoaDon.soPhong} T${hoaDon.thang} '
                        '${DinhDang.tien(_soTien)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Chuyển khoản tới tài khoản chủ trọ ghi trong hợp đồng, '
                        'sau đó chụp màn hình biên lai và tải lên bên dưới.',
                        style:
                            TextStyle(fontSize: 11.5, color: AppColors.chuMo),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ảnh biên lai',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      _hinhThuc == 'CHUYEN_KHOAN'
                          ? 'Bắt buộc'
                          : 'Không bắt buộc',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _hinhThuc == 'CHUYEN_KHOAN'
                            ? AppColors.nguyHiem
                            : AppColors.chuMo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_anhBienLai != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _anhBienLai!,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 160,
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
                                      _anhBienLai = null;
                                    }),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  InkWell(
                    onTap: _dangGui ? null : _chonAnh,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.brand,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 34, color: AppColors.brand),
                          SizedBox(height: 6),
                          Text(
                            'Chọn ảnh biên lai từ thư viện',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_anhBienLai != null)
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
                const SizedBox(height: 18),
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
                  label: Text(
                    _dangGui ? 'Đang gửi biên lai…' : 'Gửi xác nhận thanh toán',
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

class _Dong extends StatelessWidget {
  const _Dong({
    required this.nhan,
    required this.giaTri,
    this.mau,
    this.dam = false,
  });

  final String nhan;
  final String giaTri;
  final Color? mau;
  final bool dam;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              nhan,
              style: const TextStyle(fontSize: 12.5, color: AppColors.chuMo),
            ),
          ),
          Text(
            giaTri,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: dam ? FontWeight.w800 : FontWeight.w600,
              color: mau ?? AppColors.chu,
            ),
          ),
        ],
      ),
    );
  }
}
