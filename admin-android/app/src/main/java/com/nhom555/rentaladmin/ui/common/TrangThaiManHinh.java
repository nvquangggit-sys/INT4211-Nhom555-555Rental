package com.nhom555.rentaladmin.ui.common;

import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import com.nhom555.rentaladmin.R;

/**
 * Quản lý 3 trạng thái của một màn hình: đang tải / lỗi mạng / không có dữ liệu.
 * Mọi màn hình danh sách đều nhúng layout @layout/trang_thai để thống nhất cách hiển thị.
 */
public final class TrangThaiManHinh {

    private final View khoiTai;
    private final View khoiLoi;
    private final View khoiRong;
    private final TextView txtLoi;
    private final TextView txtRong;
    private Runnable thuLai;

    public TrangThaiManHinh(View root) {
        khoiTai = root.findViewById(R.id.khoi_tai);
        khoiLoi = root.findViewById(R.id.khoi_loi);
        khoiRong = root.findViewById(R.id.khoi_rong);
        txtLoi = root.findViewById(R.id.txt_loi);
        txtRong = root.findViewById(R.id.txt_rong);
        Button btnThuLai = root.findViewById(R.id.btn_thu_lai);
        btnThuLai.setOnClickListener(v -> {
            if (thuLai != null) {
                dangTai();
                thuLai.run();
            }
        });
    }

    public void dangTai() {
        khoiTai.setVisibility(View.VISIBLE);
        khoiLoi.setVisibility(View.GONE);
        khoiRong.setVisibility(View.GONE);
    }

    public void loi(String thongDiep, Runnable thuLai) {
        this.thuLai = thuLai;
        txtLoi.setText(thongDiep == null || thongDiep.isEmpty()
                ? "Không kết nối được máy chủ. Kiểm tra Wi-Fi và thử lại." : thongDiep);
        khoiTai.setVisibility(View.GONE);
        khoiLoi.setVisibility(View.VISIBLE);
        khoiRong.setVisibility(View.GONE);
    }

    public void rong(String thongDiep) {
        txtRong.setText(thongDiep == null ? "Chưa có dữ liệu" : thongDiep);
        khoiTai.setVisibility(View.GONE);
        khoiLoi.setVisibility(View.GONE);
        khoiRong.setVisibility(View.VISIBLE);
    }

    public void xong() {
        khoiTai.setVisibility(View.GONE);
        khoiLoi.setVisibility(View.GONE);
        khoiRong.setVisibility(View.GONE);
    }
}
