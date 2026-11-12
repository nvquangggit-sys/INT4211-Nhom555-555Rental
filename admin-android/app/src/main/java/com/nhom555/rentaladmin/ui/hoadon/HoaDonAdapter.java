package com.nhom555.rentaladmin.ui.hoadon;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.model.HoaDon;
import com.nhom555.rentaladmin.util.DinhDang;
import com.nhom555.rentaladmin.util.GiaoDien;
import com.nhom555.rentaladmin.util.TrangThai;

import java.util.ArrayList;
import java.util.List;

/** Adapter hóa đơn, bấm vào một dòng để mở chi tiết. */
public class HoaDonAdapter extends RecyclerView.Adapter<HoaDonAdapter.VH> {

    private final List<HoaDon> duLieu = new ArrayList<>();

    public void capNhat(List<HoaDon> moi) {
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
                .inflate(R.layout.item_hoa_don, parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        HoaDon hd = duLieu.get(position);
        Context ctx = h.itemView.getContext();
        h.txtPhong.setText("Phòng " + hd.so_phong
                + (hd.ten_khu == null ? "" : " · " + hd.ten_khu));
        h.txtThang.setText(DinhDang.thang(hd.thang) + " · Hạn " + DinhDang.ngay(hd.han_thanh_toan));
        h.txtTong.setText("Tổng: " + DinhDang.tien(hd.tong_tien));
        h.txtDaThu.setText("Đã thu " + DinhDang.tien(hd.da_thu)
                + " · Còn nợ " + DinhDang.tien(hd.con_no));
        h.txtDaThu.setTextColor(ContextCompat.getColor(ctx,
                hd.con_no <= 0 ? R.color.success : R.color.danger));
        h.txtNguoiThue.setText("Người thuê: " + (hd.ten_nguoi_thue == null ? "—" : hd.ten_nguoi_thue));
        GiaoDien.ganBadge(h.txtTrangThai, TrangThai.hoaDon(hd.trang_thai));

        if (hd.so_ngay_qua_han > 0 && hd.con_no > 0) {
            h.txtQuaHan.setVisibility(View.VISIBLE);
            h.txtQuaHan.setText("Quá hạn " + hd.so_ngay_qua_han + " ngày");
        } else {
            h.txtQuaHan.setVisibility(View.GONE);
        }

        h.itemView.setOnClickListener(v -> {
            Intent intent = new Intent(ctx, HoaDonChiTietActivity.class);
            intent.putExtra(HoaDonChiTietActivity.EXTRA_ID, hd.id);
            ctx.startActivity(intent);
        });
    }

    @Override
    public int getItemCount() {
        return duLieu.size();
    }

    static class VH extends RecyclerView.ViewHolder {
        final TextView txtPhong;
        final TextView txtThang;
        final TextView txtTong;
        final TextView txtDaThu;
        final TextView txtQuaHan;
        final TextView txtNguoiThue;
        final TextView txtTrangThai;

        VH(@NonNull View v) {
            super(v);
            txtPhong = v.findViewById(R.id.txt_phong);
            txtThang = v.findViewById(R.id.txt_thang);
            txtTong = v.findViewById(R.id.txt_tong);
            txtDaThu = v.findViewById(R.id.txt_da_thu);
            txtQuaHan = v.findViewById(R.id.txt_qua_han);
            txtNguoiThue = v.findViewById(R.id.txt_nguoi_thue);
            txtTrangThai = v.findViewById(R.id.txt_trang_thai);
        }
    }
}
