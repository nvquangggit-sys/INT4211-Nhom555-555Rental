package com.nhom555.rentaladmin.ui.baocao;

import android.content.res.ColorStateList;
import android.graphics.Typeface;
import android.os.Bundle;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.github.mikephil.charting.charts.BarChart;
import com.github.mikephil.charting.charts.PieChart;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.data.BarData;
import com.github.mikephil.charting.data.BarDataSet;
import com.github.mikephil.charting.data.BarEntry;
import com.github.mikephil.charting.data.PieData;
import com.github.mikephil.charting.data.PieDataSet;
import com.github.mikephil.charting.data.PieEntry;
import com.github.mikephil.charting.formatter.IndexAxisValueFormatter;
import com.github.mikephil.charting.formatter.ValueFormatter;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.card.MaterialCardView;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.ApiCallback;
import com.nhom555.rentaladmin.data.ApiClient;
import com.nhom555.rentaladmin.data.TokenStore;
import com.nhom555.rentaladmin.data.model.BaoCaoCongNo;
import com.nhom555.rentaladmin.data.model.BaoCaoDoanhThu;
import com.nhom555.rentaladmin.data.model.BaoCaoLapDay;
import com.nhom555.rentaladmin.data.model.ChiTietCongNo;
import com.nhom555.rentaladmin.data.model.DoanhThuThang;
import com.nhom555.rentaladmin.data.model.TieuThuBatThuong;
import com.nhom555.rentaladmin.ui.common.TrangThaiManHinh;
import com.nhom555.rentaladmin.util.DinhDang;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

/**
 * Màn hình báo cáo: doanh thu theo tháng (biểu đồ cột), tỷ lệ lấp đầy,
 * công nợ quá hạn và các phòng có mức tiêu thụ điện bất thường.
 *
 * <p>Doanh thu chỉ hiển thị với CHU_TRO. QUAN_LY vẫn xem được lấp đầy,
 * công nợ và tiêu thụ bất thường theo đúng phân quyền của backend.</p>
 */
public class BaoCaoFragment extends Fragment {

    public static final String TAG = "555Rental-BaoCao";

    private static final String KHOA_THANG = "thang_bat_thuong";

    private TrangThaiManHinh trangThai;
    private SwipeRefreshLayout keoXuong;
    private MaterialCardView theDoanhThu;
    private BarChart bieuDo;
    private PieChart bieuDoLapDay;
    private TextView txtTongPhaiThu;
    private TextView txtTongDaThu;
    private TextView txtTongConNo;
    private TextView txtSoHoaDon;
    private TextView txtDoanhThuTrong;
    private LinearLayout khungLapDay;
    private TextView txtLapDayTrong;
    private TextView txtCongNoTong;
    private TextView txtCongNoQuaHan;
    private TextView txtSoHoaDonNo;
    private LinearLayout khungCongNo;
    private TextView txtCongNoTrong;
    private LinearLayout khungBatThuong;
    private TextView txtBatThuongTrong;
    private MaterialButton btnChonThang;

    private String thangBatThuong = DinhDang.thangTruoc(DinhDang.thangNay());
    private int dangCho;
    private boolean coLoi;
    private String loiCuoi;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_bao_cao, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        if (savedInstanceState != null) {
            String daLuu = savedInstanceState.getString(KHOA_THANG);
            if (daLuu != null && !daLuu.isEmpty()) {
                thangBatThuong = daLuu;
            }
        }

