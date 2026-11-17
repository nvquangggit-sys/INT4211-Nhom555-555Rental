import 'package:flutter/material.dart';

import '../theme.dart';

/// Ảnh mạng có `loadingBuilder` và `errorBuilder` theo yêu cầu của đề.
///
/// - Trong lúc tải: khung xám + vòng tròn tiến trình.
/// - Lỗi/không có URL: khung xám + icon, không làm văng app.
class AnhMang extends StatelessWidget {
  const AnhMang({
    super.key,
    required this.url,
    this.chieuCao = 180,
    this.chieuRong,
    this.boGoc = 16,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final double chieuCao;
  final double? chieuRong;
  final double boGoc;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final diaChi = (url ?? '').trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(boGoc),
      child: Container(
        height: chieuCao,
        width: chieuRong,
        color: const Color(0xFFE9EEEE),
        child: diaChi.isEmpty
            ? _khungLoi('Chưa có ảnh')
            : Image.network(
                diaChi,
                height: chieuCao,
                width: chieuRong,
                fit: fit,
                loadingBuilder: (context, child, tienTrinh) {
                  if (tienTrinh == null) {
                    return child;
                  }
                  final tong = tienTrinh.expectedTotalBytes;
                  return Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.brand,
                        value: tong == null
                            ? null
                            : tienTrinh.cumulativeBytesLoaded / tong,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    _khungLoi('Không tải được ảnh'),
              ),
      ),
    );
  }

  Widget _khungLoi(String thongDiep) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_not_supported_outlined,
              size: 30, color: AppColors.chuMo),
          const SizedBox(height: 6),
          Text(
            thongDiep,
            style: const TextStyle(fontSize: 12, color: AppColors.chuMo),
          ),
        ],
      ),
    );
  }
}
