package com.nhom555.rentaladmin.data.model;

import java.util.List;

/**
 * Response của GET /hoa-don/{id}: thông tin hóa đơn + các dòng chi tiết
 * + chỉ số điện nước của tháng + lịch sử thanh toán.
 */
public class HoaDonChiTiet extends HoaDon {
    public List<ChiTietHoaDon> chi_tiet;
    public ChiSoDienNuoc chi_so;
    public List<ThanhToan> thanh_toan;
}
