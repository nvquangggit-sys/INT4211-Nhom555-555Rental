package com.nhom555.rentaladmin.ui.suco;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.button.MaterialButton;
import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.model.SuCo;
import com.nhom555.rentaladmin.util.DinhDang;
import com.nhom555.rentaladmin.util.GiaoDien;
import com.nhom555.rentaladmin.util.TrangThai;

import java.util.ArrayList;
import java.util.List;

/** Adapter sự cố; nút đổi trạng thái theo quy trình Mới → Đang xử lý → Đã xử lý. */
public class SuCoAdapter extends RecyclerView.Adapter<SuCoAdapter.VH> {

    public interface ThaoTac {
        void doiTrangThai(SuCo suCo, String trangThaiMoi, String nhanNut);

        void xemChiTiet(SuCo suCo);
    }

    private final List<SuCo> duLieu = new ArrayList<>();
    private final ThaoTac thaoTac;

    public SuCoAdapter(ThaoTac thaoTac) {
        this.thaoTac = thaoTac;
    }

    public void capNhat(List<SuCo> moi) {
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
                .inflate(R.layout.item_su_co, parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        SuCo s = duLieu.get(position);
        h.txtLoai.setText(s.loai == null ? "Sự cố" : s.loai);
        h.txtPhong.setText("Phòng " + s.so_phong
                + (s.ten_khu == null ? "" : " · " + s.ten_khu));
        h.txtMoTa.setText(s.mo_ta);
        h.txtNguoiBao.setText("Người báo: " + (s.ten_nguoi_bao == null ? "—" : s.ten_nguoi_bao)
                + (s.sdt_nguoi_bao == null ? "" : " · " + s.sdt_nguoi_bao));
        GiaoDien.ganBadge(h.txtTrangThai, TrangThai.suCo(s.trang_thai));
        h.itemView.setOnClickListener(v -> thaoTac.xemChiTiet(s));

        if (s.xu_ly_luc != null) {
            h.txtXuLyLuc.setVisibility(View.VISIBLE);
            h.txtXuLyLuc.setText("Xử lý lúc " + DinhDang.ngayGio(s.xu_ly_luc));
        } else {
            h.txtXuLyLuc.setVisibility(View.GONE);
        }

        if ("MOI".equals(s.trang_thai)) {
            h.btnXuLy.setVisibility(View.VISIBLE);
            h.btnXuLy.setText("Nhận xử lý");
            h.btnXuLy.setOnClickListener(v ->
                    thaoTac.doiTrangThai(s, "DANG_XU_LY", "Nhận xử lý sự cố này?"));
        } else if ("DANG_XU_LY".equals(s.trang_thai)) {
            h.btnXuLy.setVisibility(View.VISIBLE);
            h.btnXuLy.setText("Đã xử lý");
            h.btnXuLy.setOnClickListener(v ->
                    thaoTac.doiTrangThai(s, "DA_XU_LY", "Đánh dấu sự cố đã xử lý xong?"));
        } else {
            h.btnXuLy.setVisibility(View.GONE);
        }
    }

    @Override
    public int getItemCount() {
        return duLieu.size();
    }

    static class VH extends RecyclerView.ViewHolder {
        final TextView txtLoai;
        final TextView txtTrangThai;
        final TextView txtPhong;
        final TextView txtMoTa;
        final TextView txtNguoiBao;
        final TextView txtXuLyLuc;
        final MaterialButton btnXuLy;

        VH(@NonNull View v) {
            super(v);
            txtLoai = v.findViewById(R.id.txt_loai);
            txtTrangThai = v.findViewById(R.id.txt_trang_thai);
            txtPhong = v.findViewById(R.id.txt_phong);
            txtMoTa = v.findViewById(R.id.txt_mo_ta);
            txtNguoiBao = v.findViewById(R.id.txt_nguoi_bao);
            txtXuLyLuc = v.findViewById(R.id.txt_xu_ly_luc);
            btnXuLy = v.findViewById(R.id.btn_xu_ly);
        }
    }
}
