package com.nhom555.rentaladmin.data.model;

/** Lịch khách đặt xem phòng. */
public class LichXemPhong {
    public int id;
    public int phong_id;
    public int khach_id;
    public String thoi_gian;
    public String trang_thai;

    // Trường join
    public String so_phong;
    public int khu_tro_id;
    public String ten_khu;
    public String ten_khach;
    public String sdt_khach;
    public String email_khach;
}
