package com.nhom555.rentaladmin.data.model;

/** Phòng cho thuê. GET /phong trả kèm thông tin khu và đơn giá. */
public class Phong {
    public int id;
    public int khu_tro_id;
    public String so_phong;
    public double dien_tich;
    public int gia_thue;
    public int suc_chua;
    public String trang_thai;
    public String anh_url;

    // Trường join từ khu_tro / bieu_gia
    public String ten_khu;
    public String dia_chi;
    public String phuong_xa;
    public String tien_ich;
    public Integer gia_dien;
    public Integer gia_nuoc;
    public Integer phi_rac;
    public Integer phi_gui_xe;
    public int tong_so;

    public String moTaNgan() {
        return so_phong + " · " + ten_khu;
    }
}
