package com.nhom555.rentaladmin.data.model;

/**
 * Body lỗi của backend:
 * { "loi": "...", "chi_tiet": { "truong": "dien_cuoi", ... } }.
 * Trường chi_tiet.truong cho biết ô nhập nào gây lỗi để app tô đỏ đúng ô.
 */
public class LoiPhanHoi {

    public String loi;
    public ChiTiet chi_tiet;

    public static class ChiTiet {
        public String truong;
    }

    /** Tên trường gây lỗi (snake_case), hoặc null nếu backend không chỉ rõ. */
    public String truong() {
        return chi_tiet == null ? null : chi_tiet.truong;
    }
}
