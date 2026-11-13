package com.nhom555.rentaladmin.ui.hopdong;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.button.MaterialButton;
import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.model.HopDong;
import com.nhom555.rentaladmin.util.DinhDang;
import com.nhom555.rentaladmin.util.GiaoDien;
import com.nhom555.rentaladmin.util.TrangThai;

import java.util.ArrayList;
import java.util.List;

/** Adapter hợp đồng thuê. */
public class HopDongAdapter extends RecyclerView.Adapter<HopDongAdapter.VH> {

    public interface ThaoTac {
        void giaHan(HopDong hopDong);

        void ketThuc(HopDong hopDong);

        void chon(HopDong hopDong);
    }

    private final List<HopDong> duLieu = new ArrayList<>();
    private final boolean laChuTro;
    private final ThaoTac thaoTac;

    public HopDongAdapter(boolean laChuTro, ThaoTac thaoTac) {
        this.laChuTro = laChuTro;
        this.thaoTac = thaoTac;
    }

    public void capNhat(List<HopDong> moi) {
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
                .inflate(R.layout.item_hop_dong, parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        HopDong hd = duLieu.get(position);
        String khu = hd.ten_khu == null ? "" : " · " + hd.ten_khu;
        h.txtPhong.setText("Phòng " + hd.so_phong + khu);
        h.txtNguoiThue.setText("Người thuê: "
                + (hd.ten_nguoi_thue == null ? "—" : hd.ten_nguoi_thue)
                + (hd.sdt_nguoi_thue == null ? "" : " · " + hd.sdt_nguoi_thue));
        h.txtThoiHan.setText(DinhDang.ngay(hd.bat_dau) + " → " + DinhDang.ngay(hd.ket_thuc));
        String conLai;
        if (hd.so_ngay_con_lai > 0) {
            conLai = "Còn " + hd.so_ngay_con_lai + " ngày";
        } else if (hd.so_ngay_con_lai == 0) {
            conLai = "Hết hạn hôm nay";
        } else {
            conLai = "Đã quá hạn " + Math.abs(hd.so_ngay_con_lai) + " ngày";
        }
        h.txtConLai.setText(conLai + " · Cọc " + DinhDang.tien(hd.tien_coc)
                + " · " + hd.so_nguoi + " người");
        GiaoDien.ganBadge(h.txtTrangThai, TrangThai.hopDong(hd.trang_thai));

        boolean hieuLuc = "HIEU_LUC".equals(hd.trang_thai);
        int hien = laChuTro && hieuLuc ? View.VISIBLE : View.GONE;
        h.btnGiaHan.setVisibility(hien);
        h.btnKetThuc.setVisibility(hien);
        h.btnGiaHan.setOnClickListener(v -> thaoTac.giaHan(hd));
        h.btnKetThuc.setOnClickListener(v -> thaoTac.ketThuc(hd));
        h.itemView.setOnClickListener(v -> thaoTac.chon(hd));
    }

    @Override
    public int getItemCount() {
        return duLieu.size();
    }

    static class VH extends RecyclerView.ViewHolder {
        final TextView txtPhong;
        final TextView txtNguoiThue;
        final TextView txtThoiHan;
        final TextView txtConLai;
        final TextView txtTrangThai;
        final MaterialButton btnGiaHan;
        final MaterialButton btnKetThuc;

        VH(@NonNull View v) {
            super(v);
            txtPhong = v.findViewById(R.id.txt_phong);
            txtNguoiThue = v.findViewById(R.id.txt_nguoi_thue);
            txtThoiHan = v.findViewById(R.id.txt_thoi_han);
            txtConLai = v.findViewById(R.id.txt_con_lai);
            txtTrangThai = v.findViewById(R.id.txt_trang_thai);
            btnGiaHan = v.findViewById(R.id.btn_gia_han);
            btnKetThuc = v.findViewById(R.id.btn_ket_thuc);
        }
    }
}
