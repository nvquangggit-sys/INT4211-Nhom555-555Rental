package com.nhom555.rentaladmin.data.model;

/** Body của POST /auth/dang-nhap. */
public class YeuCauDangNhap {
    public String email;
    public String matKhau;

    public YeuCauDangNhap(String email, String matKhau) {
        this.email = email;
        this.matKhau = matKhau;
    }
}
