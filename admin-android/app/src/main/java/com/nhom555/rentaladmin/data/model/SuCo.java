package com.nhom555.rentaladmin.data.model;

/** Sự cố do người thuê báo. */
public class SuCo {
    public int id;
    public int phong_id;
    public int nguoi_bao_id;
    public String loai;
    public String mo_ta;
    public String anh_url;
    public String trang_thai;
    public String xu_ly_luc;

    // Trường join
    public String so_phong;
    public int khu_tro_id;
    public String ten_khu;
    public String ten_nguoi_bao;
    public String sdt_nguoi_bao;
}
