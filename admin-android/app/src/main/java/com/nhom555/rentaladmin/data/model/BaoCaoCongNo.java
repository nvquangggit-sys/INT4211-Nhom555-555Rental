package com.nhom555.rentaladmin.data.model;

import java.util.List;

/** Response của GET /bao-cao/cong-no. */
public class BaoCaoCongNo {
    public List<TongHopCongNo> tong_hop;
    public List<ChiTietCongNo> chi_tiet;
    public int so_hoa_don_no;
    public long tong_con_no;
}
