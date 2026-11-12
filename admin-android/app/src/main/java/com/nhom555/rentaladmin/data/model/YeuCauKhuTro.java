package com.nhom555.rentaladmin.data.model;

/** Body của POST/PATCH /khu-tro. Trường null sẽ được backend giữ nguyên khi PATCH. */
public class YeuCauKhuTro {
    public String ten;
    public String dia_chi;
    public String phuong_xa;
    public String tien_ich;
    public YeuCauBieuGia bieu_gia;
}
