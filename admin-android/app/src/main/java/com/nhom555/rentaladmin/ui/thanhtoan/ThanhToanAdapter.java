package com.nhom555.rentaladmin.ui.thanhtoan;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.button.MaterialButton;
import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.model.ThanhToan;
import com.nhom555.rentaladmin.util.Anh;
import com.nhom555.rentaladmin.util.DinhDang;
import com.nhom555.rentaladmin.util.GiaoDien;
import com.nhom555.rentaladmin.util.TrangThai;

import java.util.ArrayList;
import java.util.List;

/** Adapter giao dịch thanh toán; nút xác nhận chỉ hiện với CHU_TRO và giao dịch chờ. */
public class ThanhToanAdapter extends RecyclerView.Adapter<ThanhToanAdapter.VH> {

    public interface ThaoTac {
        void xacNhan(ThanhToan thanhToan);
    }

    private final List<ThanhToan> duLieu = new ArrayList<>();
    private final boolean laChuTro;
    private final ThaoTac thaoTac;

    public ThanhToanAdapter(boolean laChuTro, ThaoTac thaoTac) {
        this.laChuTro = laChuTro;
        this.thaoTac = thaoTac;
    }

    public void capNhat(List<ThanhToan> moi) {
        duLieu.clear();
        if (moi != null) {
            duLieu.addAll(moi);
        }
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        return new VH(LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_thanh_toan, parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        ThanhToan tt = duLieu.get(position);
        h.txtPhong.setText("Phòng " + tt.so_phong
                + (tt.ten_khu == null ? "" : " · " + tt.ten_khu));
        h.txtNguoiThue.setText("Người thuê: " + (tt.ten_nguoi_thue == null ? "—" : tt.ten_nguoi_thue));
        h.txtSoTien.setText(DinhDang.tien(tt.so_tien));
        h.txtHinhThuc.setText(TrangThai.hinhThuc(tt.hinh_thuc).nhan + " · "
                + DinhDang.ngayGio(tt.thoi_diem));
        h.txtHoaDon.setText("Hóa đơn " + DinhDang.thang(tt.thang)
                + " · Tổng " + DinhDang.tien(tt.tong_tien)
                + " · Đã thu " + DinhDang.tien(tt.da_thu));

        if (tt.daXacNhan()) {
            GiaoDien.ganBadge(h.txtTrangThai, TrangThai.hoaDon("DA_THU"));
            h.txtTrangThai.setText("Đã xác nhận");
            h.btnXacNhan.setVisibility(View.GONE);
        } else {
            GiaoDien.ganBadge(h.txtTrangThai, TrangThai.hoaDon("CHUA_THU"));
            h.txtTrangThai.setText("Chờ xác nhận");
            h.btnXacNhan.setVisibility(laChuTro ? View.VISIBLE : View.GONE);
        }
        h.btnXacNhan.setOnClickListener(v -> thaoTac.xacNhan(tt));

        if (tt.anh_bien_lai == null || tt.anh_bien_lai.isEmpty()) {
            h.btnBienLai.setVisibility(View.GONE);
        } else {
            h.btnBienLai.setVisibility(View.VISIBLE);
            h.btnBienLai.setOnClickListener(v -> Anh.xem(
                    h.itemView.getContext(), tt.anh_bien_lai, "Biên lai thanh toán"));
        }
    }

    @Override
    public int getItemCount() {
        return duLieu.size();
    }

    static class VH extends RecyclerView.ViewHolder {
        final TextView txtPhong;
        final TextView txtNguoiThue;
        final TextView txtSoTien;
        final TextView txtHinhThuc;
        final TextView txtHoaDon;
        final TextView txtTrangThai;
        final MaterialButton btnXacNhan;
        final MaterialButton btnBienLai;

        VH(@NonNull View v) {
            super(v);
            txtPhong = v.findViewById(R.id.txt_phong);
            txtNguoiThue = v.findViewById(R.id.txt_nguoi_thue);
            txtSoTien = v.findViewById(R.id.txt_so_tien);
            txtHinhThuc = v.findViewById(R.id.txt_hinh_thuc);
            txtHoaDon = v.findViewById(R.id.txt_hoa_don);
            txtTrangThai = v.findViewById(R.id.txt_trang_thai);
            btnXacNhan = v.findViewById(R.id.btn_xac_nhan);
            btnBienLai = v.findViewById(R.id.btn_bien_lai);
        }
    }
}