        trangThai = new TrangThaiManHinh(view.findViewById(R.id.trang_thai));
        keoXuong = view.findViewById(R.id.keo_xuong);
        theDoanhThu = view.findViewById(R.id.the_doanh_thu);
        bieuDo = view.findViewById(R.id.bieu_do_doanh_thu);
        bieuDoLapDay = view.findViewById(R.id.bieu_do_lap_day);
        txtTongPhaiThu = view.findViewById(R.id.txt_tong_phai_thu);
        txtTongDaThu = view.findViewById(R.id.txt_tong_da_thu);
        txtTongConNo = view.findViewById(R.id.txt_tong_con_no);
        txtSoHoaDon = view.findViewById(R.id.txt_so_hoa_don);
        txtDoanhThuTrong = view.findViewById(R.id.txt_doanh_thu_trong);
        khungLapDay = view.findViewById(R.id.khung_lap_day);
        txtLapDayTrong = view.findViewById(R.id.txt_lap_day_trong);
        txtCongNoTong = view.findViewById(R.id.txt_cong_no_tong);
        txtCongNoQuaHan = view.findViewById(R.id.txt_cong_no_qua_han);
        txtSoHoaDonNo = view.findViewById(R.id.txt_so_hoa_don_no);
        khungCongNo = view.findViewById(R.id.khung_cong_no);
        txtCongNoTrong = view.findViewById(R.id.txt_cong_no_trong);
        khungBatThuong = view.findViewById(R.id.khung_bat_thuong);
        txtBatThuongTrong = view.findViewById(R.id.txt_bat_thuong_trong);
        btnChonThang = view.findViewById(R.id.btn_chon_thang);

        TextView txtKy = view.findViewById(R.id.txt_ky_bao_cao);
        txtKy.setText("Kỳ báo cáo " + DinhDang.thang(DinhDang.thangNay())
                + " • Tiêu thụ " + DinhDang.thang(thangBatThuong));
        TextView txtGhiChu = view.findViewById(R.id.txt_ghi_chu_vai_tro);
        txtGhiChu.setText(TokenStore.laChuTro(requireContext())
                ? "Bạn xem được toàn bộ doanh thu, công nợ và tình trạng lấp đầy."
                : "Bạn phụ trách vận hành: xem lấp đầy, công nợ và tiêu thụ bất thường. Doanh thu được ẩn.");

        btnChonThang.setText(DinhDang.thang(thangBatThuong));
        btnChonThang.setOnClickListener(v -> chonThang());
        keoXuong.setOnRefreshListener(this::taiDuLieu);

