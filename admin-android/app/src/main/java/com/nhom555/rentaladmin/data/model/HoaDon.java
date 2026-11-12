package com.nhom555.rentaladmin.data.model;

/** Hóa đơn tháng của một hợp đồng. */
public class HoaDon {
    public int id;
    public int hop_dong_id;
    public String thang;
    public int tong_tien;
    public int da_thu;
    public String han_thanh_toan;
    public String trang_thai;

    // Trường join / tính toán
    public int nguoi_thue_id;
    public String so_phong;
    public int khu_tro_id;
    public int gia_thue;
    public String ten_khu;
    public String ten_nguoi_thue;
    public String sdt_nguoi_thue;
    public int con_no;
    public int so_ngay_qua_han;

    public int phanTramDaThu() {
        if (tong_tien <= 0) {
            return 0;
        }
        return Math.min(100, Math.round(da_thu * 100f / tong_tien));
    }
}
