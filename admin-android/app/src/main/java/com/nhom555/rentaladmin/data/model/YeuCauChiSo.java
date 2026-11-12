package com.nhom555.rentaladmin.data.model;

/**
 * Body của POST /chi-so-dien-nuoc.
 * dien_dau / nuoc_dau có thể bỏ trống: backend tự lấy chỉ số cuối của tháng trước.
 */
public class YeuCauChiSo {
    public Integer phong_id;
    public String thang;
    public Integer dien_cuoi;
    public Integer nuoc_cuoi;
    public Integer dien_dau;
    public Integer nuoc_dau;
}
