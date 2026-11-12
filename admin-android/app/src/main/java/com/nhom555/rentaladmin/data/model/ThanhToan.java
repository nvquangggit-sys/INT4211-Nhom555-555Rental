package com.nhom555.rentaladmin.data.model;

/** Một giao dịch thanh toán của người thuê. xac_nhan_boi = null nghĩa là chờ xác nhận. */
public class ThanhToan {
    public int id;
    public int hoa_don_id;
    public int so_tien;
    public String hinh_thuc;
    public String anh_bien_lai;
    public Integer xac_nhan_boi;
    public String thoi_diem;

    // Trường join
    public String thang;
    public int tong_tien;
    public int da_thu;
    public String so_phong;
    public String ten_khu;
    public String ten_nguoi_thue;
    public String ten_nguoi_xac_nhan;

    public boolean daXacNhan() {
        return xac_nhan_boi != null;
    }
}
