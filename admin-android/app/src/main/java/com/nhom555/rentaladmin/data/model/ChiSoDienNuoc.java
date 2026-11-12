package com.nhom555.rentaladmin.data.model;

/** Chỉ số điện nước của một phòng trong một tháng. */
public class ChiSoDienNuoc {
    public int id;
    public int phong_id;
    public String thang;
    public int dien_dau;
    public int dien_cuoi;
    public int nuoc_dau;
    public int nuoc_cuoi;
    public int ghi_boi;
    public String ghi_luc;

    // Trường join / tính toán
    public String so_phong;
    public int khu_tro_id;
    public String ten_khu;
    public String ten_nguoi_ghi;
    public int tieu_thu_dien;
    public int tieu_thu_nuoc;
}
