package com.nhom555.rentaladmin.ui.hoadon;

import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;

import com.google.android.material.appbar.MaterialToolbar;
import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.ApiCallback;
import com.nhom555.rentaladmin.data.ApiClient;
import com.nhom555.rentaladmin.data.model.ChiTietHoaDon;
import com.nhom555.rentaladmin.data.model.ChiSoDienNuoc;
import com.nhom555.rentaladmin.data.model.HoaDonChiTiet;
import com.nhom555.rentaladmin.data.model.ThanhToan;
import com.nhom555.rentaladmin.ui.common.TrangThaiManHinh;
import com.nhom555.rentaladmin.util.Anh;
import com.nhom555.rentaladmin.util.DinhDang;
import com.nhom555.rentaladmin.util.GiaoDien;
import com.nhom555.rentaladmin.util.TrangThai;

import java.util.List;

/** Chi tiết một hóa đơn: các khoản, chỉ số điện nước và lịch sử thanh toán. */
public class HoaDonChiTietActivity extends AppCompatActivity {

    public static final String EXTRA_ID = "hoa_don_id";
    public static final String TAG = "555Rental-HoaDonCT";

    private TrangThaiManHinh trangThai;
    private LinearLayout khoiChiTiet;
    private LinearLayout khoiThanhToan;
    private TextView txtChiSo;
    private int id;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_hoa_don_chi_tiet);

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        toolbar.setNavigationOnClickListener(v -> finish());

        id = getIntent().getIntExtra(EXTRA_ID, 0);
        if (id <= 0) {
            finish();
            return;
        }

        trangThai = new TrangThaiManHinh(findViewById(R.id.trang_thai));
        khoiChiTiet = findViewById(R.id.khoi_chi_tiet);
        khoiThanhToan = findViewById(R.id.khoi_thanh_toan);
        txtChiSo = findViewById(R.id.txt_chi_so);

        taiChiTiet();
    }

    private void taiChiTiet() {
        trangThai.dangTai();
        ApiClient.get(this).chiTietHoaDon(id)
                .enqueue(new ApiCallback<HoaDonChiTiet>(this) {
                    @Override
                    public void khiThanhCong(HoaDonChiTiet hd) {
                        trangThai.xong();
                        if (hd == null) {
                            trangThai.rong("Không tìm thấy hóa đơn");
                            return;
                        }
                        hienThi(hd);
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        trangThai.loi(thongDiep, HoaDonChiTietActivity.this::taiChiTiet);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        trangThai.loi(thongDiep, HoaDonChiTietActivity.this::taiChiTiet);
                    }
                });
    }

    private void hienThi(HoaDonChiTiet hd) {
        TextView txtPhong = findViewById(R.id.txt_phong);
        TextView txtThang = findViewById(R.id.txt_thang);
        TextView txtNguoiThue = findViewById(R.id.txt_nguoi_thue);
        TextView txtHan = findViewById(R.id.txt_han);
        TextView txtTong = findViewById(R.id.txt_tong);
        TextView txtDaThu = findViewById(R.id.txt_da_thu);
        TextView txtConNo = findViewById(R.id.txt_con_no);
        TextView txtTrangThai = findViewById(R.id.txt_trang_thai);

        txtPhong.setText("Phòng " + hd.so_phong
                + (hd.ten_khu == null ? "" : " · " + hd.ten_khu));
        txtThang.setText(DinhDang.thang(hd.thang));
        txtNguoiThue.setText("Người thuê: " + (hd.ten_nguoi_thue == null ? "—" : hd.ten_nguoi_thue)
                + (hd.sdt_nguoi_thue == null ? "" : " · " + hd.sdt_nguoi_thue));
        txtHan.setText("Hạn thanh toán: " + DinhDang.ngay(hd.han_thanh_toan));
        txtTong.setText("Tổng tiền: " + DinhDang.tien(hd.tong_tien));
        txtDaThu.setText("Đã thu: " + DinhDang.tien(hd.da_thu));
        txtConNo.setText("Còn nợ: " + DinhDang.tien(hd.con_no));
        GiaoDien.ganBadge(txtTrangThai, TrangThai.hoaDon(hd.trang_thai));

        khoiChiTiet.removeAllViews();
        List<ChiTietHoaDon> chiTiet = hd.chi_tiet;
        if (chiTiet == null || chiTiet.isEmpty()) {
            khoiChiTiet.addView(dongChu("Chưa có dòng chi tiết.", false));
        } else {
            for (ChiTietHoaDon ct : chiTiet) {
                String noiDung = ct.ten_khoan
                        + (ct.so_luong != 1 ? " · SL " + DinhDang.so(ct.so_luong) : "")
                        + " · " + DinhDang.tien(ct.thanh_tien);
                khoiChiTiet.addView(dongChu(noiDung, false));
            }
        }

        ChiSoDienNuoc cs = hd.chi_so;
        if (cs == null) {
            txtChiSo.setText("Chưa có chỉ số của tháng này.");
        } else {
            txtChiSo.setText("Điện: " + cs.dien_dau + " → " + cs.dien_cuoi
                    + " (" + (cs.dien_cuoi - cs.dien_dau) + " kWh)\n"
                    + "Nước: " + cs.nuoc_dau + " → " + cs.nuoc_cuoi
                    + " (" + (cs.nuoc_cuoi - cs.nuoc_dau) + " m³)");
        }

        khoiThanhToan.removeAllViews();
        List<ThanhToan> thanhToan = hd.thanh_toan;
        if (thanhToan == null || thanhToan.isEmpty()) {
            khoiThanhToan.addView(dongChu("Chưa có giao dịch nào.", false));
        } else {
            for (ThanhToan tt : thanhToan) {
                String noiDung = DinhDang.ngayGio(tt.thoi_diem) + " · "
                        + DinhDang.tien(tt.so_tien) + " · "
                        + TrangThai.hinhThuc(tt.hinh_thuc).nhan + " · "
                        + (tt.daXacNhan() ? "Đã xác nhận" : "Chờ xác nhận");
                TextView tv = dongChu(noiDung, !tt.daXacNhan());

                if (tt.anh_bien_lai == null || tt.anh_bien_lai.isEmpty()) {
                    khoiThanhToan.addView(tv);
                    continue;
                }

                LinearLayout hang = new LinearLayout(this);
                hang.setOrientation(LinearLayout.HORIZONTAL);
                hang.setGravity(Gravity.CENTER_VERTICAL);
                hang.addView(tv, new LinearLayout.LayoutParams(
                        0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));

                ImageView img = new ImageView(this);
                int co = GiaoDien.dp(this, 44);
                LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(co, co);
                lp.setMarginStart(GiaoDien.dp(this, 8));
                img.setLayoutParams(lp);
                img.setScaleType(ImageView.ScaleType.CENTER_CROP);
                img.setContentDescription("Biên lai thanh toán");
                Anh.tai(img, tt.anh_bien_lai);
                img.setOnClickListener(v ->
                        Anh.xem(this, tt.anh_bien_lai, "Biên lai thanh toán"));
                hang.addView(img);
                khoiThanhToan.addView(hang);
            }
        }
    }

    private TextView dongChu(String noiDung, boolean canhBao) {
        TextView tv = new TextView(this);
        tv.setText(noiDung);
        tv.setTextSize(13);
        tv.setTextColor(ContextCompat.getColor(this,
                canhBao ? R.color.warning : R.color.text_primary));
        int pad = GiaoDien.dp(this, 6);
        tv.setPadding(0, pad, 0, pad);
        return tv;
    }
}
