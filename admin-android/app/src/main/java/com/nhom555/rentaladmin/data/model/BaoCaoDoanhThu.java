package com.nhom555.rentaladmin.data.model;

import java.util.List;

/** Response của GET /bao-cao/doanh-thu - chỉ CHU_TRO được gọi (QUAN_LY nhận 403). */
public class BaoCaoDoanhThu {
    public List<DoanhThuKhu> theo_khu;
    public List<DoanhThuThang> theo_thang;
    public DoanhThuTong tong;
}
