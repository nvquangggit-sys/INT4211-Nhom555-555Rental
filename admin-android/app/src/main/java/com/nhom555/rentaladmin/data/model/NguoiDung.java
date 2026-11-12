package com.nhom555.rentaladmin.data.model;

/** Tài khoản người dùng (chủ trọ / quản lý / người thuê). Backend không trả mật khẩu. */
public class NguoiDung {
    public int id;
    public String email;
    public String ho_ten;
    public String sdt;
    public String cccd;
    public String vai_tro;

    public String tenVaiTro() {
        if ("CHU_TRO".equals(vai_tro)) {
            return "Chủ trọ";
        }
        if ("QUAN_LY".equals(vai_tro)) {
            return "Quản lý";
        }
        if ("NGUOI_THUE".equals(vai_tro)) {
            return "Người thuê";
        }
        return "Không rõ";
    }
}
