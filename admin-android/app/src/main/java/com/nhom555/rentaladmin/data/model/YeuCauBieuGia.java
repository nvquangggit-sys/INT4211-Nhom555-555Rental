package com.nhom555.rentaladmin.data.model;

/** Body của PATCH /bieu-gia/{khuTroId}. Chỉ CHU_TRO được gọi. */
public class YeuCauBieuGia {
    public Integer gia_dien;
    public Integer gia_nuoc;
    public Integer phi_rac;
    public Integer phi_gui_xe;

    public YeuCauBieuGia() {
    }

    public YeuCauBieuGia(Integer giaDien, Integer giaNuoc, Integer phiRac, Integer phiGuiXe) {
        this.gia_dien = giaDien;
        this.gia_nuoc = giaNuoc;
        this.phi_rac = phiRac;
        this.phi_gui_xe = phiGuiXe;
    }
}
