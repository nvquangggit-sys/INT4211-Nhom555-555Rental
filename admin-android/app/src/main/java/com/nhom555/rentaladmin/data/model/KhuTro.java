package com.nhom555.rentaladmin.data.model;

/**
 * Một khu trọ. GET /khu-tro trả kèm đơn giá và số phòng;
 * POST /khu-tro trả kèm object bieu_gia lồng nhau.
 */
public class KhuTro {
    public int id;
    public String ten;
    public String dia_chi;
    public String phuong_xa;
    public String tien_ich;
    public int chu_tro_id;

    public Integer gia_dien;
    public Integer gia_nuoc;
    public Integer phi_rac;
    public Integer phi_gui_xe;

    public int so_phong;
    public int so_phong_trong;
    public int so_phong_da_thue;

    public BieuGia bieu_gia;

    public String diaChiDayDu() {
        String a = dia_chi == null ? "" : dia_chi.trim();
        String b = phuong_xa == null ? "" : phuong_xa.trim();
        if (a.isEmpty()) {
            return b;
        }
        if (b.isEmpty()) {
            return a;
        }
        return a + ", " + b;
    }
}
