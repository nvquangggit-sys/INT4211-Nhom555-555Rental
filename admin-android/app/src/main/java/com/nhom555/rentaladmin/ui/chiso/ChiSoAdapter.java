package com.nhom555.rentaladmin.ui.chiso;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.model.ChiSoDienNuoc;
import com.nhom555.rentaladmin.util.DinhDang;

import java.util.ArrayList;
import java.util.List;

/** Adapter chỉ số điện nước theo tháng. */
public class ChiSoAdapter extends RecyclerView.Adapter<ChiSoAdapter.VH> {

    public interface ThaoTac {
        void chon(ChiSoDienNuoc chiSo);
    }

    private final List<ChiSoDienNuoc> duLieu = new ArrayList<>();
    private final ThaoTac thaoTac;

    public ChiSoAdapter(ThaoTac thaoTac) {
        this.thaoTac = thaoTac;
    }

    public void capNhat(List<ChiSoDienNuoc> moi) {
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
                .inflate(R.layout.item_chi_so, parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        ChiSoDienNuoc c = duLieu.get(position);
        h.txtPhong.setText("Phòng " + c.so_phong
                + (c.ten_khu == null ? "" : " · " + c.ten_khu));
        h.txtThang.setText(DinhDang.thang(c.thang));
        h.txtDien.setText("Điện: " + DinhDang.so(c.dien_dau) + " → " + DinhDang.so(c.dien_cuoi));
        h.txtNuoc.setText("Nước: " + DinhDang.so(c.nuoc_dau) + " → " + DinhDang.so(c.nuoc_cuoi));
        h.txtTieuThu.setText("Tiêu thụ " + c.tieu_thu_dien + " kWh · " + c.tieu_thu_nuoc + " m³");
        h.txtNguoiGhi.setText("Ghi bởi " + (c.ten_nguoi_ghi == null ? "—" : c.ten_nguoi_ghi)
                + " · " + DinhDang.ngayGio(c.ghi_luc));
        h.itemView.setOnClickListener(v -> thaoTac.chon(c));
    }

    @Override
    public int getItemCount() {
        return duLieu.size();
    }

    static class VH extends RecyclerView.ViewHolder {
        final TextView txtPhong;
        final TextView txtThang;
        final TextView txtDien;
        final TextView txtNuoc;
        final TextView txtTieuThu;
        final TextView txtNguoiGhi;

        VH(@NonNull View v) {
            super(v);
            txtPhong = v.findViewById(R.id.txt_phong);
            txtThang = v.findViewById(R.id.txt_thang);
            txtDien = v.findViewById(R.id.txt_dien);
            txtNuoc = v.findViewById(R.id.txt_nuoc);
            txtTieuThu = v.findViewById(R.id.txt_tieu_thu);
            txtNguoiGhi = v.findViewById(R.id.txt_nguoi_ghi);
        }
    }
}
