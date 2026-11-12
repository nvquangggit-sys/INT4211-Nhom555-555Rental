package com.nhom555.rentaladmin.ui.phong;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.button.MaterialButton;
import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.model.Phong;
import com.nhom555.rentaladmin.util.DinhDang;
import com.nhom555.rentaladmin.util.GiaoDien;
import com.nhom555.rentaladmin.util.TrangThai;

import java.util.ArrayList;
import java.util.List;

/** Adapter danh sách phòng, kèm badge trạng thái và nút sửa/xóa. */
public class PhongAdapter extends RecyclerView.Adapter<PhongAdapter.VH> {

    public interface ThaoTac {
        void sua(Phong phong);

        void xoa(Phong phong);

        void chon(Phong phong);
    }

    private final List<Phong> duLieu = new ArrayList<>();
    private final boolean laChuTro;
    private final ThaoTac thaoTac;

    public PhongAdapter(boolean laChuTro, ThaoTac thaoTac) {
        this.laChuTro = laChuTro;
        this.thaoTac = thaoTac;
    }

    public void capNhat(List<Phong> moi) {
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
                .inflate(R.layout.item_phong, parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        Phong p = duLieu.get(position);
        h.txtSoPhong.setText("Phòng " + p.so_phong);
        h.txtKhu.setText(p.ten_khu == null ? "Khu trọ" : p.ten_khu);
        h.txtThongTin.setText(DinhDang.so(p.dien_tich) + " m² · " + p.suc_chua
                + " người · " + DinhDang.tien(p.gia_thue) + "/tháng");
        GiaoDien.ganBadge(h.txtTrangThai, TrangThai.phong(p.trang_thai));

        int hien = laChuTro ? View.VISIBLE : View.GONE;
        h.btnSua.setVisibility(hien);
        h.btnXoa.setVisibility(hien);
        h.btnSua.setOnClickListener(v -> thaoTac.sua(p));
        h.btnXoa.setOnClickListener(v -> thaoTac.xoa(p));
        h.itemView.setOnClickListener(v -> thaoTac.chon(p));
    }

    @Override
    public int getItemCount() {
        return duLieu.size();
    }

    static class VH extends RecyclerView.ViewHolder {
        final TextView txtSoPhong;
        final TextView txtKhu;
        final TextView txtThongTin;
        final TextView txtTrangThai;
        final MaterialButton btnSua;
        final MaterialButton btnXoa;

        VH(@NonNull View v) {
            super(v);
            txtSoPhong = v.findViewById(R.id.txt_so_phong);
            txtKhu = v.findViewById(R.id.txt_khu);
            txtThongTin = v.findViewById(R.id.txt_thong_tin);
            txtTrangThai = v.findViewById(R.id.txt_trang_thai);
            btnSua = v.findViewById(R.id.btn_sua);
            btnXoa = v.findViewById(R.id.btn_xoa);
        }
    }
}
