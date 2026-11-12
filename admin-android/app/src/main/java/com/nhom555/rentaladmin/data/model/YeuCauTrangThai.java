package com.nhom555.rentaladmin.data.model;

/** Body dùng chung cho các API chỉ đổi trạng thái (hợp đồng, sự cố, lịch xem). */
public class YeuCauTrangThai {
    public String trang_thai;
    /** Chỉ dùng khi gia hạn hợp đồng (PATCH /hop-dong/:id). */
    public String ket_thuc;

    public YeuCauTrangThai() {
    }

    public YeuCauTrangThai(String trangThai) {
        this.trang_thai = trangThai;
    }
}
