package com.nhom555.rentaladmin.ui.khutro;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.button.MaterialButton;
import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.model.KhuTro;
import com.nhom555.rentaladmin.util.DinhDang;

import java.util.ArrayList;
import java.util.List;

/** Adapter danh sách khu trọ. Nút sửa/xóa/biểu giá bị ẩn với tài khoản QUAN_LY. */
public class KhuTroAdapter extends RecyclerView.Adapter<KhuTroAdapter.VH> {

    public interface ThaoTac {
        void sua(KhuTro khu);

        void xoa(KhuTro khu);

        void bieuGia(KhuTro khu);
    }

    private final List<KhuTro> duLieu = new ArrayList<>();
    private final boolean laChuTro;
    private final ThaoTac thaoTac;

    public KhuTroAdapter(boolean laChuTro, ThaoTac thaoTac) {
        this.laChuTro = laChuTro;
        this.thaoTac = thaoTac;
    }

    public void capNhat(List<KhuTro> moi) {
        duLieu.clear();
        if (moi != null) {
            duLieu.addAll(moi);
        }
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_khu_tro, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        KhuTro k = duLieu.get(position);
        h.txtTen.setText(k.ten);
        h.txtSoPhong.setText(k.so_phong + " phòng");
        h.txtDiaChi.setText(k.diaChiDayDu());
        String tienIch = k.tien_ich == null || k.tien_ich.trim().isEmpty()
                ? "Chưa cập nhật tiện ích" : k.tien_ich;
        h.txtTienIch.setText(tienIch);
        h.txtTinhTrang.setText("Trống " + k.so_phong_trong + " · Đã thuê " + k.so_phong_da_thue);

        if (k.gia_dien == null && k.gia_nuoc == null
                && k.phi_rac == null && k.phi_gui_xe == null) {
            h.txtBieuGia.setText("Chưa có biểu giá");
        } else {
            h.txtBieuGia.setText("Điện " + donGia(k.gia_dien) + " đ/kWh · Nước "
                    + donGia(k.gia_nuoc) + " đ/m³ · Rác " + donGia(k.phi_rac)
                    + " đ · Xe " + donGia(k.phi_gui_xe) + " đ");
        }

        int hien = laChuTro ? View.VISIBLE : View.GONE;
        h.btnSua.setVisibility(hien);
        h.btnXoa.setVisibility(hien);
        h.btnBieuGia.setVisibility(hien);

        h.btnSua.setOnClickListener(v -> thaoTac.sua(k));
        h.btnXoa.setOnClickListener(v -> thaoTac.xoa(k));
        h.btnBieuGia.setOnClickListener(v -> thaoTac.bieuGia(k));
    }

    @Override
    public int getItemCount() {
        return duLieu.size();
    }

    /** Đơn giá có thể null khi khu chưa cấu hình biểu giá đầy đủ. */
    private static String donGia(Integer giaTri) {
        return giaTri == null ? "—" : DinhDang.so(giaTri);
    }

    static class VH extends RecyclerView.ViewHolder {
        final TextView txtTen;
        final TextView txtSoPhong;
        final TextView txtDiaChi;
        final TextView txtTienIch;
        final TextView txtTinhTrang;
        final TextView txtBieuGia;
        final MaterialButton btnSua;
        final MaterialButton btnXoa;
        final MaterialButton btnBieuGia;

        VH(@NonNull View v) {
            super(v);
            txtTen = v.findViewById(R.id.txt_ten);
            txtSoPhong = v.findViewById(R.id.txt_so_phong);
            txtDiaChi = v.findViewById(R.id.txt_dia_chi);
            txtTienIch = v.findViewById(R.id.txt_tien_ich);
            txtTinhTrang = v.findViewById(R.id.txt_tinh_trang);
            txtBieuGia = v.findViewById(R.id.txt_bieu_gia);
            btnSua = v.findViewById(R.id.btn_sua);
            btnXoa = v.findViewById(R.id.btn_xoa);
            btnBieuGia = v.findViewById(R.id.btn_bieu_gia);
        }
    }
}
