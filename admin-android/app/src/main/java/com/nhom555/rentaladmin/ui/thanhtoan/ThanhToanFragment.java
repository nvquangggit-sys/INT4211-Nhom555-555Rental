package com.nhom555.rentaladmin.ui.thanhtoan;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Spinner;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.ApiCallback;
import com.nhom555.rentaladmin.data.ApiClient;
import com.nhom555.rentaladmin.data.TokenStore;
import com.nhom555.rentaladmin.data.model.KhuTro;
import com.nhom555.rentaladmin.data.model.ThanhToan;
import com.nhom555.rentaladmin.ui.common.TrangThaiManHinh;
import com.nhom555.rentaladmin.util.DinhDang;
import com.nhom555.rentaladmin.util.GiaoDien;

import java.util.ArrayList;
import java.util.List;

/** Danh sách giao dịch thanh toán, chủ trọ xác nhận tiền đã thu. */
public class ThanhToanFragment extends Fragment implements ThanhToanAdapter.ThaoTac {

    public static final String TAG = "555Rental-ThanhToan";

    private TrangThaiManHinh trangThai;
    private SwipeRefreshLayout keoXuong;
    private Spinner spKhu;
    private ThanhToanAdapter adapter;
    private final List<KhuTro> dsKhu = new ArrayList<>();
    private boolean laChuTro;
    private boolean dangKhoiTao = true;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_thanh_toan, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        laChuTro = TokenStore.laChuTro(requireContext());
        trangThai = new TrangThaiManHinh(view.findViewById(R.id.trang_thai));
        keoXuong = view.findViewById(R.id.keo_xuong);
        spKhu = view.findViewById(R.id.sp_khu);

        RecyclerView ds = view.findViewById(R.id.danh_sach);
        ds.setLayoutManager(new LinearLayoutManager(requireContext()));
        adapter = new ThanhToanAdapter(laChuTro, this);
        ds.setAdapter(adapter);

        spKhu.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View v, int position, long id) {
                if (!dangKhoiTao) {
                    taiThanhToan();
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });
        view.findViewById(R.id.btn_tai_lai).setOnClickListener(v -> taiThanhToan());
        keoXuong.setOnRefreshListener(this::taiThanhToan);
        taiKhu();
    }

    private ArrayAdapter<String> mau(List<String> giaTri) {
        ArrayAdapter<String> a = new ArrayAdapter<>(requireContext(),
                android.R.layout.simple_spinner_item, giaTri);
        a.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        return a;
    }

    private void taiKhu() {
        trangThai.dangTai();
        ApiClient.get(requireContext()).dsKhuTro()
                .enqueue(new ApiCallback<List<KhuTro>>(this) {
                    @Override
                    public void khiThanhCong(List<KhuTro> duLieu) {
                        dsKhu.clear();
                        if (duLieu != null) {
                            dsKhu.addAll(duLieu);
                        }
                        List<String> ten = new ArrayList<>();
                        ten.add("Tất cả khu");
                        for (KhuTro k : dsKhu) {
                            ten.add(k.ten);
                        }
                        spKhu.setAdapter(mau(ten));
                        dangKhoiTao = false;
                        taiThanhToan();
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        trangThai.loi(thongDiep, ThanhToanFragment.this::taiKhu);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        trangThai.loi(thongDiep, ThanhToanFragment.this::taiKhu);
                    }
                });
    }

    private void taiThanhToan() {
        if (!keoXuong.isRefreshing()) {
            trangThai.dangTai();
        }
        Integer khuId = spKhu.getSelectedItemPosition() > 0
                ? dsKhu.get(spKhu.getSelectedItemPosition() - 1).id : null;
        ApiClient.get(requireContext()).dsThanhToan(khuId, null)
                .enqueue(new ApiCallback<List<ThanhToan>>(this) {
                    @Override
                    public void khiThanhCong(List<ThanhToan> duLieu) {
                        keoXuong.setRefreshing(false);
                        trangThai.xong();
                        adapter.capNhat(duLieu);
                        if (duLieu == null || duLieu.isEmpty()) {
                            trangThai.rong("Chưa có giao dịch thanh toán nào.");
                        }
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, ThanhToanFragment.this::taiThanhToan);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, ThanhToanFragment.this::taiThanhToan);
                    }
                });
    }

    @Override
    public void xacNhan(ThanhToan tt) {
        GiaoDien.xacNhan(this, "Xác nhận thanh toán",
                "Xác nhận đã nhận " + DinhDang.tien(tt.so_tien) + " cho phòng "
                        + tt.so_phong + "? Thao tác này không thể hoàn tác.",
                "Xác nhận", () -> ApiClient.get(requireContext()).xacNhanThanhToan(tt.id)
                        .enqueue(new ApiCallback<Object>(this) {
                            @Override
                            public void khiThanhCong(Object duLieu) {
                                GiaoDien.snackThanhCong(requireView(), "Đã xác nhận thanh toán");
                                taiThanhToan();
                            }
                        }));
    }
}
