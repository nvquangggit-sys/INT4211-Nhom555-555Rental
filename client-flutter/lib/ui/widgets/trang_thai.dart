import 'package:flutter/material.dart';

import '../theme.dart';

/// Nhãn trạng thái nhỏ (màu chữ + nền theo mã trạng thái backend).
class NhanTrangThai extends StatelessWidget {
  const NhanTrangThai({super.key, required this.ma, required this.nhan});

  final String ma;
  final String nhan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: nenTrangThai(ma),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        nhan,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: mauTrangThai(ma),
        ),
      ),
    );
  }
}

/// Thẻ số liệu nhỏ dùng ở trang chủ / chi tiết.
class TheSoLieu extends StatelessWidget {
  const TheSoLieu({
    super.key,
    required this.nhan,
    required this.giaTri,
    this.icon,
    this.mau = AppColors.brand,
    this.onTap,
  });

  final String nhan;
  final String giaTri;
  final IconData? icon;
  final Color mau;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: mau.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: mau),
                ),
              const SizedBox(height: 10),
              Text(
                giaTri,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                nhan,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.chuMo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dòng "nhãn – giá trị" trong các thẻ thông tin.
class DongThongTin extends StatelessWidget {
  const DongThongTin({
    super.key,
    required this.nhan,
    required this.giaTri,
    this.icon,
    this.mauGiaTri,
    this.dam = false,
  });

  final String nhan;
  final String giaTri;
  final IconData? icon;
  final Color? mauGiaTri;
  final bool dam;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.chuMo),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              nhan,
              style: const TextStyle(fontSize: 13.5, color: AppColors.chuMo),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              giaTri,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: dam ? FontWeight.w700 : FontWeight.w500,
                color: mauGiaTri ?? AppColors.chu,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Màn hình trạng thái rỗng (không có dữ liệu).
class MucRong extends StatelessWidget {
  const MucRong({
    super.key,
    required this.tieuDe,
    this.moTa,
    this.icon = Icons.inbox_outlined,
    this.nhanNut,
    this.onNhan,
  });

  final String tieuDe;
  final String? moTa;
  final IconData icon;
  final String? nhanNut;
  final VoidCallback? onNhan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.vien),
            const SizedBox(height: 12),
            Text(
              tieuDe,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            if (moTa != null) ...[
              const SizedBox(height: 6),
              Text(
                moTa!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.chuMo),
              ),
            ],
            if (nhanNut != null && onNhan != null) ...[
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: onNhan,
                icon: const Icon(Icons.refresh),
                label: Text(nhanNut!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Màn hình lỗi mạng kèm nút "Thử lại" – trạng thái thứ 3 của mọi màn.
class ManHinhLoi extends StatelessWidget {
  const ManHinhLoi({super.key, required this.thongDiep, required this.onThuLai});

  final String thongDiep;
  final VoidCallback onThuLai;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 52, color: AppColors.nguyHiem),
            const SizedBox(height: 12),
            const Text(
              'Không tải được dữ liệu',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              thongDiep,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.chuMo),
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onThuLai,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Khung tải dữ liệu.
class KhungDangTai extends StatelessWidget {
  const KhungDangTai({super.key, this.thongDiep = 'Đang tải dữ liệu…'});

  final String thongDiep;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 12),
          Text(
            thongDiep,
            style: const TextStyle(fontSize: 13, color: AppColors.chuMo),
          ),
        ],
      ),
    );
  }
}
