package com.nhom555.rentaladmin.ui.tongquan;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.ApiCallback;
import com.nhom555.rentaladmin.data.ApiClient;
import com.nhom555.rentaladmin.data.TokenStore;
import com.nhom555.rentaladmin.data.model.BaoCaoTongQuan;
import com.nhom555.rentaladmin.data.model.ThongKeHoaDonThang;
import com.nhom555.rentaladmin.data.model.ThongKePhong;
import com.nhom555.rentaladmin.data.model.ThongKeSuCo;
import com.nhom555.rentaladmin.ui.common.TrangThaiManHinh;
import com.nhom555.rentaladmin.ui.main.MainActivity;
import com.nhom555.rentaladmin.util.DinhDang;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/** Màn hình tổng quan: số liệu phòng, sự cố, hóa đơn tháng và thao tác nhanh. */
public class TongQuanFragment extends Fragment {

    public static final String TAG = "555Rental-TongQuan";

    private TrangThaiManHinh trangThai;
    private TextView txtTongPhong;
    private TextView txtDaThue;
    private TextView txtTrong;
    private TextView txtDangSua;
    private TextView txtSuCoMoi;
    private TextView txtDangXuLy;
    private TextView txtPhaiThu;
    private TextView txtDaThu;
    private TextView txtConNo;
    private View theDoanhThu;
    private boolean laChuTro;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_tong_quan, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        trangThai = new TrangThaiManHinh(view.findViewById(R.id.trang_thai));
        txtTongPhong = view.findViewById(R.id.txt_tong_phong);
        txtDaThue = view.findViewById(R.id.txt_da_thue);
        txtTrong = view.findViewById(R.id.txt_trong);
        txtDangSua = view.findViewById(R.id.txt_dang_sua);
        txtSuCoMoi = view.findViewById(R.id.txt_su_co_moi);
        txtDangXuLy = view.findViewById(R.id.txt_dang_xu_ly);
        txtPhaiThu = view.findViewById(R.id.txt_phai_thu);
        txtDaThu = view.findViewById(R.id.txt_da_thu);
        txtConNo = view.findViewById(R.id.txt_con_no);
        theDoanhThu = view.findViewById(R.id.the_doanh_thu);
        laChuTro = TokenStore.laChuTro(requireContext());
        // QUAN_LY không được xem doanh thu; ẩn hẳn thẻ số liệu tiền.
        if (!laChuTro) {
            theDoanhThu.setVisibility(View.GONE);
        }

        TextView txtChao = view.findViewById(R.id.txt_chao);
        txtChao.setText("Xin chào, " + TokenStore.hoTen(requireContext()));
        TextView txtHomNay = view.findViewById(R.id.txt_hom_nay);
        txtHomNay.setText("Hôm nay " + new SimpleDateFormat("dd/MM/yyyy", Locale.forLanguageTag("vi-VN"))
                .format(new Date()));
        TextView txtMoTa = view.findViewById(R.id.txt_vai_tro_mo_ta);
        txtMoTa.setText(TokenStore.laChuTro(requireContext())
                ? "Bạn đang quản lý toàn bộ khu trọ và xem được doanh thu."
                : "Bạn phụ trách ghi chỉ số và xử lý sự cố. Doanh thu được ẩn theo phân quyền.");

        view.findViewById(R.id.btn_ghi_chi_so).setOnClickListener(v ->
                ((MainActivity) requireActivity()).moManHinh(R.id.nav_chi_so));
        View nutHoaDon = view.findViewById(R.id.btn_hoa_don);
        nutHoaDon.setVisibility(TokenStore.laChuTro(requireContext()) ? View.VISIBLE : View.GONE);
        nutHoaDon.setOnClickListener(v ->
                ((MainActivity) requireActivity()).moManHinh(R.id.nav_hoa_don));
        view.findViewById(R.id.btn_su_co).setOnClickListener(v ->
                ((MainActivity) requireActivity()).moManHinh(R.id.nav_su_co));

        taiDuLieu();
    }

    private void taiDuLieu() {
        trangThai.dangTai();
        ApiClient.get(requireContext()).baoCaoTongQuan()
                .enqueue(new ApiCallback<BaoCaoTongQuan>(this) {
                    @Override
                    public void khiThanhCong(BaoCaoTongQuan duLieu) {
                        trangThai.xong();
                        if (duLieu == null) {
                            trangThai.rong("Không có dữ liệu tổng quan");
                            return;
                        }
                        ThongKePhong p = duLieu.phong;
                        if (p != null) {
                            txtTongPhong.setText(String.valueOf(p.tong_phong));
                            txtDaThue.setText(String.valueOf(p.da_thue));
                            txtTrong.setText(String.valueOf(p.trong));
                            txtDangSua.setText(String.valueOf(p.dang_sua));
                        }
                        ThongKeSuCo s = duLieu.su_co;
                        if (s != null) {
                            txtSuCoMoi.setText(String.valueOf(s.moi));
                            txtDangXuLy.setText(String.valueOf(s.dang_xu_ly));
                        }
                        ThongKeHoaDonThang hd = duLieu.hoa_don_thang_nay;
                        if (hd == null || !laChuTro) {
                            theDoanhThu.setVisibility(View.GONE);
                        } else {
                            theDoanhThu.setVisibility(View.VISIBLE);
                            txtPhaiThu.setText("Phải thu: " + DinhDang.tien(hd.phai_thu));
                            txtDaThu.setText("Đã thu: " + DinhDang.tien(hd.da_thu));
                            txtConNo.setText("Còn nợ: " + DinhDang.tien(hd.con_no));
                        }
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        trangThai.loi(thongDiep, TongQuanFragment.this::taiDuLieu);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        trangThai.loi(thongDiep, TongQuanFragment.this::taiDuLieu);
                    }
                });
    }
}
