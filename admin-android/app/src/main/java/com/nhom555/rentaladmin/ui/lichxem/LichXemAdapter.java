package com.nhom555.rentaladmin.ui.lichxem;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.button.MaterialButton;
import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.model.LichXemPhong;
import com.nhom555.rentaladmin.util.DinhDang;
import com.nhom555.rentaladmin.util.GiaoDien;
import com.nhom555.rentaladmin.util.TrangThai;

import java.util.ArrayList;
import java.util.List;

/** Adapter lịch xem phòng, có nút xác nhận / từ chối. */
public class LichXemAdapter extends RecyclerView.Adapter<LichXemAdapter.VH> {

    public interface ThaoTac {
        void capNhat(LichXemPhong lich, String trangThaiMoi, String cauHoi, String nhanNut);
    }

    private final List<LichXemPhong> duLieu = new ArrayList<>();
    private final ThaoTac thaoTac;

    public LichXemAdapter(ThaoTac thaoTac) {
        this.thaoTac = thaoTac;
    }

    public void capNhat(List<LichXemPhong> moi) {
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
                .inflate(R.layout.item_lich_xem, parent, false));
    }

    @Override
    public void onBindViewHolder(@NonNull VH h, int position) {
        LichXemPhong lx = duLieu.get(position);
        h.txtKhach.setText(lx.ten_khach == null ? "Khách" : lx.ten_khach);
        h.txtLienHe.setText((lx.sdt_khach == null ? "—" : lx.sdt_khach)
                + (lx.email_khach == null ? "" : " · " + lx.email_khach));
        h.txtPhong.setText("Phòng " + lx.so_phong
                + (lx.ten_khu == null ? "" : " · " + lx.ten_khu));
        h.txtThoiGian.setText("Hẹn xem: " + DinhDang.ngayGio(lx.thoi_gian));
        GiaoDien.ganBadge(h.txtTrangThai, TrangThai.lichXem(lx.trang_thai));

        boolean cho = "CHO_XAC_NHAN".equals(lx.trang_thai);
        h.btnXacNhan.setVisibility(cho ? View.VISIBLE : View.GONE);
        h.btnTuChoi.setVisibility(cho ? View.VISIBLE : View.GONE);
        h.btnXacNhan.setOnClickListener(v ->
                thaoTac.capNhat(lx, "DA_XAC_NHAN", "Xác nhận lịch hẹn xem phòng này?", "Xác nhận"));
        h.btnTuChoi.setOnClickListener(v ->
                thaoTac.capNhat(lx, "TU_CHOI", "Từ chối lịch hẹn này?", "Từ chối"));
    }

    @Override
    public int getItemCount() {
        return duLieu.size();
    }

    static class VH extends RecyclerView.ViewHolder {
        final TextView txtKhach;
        final TextView txtLienHe;
        final TextView txtPhong;
        final TextView txtThoiGian;
        final TextView txtTrangThai;
        final MaterialButton btnXacNhan;
        final MaterialButton btnTuChoi;

        VH(@NonNull View v) {
            super(v);
            txtKhach = v.findViewById(R.id.txt_khach);
            txtLienHe = v.findViewById(R.id.txt_lien_he);
            txtPhong = v.findViewById(R.id.txt_phong);
            txtThoiGian = v.findViewById(R.id.txt_thoi_gian);
            txtTrangThai = v.findViewById(R.id.txt_trang_thai);
            btnXacNhan = v.findViewById(R.id.btn_xac_nhan);
            btnTuChoi = v.findViewById(R.id.btn_tu_choi);
        }
    }
}
