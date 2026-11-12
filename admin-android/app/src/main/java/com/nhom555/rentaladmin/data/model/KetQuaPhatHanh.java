package com.nhom555.rentaladmin.data.model;

import java.util.List;

/** Response 201 của POST /hoa-don/phat-hanh (điểm nhấn 2). */
public class KetQuaPhatHanh {
    public String thang;
    public int khu_tro_id;
    public int so_hoa_don_da_tao;
    public long tong_tien;
    public List<HoaDonDaTao> da_tao;
    public List<PhongBoQua> bo_qua;
    public List<PhongThieuChiSo> thieu_chi_so;
    public List<CanhBaoBatThuong> canh_bao_bat_thuong;
}