        cauHinhBieuDo();
        taiDuLieu();
    }

    // ---------------------------------------------------------------- tải dữ liệu

    private void taiDuLieu() {
        boolean laChuTro = TokenStore.laChuTro(requireContext());
        theDoanhThu.setVisibility(laChuTro ? View.VISIBLE : View.GONE);

        dangCho = laChuTro ? 4 : 3;
        coLoi = false;
        loiCuoi = null;
        trangThai.dangTai();

        if (laChuTro) {
            taiDoanhThu();
        }
        taiLapDay();
        taiCongNo();
        taiBatThuong();
    }

    private void xongMotPhan() {
        dangCho--;
        if (dangCho > 0) {
            return;
        }
        keoXuong.setRefreshing(false);
        if (coLoi) {
            trangThai.loi(loiCuoi, this::taiDuLieu);
        } else {
            trangThai.xong();
        }
    }

    private void ghiNhanLoi(String thongDiep) {
        if (!coLoi) {
            coLoi = true;
            loiCuoi = thongDiep;
        }
        xongMotPhan();
    }

    private void taiDoanhThu() {
        String denThang = DinhDang.thangNay();
        String tuThang = luiThang(denThang, 5);

        ApiClient.get(requireContext()).baoCaoDoanhThu(null, tuThang, denThang)
                .enqueue(new ApiCallback<BaoCaoDoanhThu>(this) {
                    @Override
                    public void khiThanhCong(BaoCaoDoanhThu duLieu) {
                        hienThiDoanhThu(duLieu);
                        xongMotPhan();
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        ghiNhanLoi(thongDiep);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        ghiNhanLoi(thongDiep);
                    }
                });
    }

    private void taiLapDay() {
        ApiClient.get(requireContext()).baoCaoLapDay(null)
                .enqueue(new ApiCallback<List<BaoCaoLapDay>>(this) {
                    @Override
                    public void khiThanhCong(List<BaoCaoLapDay> duLieu) {
                        hienThiLapDay(duLieu);
                        xongMotPhan();
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        ghiNhanLoi(thongDiep);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        ghiNhanLoi(thongDiep);
                    }
                });
    }

    private void taiCongNo() {
        ApiClient.get(requireContext()).baoCaoCongNo(null, null)
                .enqueue(new ApiCallback<BaoCaoCongNo>(this) {
                    @Override
                    public void khiThanhCong(BaoCaoCongNo duLieu) {
                        hienThiCongNo(duLieu);
                        xongMotPhan();
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        ghiNhanLoi(thongDiep);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        ghiNhanLoi(thongDiep);
                    }
                });
    }

    private void taiBatThuong() {
        ApiClient.get(requireContext()).baoCaoTieuThuBatThuong(thangBatThuong, null)
                .enqueue(new ApiCallback<List<TieuThuBatThuong>>(this) {
                    @Override
                    public void khiThanhCong(List<TieuThuBatThuong> duLieu) {
                        btnChonThang.setEnabled(true);
                        hienThiBatThuong(duLieu);
                        if (dangCho > 0) {
                            xongMotPhan();
                        }
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        btnChonThang.setEnabled(true);
                        if (dangCho > 0) {
                            ghiNhanLoi(thongDiep);
                        } else {
                            Toast.makeText(requireContext(), thongDiep, Toast.LENGTH_LONG).show();
                        }
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        btnChonThang.setEnabled(true);
                        if (dangCho > 0) {
                            ghiNhanLoi(thongDiep);
                        } else {
                            Toast.makeText(requireContext(), thongDiep, Toast.LENGTH_LONG).show();
                        }
                    }
                });
    }

    // ---------------------------------------------------------------- doanh thu

    private void hienThiDoanhThu(BaoCaoDoanhThu duLieu) {
        if (duLieu == null || duLieu.tong == null) {
            txtDoanhThuTrong.setVisibility(View.VISIBLE);
            bieuDo.setVisibility(View.GONE);
            return;
        }
        txtTongPhaiThu.setText(DinhDang.tien(duLieu.tong.phai_thu));
        txtTongDaThu.setText(DinhDang.tien(duLieu.tong.da_thu));
        txtTongConNo.setText(DinhDang.tien(duLieu.tong.con_no));
        txtSoHoaDon.setText(String.valueOf(duLieu.tong.so_hoa_don));

        List<DoanhThuThang> theoThang = duLieu.theo_thang == null
                ? new ArrayList<>() : new ArrayList<>(duLieu.theo_thang);
        theoThang.sort(Comparator.comparing(t -> t.thang == null ? "" : t.thang));

        if (theoThang.isEmpty()) {
            bieuDo.setVisibility(View.GONE);
            txtDoanhThuTrong.setVisibility(View.VISIBLE);
            return;
        }

        ArrayList<BarEntry> phaiThu = new ArrayList<>();
        ArrayList<BarEntry> daThu = new ArrayList<>();
        String[] nhan = new String[theoThang.size()];
        for (int i = 0; i < theoThang.size(); i++) {
            DoanhThuThang t = theoThang.get(i);
            phaiThu.add(new BarEntry(i, (float) t.phai_thu));
            daThu.add(new BarEntry(i, (float) t.da_thu));
            nhan[i] = nhanThang(t.thang);
        }

        BarDataSet boPhaiThu = new BarDataSet(phaiThu, "Phải thu");
        boPhaiThu.setColor(ContextCompat.getColor(requireContext(), R.color.brand_700));
        boPhaiThu.setDrawValues(false);
        BarDataSet boDaThu = new BarDataSet(daThu, "Đã thu");
        boDaThu.setColor(ContextCompat.getColor(requireContext(), R.color.success));
        boDaThu.setDrawValues(false);

        BarData duLieuBieuDo = new BarData(boPhaiThu, boDaThu);
        duLieuBieuDo.setBarWidth(0.35f);

        float groupSpace = 0.2f;
        float barSpace = 0.05f;
        bieuDo.getXAxis().setAxisMinimum(0f);
        bieuDo.getXAxis().setAxisMaximum(nhan.length);
        bieuDo.getXAxis().setCenterAxisLabels(true);
        bieuDo.getXAxis().setValueFormatter(new IndexAxisValueFormatter(nhan));
        bieuDo.setData(duLieuBieuDo);
        bieuDo.groupBars(0f, groupSpace, barSpace);
        bieuDo.setVisibility(View.VISIBLE);
        txtDoanhThuTrong.setVisibility(View.GONE);
        bieuDo.animateY(500);
        bieuDo.invalidate();
    }

    private void cauHinhBieuDo() {
        bieuDo.getDescription().setEnabled(false);
        bieuDo.setDrawGridBackground(false);
        bieuDo.setDrawBorders(false);
        bieuDo.setTouchEnabled(false);
        bieuDo.setExtraOffsets(0f, 8f, 0f, 8f);
        bieuDo.setNoDataText("Chưa có dữ liệu doanh thu");

        bieuDo.getAxisRight().setEnabled(false);
        bieuDo.getAxisLeft().setAxisMinimum(0f);
        bieuDo.getAxisLeft().setTextSize(10f);
        bieuDo.getAxisLeft().setValueFormatter(new ValueFormatter() {
            @Override
            public String getFormattedValue(float value) {
                return DinhDang.tienNgan((long) value);
            }
        });

        XAxis trucX = bieuDo.getXAxis();
        trucX.setPosition(XAxis.XAxisPosition.BOTTOM);
        trucX.setDrawGridLines(false);
        trucX.setGranularity(1f);
        trucX.setTextSize(10f);

        bieuDo.getLegend().setTextSize(10f);
        bieuDo.getLegend().setWordWrapEnabled(true);

        bieuDoLapDay.getDescription().setEnabled(false);
        bieuDoLapDay.setUsePercentValues(false);
        bieuDoLapDay.setDrawEntryLabels(false);
        bieuDoLapDay.setHoleRadius(56f);
        bieuDoLapDay.setTransparentCircleRadius(61f);
        bieuDoLapDay.setCenterTextSize(15f);
        bieuDoLapDay.setCenterTextColor(ContextCompat.getColor(requireContext(), R.color.text_primary));
        bieuDoLapDay.setNoDataText("Chưa có dữ liệu lấp đầy");
        bieuDoLapDay.getLegend().setTextSize(10f);
        bieuDoLapDay.getLegend().setWordWrapEnabled(true);
    }

    // ---------------------------------------------------------------- lấp đầy

    private void hienThiLapDay(List<BaoCaoLapDay> duLieu) {
        khungLapDay.removeAllViews();
        if (duLieu == null || duLieu.isEmpty()) {
            txtLapDayTrong.setVisibility(View.VISIBLE);
            bieuDoLapDay.setVisibility(View.GONE);
            return;
        }
        txtLapDayTrong.setVisibility(View.GONE);
        for (BaoCaoLapDay khu : duLieu) {
            khungLapDay.addView(taoDongLapDay(khu));
        }
        veBieuDoLapDay(duLieu);
    }

    /** Biểu đồ tròn tổng hợp toàn bộ khu: đã thuê / trống / đang sửa. */
    private void veBieuDoLapDay(List<BaoCaoLapDay> duLieu) {
        int daThue = 0;
        int trong = 0;
        int dangSua = 0;
        for (BaoCaoLapDay khu : duLieu) {
            daThue += khu.phong_da_thue;
            trong += khu.phong_trong;
            dangSua += khu.phong_dang_sua;
        }
        int tong = daThue + trong + dangSua;
        if (tong <= 0) {
            bieuDoLapDay.setVisibility(View.GONE);
            return;
        }

        ArrayList<PieEntry> phan = new ArrayList<>();
        ArrayList<Integer> mau = new ArrayList<>();
        if (daThue > 0) {
            phan.add(new PieEntry(daThue, "Đã thuê"));
            mau.add(ContextCompat.getColor(requireContext(), R.color.success));
        }
        if (trong > 0) {
            phan.add(new PieEntry(trong, "Trống"));
            mau.add(ContextCompat.getColor(requireContext(), R.color.brand_500));
        }
        if (dangSua > 0) {
            phan.add(new PieEntry(dangSua, "Đang sửa"));
            mau.add(ContextCompat.getColor(requireContext(), R.color.warning));
        }

        PieDataSet bo = new PieDataSet(phan, "");
        bo.setColors(mau);
        bo.setSliceSpace(2f);
        bo.setDrawValues(false);

        bieuDoLapDay.setCenterText(daThue + "/" + tong + "\nphòng đã thuê");
        bieuDoLapDay.setData(new PieData(bo));
        bieuDoLapDay.setVisibility(View.VISIBLE);
        bieuDoLapDay.animateY(500);
        bieuDoLapDay.invalidate();
    }

    private View taoDongLapDay(BaoCaoLapDay khu) {
        LinearLayout hop = new LinearLayout(requireContext());
        hop.setOrientation(LinearLayout.VERTICAL);
        hop.setPadding(0, dp(8), 0, dp(8));

        LinearLayout dongTen = new LinearLayout(requireContext());
        dongTen.setOrientation(LinearLayout.HORIZONTAL);
        dongTen.setGravity(Gravity.CENTER_VERTICAL);

        TextView ten = taoChu(khu.ten_khu == null ? "Khu trọ" : khu.ten_khu,
                R.color.text_primary, 14f, true);
        ten.setLayoutParams(new LinearLayout.LayoutParams(0,
                ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        dongTen.addView(ten);

        TextView phanTram = taoChu(String.format(Locale.US, "%.1f%%", khu.ty_le_lap_day),
                R.color.brand_700, 14f, true);
        dongTen.addView(phanTram);
        hop.addView(dongTen);

        ProgressBar thanh = new ProgressBar(requireContext(), null,
                android.R.attr.progressBarStyleHorizontal);
        thanh.setMax(100);
        thanh.setProgress((int) Math.round(khu.ty_le_lap_day));
        thanh.setProgressTintList(ColorStateList.valueOf(
                ContextCompat.getColor(requireContext(), R.color.brand_500)));
        thanh.setProgressBackgroundTintList(ColorStateList.valueOf(
                ContextCompat.getColor(requireContext(), R.color.divider)));
        LinearLayout.LayoutParams thanhLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(8));
        thanhLp.topMargin = dp(6);
        thanh.setLayoutParams(thanhLp);
        hop.addView(thanh);

        StringBuilder moTa = new StringBuilder()
                .append(khu.phong_da_thue).append('/').append(khu.tong_phong)
                .append(" phòng đã thuê • ").append(khu.phong_trong).append(" trống");
        if (khu.phong_dang_sua > 0) {
            moTa.append(" • ").append(khu.phong_dang_sua).append(" đang sửa");
        }
        TextView txt = taoChu(moTa.toString(), R.color.text_secondary, 11f, false);
        LinearLayout.LayoutParams txtLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        txtLp.topMargin = dp(4);
        txt.setLayoutParams(txtLp);
        hop.addView(txt);
        return hop;
    }

    // ---------------------------------------------------------------- công nợ

    private void hienThiCongNo(BaoCaoCongNo duLieu) {
        khungCongNo.removeAllViews();
        if (duLieu == null) {
            txtCongNoTrong.setVisibility(View.VISIBLE);
            return;
        }
        long quaHan = 0;
        if (duLieu.tong_hop != null) {
            for (com.nhom555.rentaladmin.data.model.TongHopCongNo khu : duLieu.tong_hop) {
                quaHan += khu.no_qua_10_ngay;
            }
        }
        txtCongNoTong.setText("Tổng còn nợ: " + DinhDang.tien(duLieu.tong_con_no));
        txtCongNoQuaHan.setText("Quá hạn trên 10 ngày: " + DinhDang.tien(quaHan));
        txtSoHoaDonNo.setText(duLieu.so_hoa_don_no + " hóa đơn còn nợ");

        List<ChiTietCongNo> chiTiet = duLieu.chi_tiet == null
                ? new ArrayList<>() : new ArrayList<>(duLieu.chi_tiet);
        if (chiTiet.isEmpty()) {
            txtCongNoTrong.setVisibility(View.VISIBLE);
            return;
        }
        txtCongNoTrong.setVisibility(View.GONE);
        chiTiet.sort((a, b) -> Integer.compare(b.so_ngay_qua_han, a.so_ngay_qua_han));

        int hienThi = Math.min(chiTiet.size(), 5);
        for (int i = 0; i < hienThi; i++) {
            khungCongNo.addView(taoDongCongNo(chiTiet.get(i)));
        }
        if (chiTiet.size() > hienThi) {
            TextView conLai = taoChu("... và " + (chiTiet.size() - hienThi)
                    + " hóa đơn khác. Xem chi tiết tại màn hình Hóa đơn.",
                    R.color.text_secondary, 11f, false);
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            lp.topMargin = dp(8);
            conLai.setLayoutParams(lp);
            khungCongNo.addView(conLai);
        }
    }

    private View taoDongCongNo(ChiTietCongNo hoaDon) {
        LinearLayout hop = new LinearLayout(requireContext());
        hop.setOrientation(LinearLayout.VERTICAL);
        hop.setPadding(0, dp(8), 0, dp(8));

        LinearLayout dong1 = new LinearLayout(requireContext());
        dong1.setOrientation(LinearLayout.HORIZONTAL);
        dong1.setGravity(Gravity.CENTER_VERTICAL);

        String phong = hoaDon.so_phong == null ? "Phòng" : "Phòng " + hoaDon.so_phong;
        TextView ten = taoChu(phong + " • " + (hoaDon.ten_khu == null ? "" : hoaDon.ten_khu),
                R.color.text_primary, 13f, true);
        ten.setLayoutParams(new LinearLayout.LayoutParams(0,
                ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        dong1.addView(ten);

        TextView soTien = taoChu(DinhDang.tien(hoaDon.con_no), R.color.danger, 13f, true);
        dong1.addView(soTien);
        hop.addView(dong1);

        String moTa = DinhDang.thang(hoaDon.thang) + " • Hạn " + DinhDang.ngay(hoaDon.han_thanh_toan);
        if (hoaDon.so_ngay_qua_han > 0) {
            moTa += " • Quá hạn " + hoaDon.so_ngay_qua_han + " ngày";
        }
        TextView txtMoTa = taoChu(moTa, R.color.text_secondary, 11f, false);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.topMargin = dp(2);
        txtMoTa.setLayoutParams(lp);
        hop.addView(txtMoTa);

        View vach = new View(requireContext());
        vach.setBackgroundColor(ContextCompat.getColor(requireContext(), R.color.divider));
        LinearLayout.LayoutParams vachLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(1));
        vachLp.topMargin = dp(8);
        vach.setLayoutParams(vachLp);
        hop.addView(vach);
        return hop;
    }

    // ---------------------------------------------------------------- bất thường

    private void hienThiBatThuong(List<TieuThuBatThuong> duLieu) {
        khungBatThuong.removeAllViews();
        if (duLieu == null || duLieu.isEmpty()) {
            txtBatThuongTrong.setVisibility(View.VISIBLE);
            return;
        }
        txtBatThuongTrong.setVisibility(View.GONE);
        for (TieuThuBatThuong phong : duLieu) {
            khungBatThuong.addView(taoDongBatThuong(phong));
        }
    }

    private View taoDongBatThuong(TieuThuBatThuong phong) {
        LinearLayout hop = new LinearLayout(requireContext());
        hop.setOrientation(LinearLayout.VERTICAL);
        hop.setBackgroundResource(R.drawable.bg_o_loc);
        hop.setPadding(dp(10), dp(10), dp(10), dp(10));
        LinearLayout.LayoutParams hopLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        hopLp.bottomMargin = dp(8);
        hop.setLayoutParams(hopLp);

        LinearLayout dong1 = new LinearLayout(requireContext());
        dong1.setOrientation(LinearLayout.HORIZONTAL);
        dong1.setGravity(Gravity.CENTER_VERTICAL);

        String tenPhong = phong.so_phong == null ? "Phòng" : "Phòng " + phong.so_phong;
        TextView ten = taoChu(tenPhong + " • " + (phong.ten_khu == null ? "" : phong.ten_khu),
                R.color.text_primary, 13f, true);
        ten.setLayoutParams(new LinearLayout.LayoutParams(0,
                ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
        dong1.addView(ten);

        TextView phanTram = taoChu(String.format(Locale.US, "+%.1f%%", phong.phan_tram_tang),
                R.color.warning, 13f, true);
        dong1.addView(phanTram);
        hop.addView(dong1);

        String moTa = "Tiêu thụ " + DinhDang.so(phong.tieu_thu) + " kWh • TB 3 tháng "
                + DinhDang.so(phong.tb_3_thang) + " kWh";
        TextView txtMoTa = taoChu(moTa, R.color.text_secondary, 11f, false);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.topMargin = dp(3);
        txtMoTa.setLayoutParams(lp);
        hop.addView(txtMoTa);
        return hop;
    }

    // ---------------------------------------------------------------- chọn tháng

    private void chonThang() {
        final String[] giaTri = new String[12];
        final String[] nhan = new String[12];
        String thangNay = DinhDang.thangNay();
        for (int i = 0; i < 12; i++) {
            giaTri[i] = luiThang(thangNay, i);
            nhan[i] = DinhDang.thang(giaTri[i]) + (i == 0 ? " (tháng này)" : "");
        }
        new MaterialAlertDialogBuilder(requireContext())
                .setTitle("Chọn tháng xem tiêu thụ")
                .setItems(nhan, (dialog, which) -> {
                    thangBatThuong = giaTri[which];
                    btnChonThang.setText(DinhDang.thang(thangBatThuong));
                    TextView txtKy = getView() == null ? null : getView().findViewById(R.id.txt_ky_bao_cao);
                    if (txtKy != null) {
                        txtKy.setText("Kỳ báo cáo " + DinhDang.thang(thangNay)
                                + " • Tiêu thụ " + DinhDang.thang(thangBatThuong));
                    }
                    btnChonThang.setEnabled(false);
                    khungBatThuong.removeAllViews();
                    txtBatThuongTrong.setVisibility(View.GONE);
                    taiBatThuong();
                })
                .show();
    }

    // ---------------------------------------------------------------- tiện ích

    private static String luiThang(String thang, int soThang) {
        String ketQua = thang;
        for (int i = 0; i < soThang; i++) {
            ketQua = DinhDang.thangTruoc(ketQua);
        }
        return ketQua;
    }

    private static String nhanThang(String thang) {
        if (thang == null || thang.length() < 7) {
            return "";
        }
        return "T" + thang.substring(5, 7) + "/" + thang.substring(2, 4);
    }

    private TextView taoChu(String noiDung, int mau, float coChu, boolean dam) {
        TextView txt = new TextView(requireContext());
        txt.setText(noiDung);
        txt.setTextColor(ContextCompat.getColor(requireContext(), mau));
        txt.setTextSize(coChu);
        if (dam) {
            txt.setTypeface(null, Typeface.BOLD);
        }
        return txt;
    }

    private int dp(int giaTri) {
        return Math.round(giaTri * getResources().getDisplayMetrics().density);
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putString(KHOA_THANG, thangBatThuong);
    }
}
