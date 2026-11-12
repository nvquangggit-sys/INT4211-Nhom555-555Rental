package com.nhom555.rentaladmin.data.model;

/** Hợp đồng thuê phòng. GET /hop-dong trả kèm tên phòng, khu, người thuê. */
public class HopDong {
    public int id;
    public int phong_id;
    public int nguoi_thue_id;
    public String bat_dau;
    public String ket_thuc;
    public int tien_coc;
    public int so_nguoi;
    public String trang_thai;

    // Trường join
    public String so_phong;
    public int khu_tro_id;
    public int gia_thue;
    public String ten_khu;
    public String ten_nguoi_thue;
    public String sdt_nguoi_thue;
    public int so_ngay_con_lai;
}
