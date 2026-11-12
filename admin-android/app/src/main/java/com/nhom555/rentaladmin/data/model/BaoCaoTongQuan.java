package com.nhom555.rentaladmin.data.model;

/** Response của GET /bao-cao/tong-quan. */
public class BaoCaoTongQuan {
    public ThongKePhong phong;
    public ThongKeSuCo su_co;
    /** null khi đăng nhập bằng QUAN_LY. */
    public ThongKeHoaDonThang hoa_don_thang_nay;
}
