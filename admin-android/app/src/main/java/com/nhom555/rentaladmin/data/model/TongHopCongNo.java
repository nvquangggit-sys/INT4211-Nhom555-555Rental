package com.nhom555.rentaladmin.data.model;

/** Tổng hợp công nợ theo khu trong GET /bao-cao/cong-no. */
public class TongHopCongNo {
    public int khu_tro_id;
    public String ten_khu;
    public int so_hoa_don;
    public long tong_con_no;
    /** Phần nợ của các hóa đơn quá hạn trên 10 ngày. */
    public long no_qua_10_ngay;
}
