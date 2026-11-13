package com.nhom555.rentaladmin.ui.hoadon;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.Spinner;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.google.android.material.textfield.TextInputLayout;
import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.ApiCallback;
import com.nhom555.rentaladmin.data.ApiClient;
import com.nhom555.rentaladmin.data.TokenStore;
import com.nhom555.rentaladmin.data.model.HoaDon;
import com.nhom555.rentaladmin.data.model.KetQuaPhatHanh;
import com.nhom555.rentaladmin.data.model.KhuTro;
import com.nhom555.rentaladmin.ui.common.TrangThaiManHinh;
import com.nhom555.rentaladmin.util.DinhDang;
import com.nhom555.rentaladmin.util.GiaoDien;
import com.nhom555.rentaladmin.util.TrangThai;

import java.util.ArrayList;
import java.util.List;

/**
 * Danh sách hóa đơn có bộ lọc công nợ quá 10 ngày
 * và chức năng phát hành hóa đơn hàng loạt theo khu/tháng.
 */
public class HoaDonFragment extends Fragment {

    public static final String TAG = "555Rental-HoaDon";

    private TrangThaiManHinh trangThai;
    private SwipeRefreshLayout keoXuong;
    private Spinner spKhu;
    private Spinner spTrangThai;
    private EditText edThang;
    private CheckBox cbQuaHan;
    private HoaDonAdapter adapter;
    private final List<KhuTro> dsKhu = new ArrayList<>();
    private boolean dangKhoiTao = true;
    private String thangLuu;
    private int khuLuu = -1;
    private int trangThaiLuu = -1;
    private boolean quaHanLuu;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_hoa_don, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        trangThai = new TrangThaiManHinh(view.findViewById(R.id.trang_thai));
        keoXuong = view.findViewById(R.id.keo_xuong);
        spKhu = view.findViewById(R.id.sp_khu);
        spTrangThai = view.findViewById(R.id.sp_trang_thai);
        edThang = view.findViewById(R.id.ed_thang);
        cbQuaHan = view.findViewById(R.id.cb_qua_han);
        edThang.setText(DinhDang.thangNay());
        if (savedInstanceState != null) {
            thangLuu = savedInstanceState.getString("loc_thang");
            khuLuu = savedInstanceState.getInt("loc_khu", -1);
            trangThaiLuu = savedInstanceState.getInt("loc_trang_thai", -1);
            quaHanLuu = savedInstanceState.getBoolean("loc_qua_han", false);
            if (thangLuu != null) {
                edThang.setText(thangLuu);
            }
            cbQuaHan.setChecked(quaHanLuu);
        }

        RecyclerView ds = view.findViewById(R.id.danh_sach);
        ds.setLayoutManager(new LinearLayoutManager(requireContext()));
        adapter = new HoaDonAdapter();
        ds.setAdapter(adapter);

        spTrangThai.setAdapter(mau(TrangThai.dsTrangThaiHoaDon()));
        AdapterView.OnItemSelectedListener chonLoc = new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View v, int position, long id) {
                if (!dangKhoiTao) {
                    taiHoaDon();
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        };
        spKhu.setOnItemSelectedListener(chonLoc);
        spTrangThai.setOnItemSelectedListener(chonLoc);
        cbQuaHan.setOnCheckedChangeListener((b, checked) -> {
            if (!dangKhoiTao) {
                taiHoaDon();
            }
        });
        view.findViewById(R.id.btn_xem).setOnClickListener(v -> {
            if (thangHopLe()) {
                taiHoaDon();
            } else {
                GiaoDien.snack(requireView(), "Tháng phải có dạng YYYY-MM, ví dụ 2026-11");
            }
        });

        View btnPhatHanh = view.findViewById(R.id.btn_phat_hanh);
        btnPhatHanh.setVisibility(TokenStore.laChuTro(requireContext())
                ? View.VISIBLE : View.GONE);
        btnPhatHanh.setOnClickListener(v -> moHopThoaiPhatHanh());

        keoXuong.setOnRefreshListener(this::taiHoaDon);
        taiKhu();
    }

    private boolean thangHopLe() {
        String thang = edThang.getText() == null ? "" : edThang.getText().toString().trim();
        return thang.isEmpty() || thang.matches("\\d{4}-(0[1-9]|1[0-2])");
    }

    private ArrayAdapter<String> mau(String[] giaTri) {
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
                        String[] ten = new String[dsKhu.size() + 1];
                        ten[0] = "Tất cả khu";
                        for (int i = 0; i < dsKhu.size(); i++) {
                            ten[i + 1] = dsKhu.get(i).ten;
                        }
                        spKhu.setAdapter(mau(ten));
                        if (khuLuu >= 0 && khuLuu < ten.length) {
                            spKhu.setSelection(khuLuu);
                        }
                        if (trangThaiLuu >= 0 && trangThaiLuu < spTrangThai.getCount()) {
                            spTrangThai.setSelection(trangThaiLuu);
                        }
                        dangKhoiTao = false;
                        taiHoaDon();
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        trangThai.loi(thongDiep, HoaDonFragment.this::taiKhu);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        trangThai.loi(thongDiep, HoaDonFragment.this::taiKhu);
                    }
                });
    }

    private void taiHoaDon() {
        String thang = edThang.getText() == null ? "" : edThang.getText().toString().trim();
        if (!thang.isEmpty() && !thang.matches("\\d{4}-(0[1-9]|1[0-2])")) {
            keoXuong.setRefreshing(false);
            edThang.setError("Tháng phải có dạng YYYY-MM, ví dụ 2026-11");
            return;
        }
        edThang.setError(null);
        if (!keoXuong.isRefreshing()) {
            trangThai.dangTai();
        }
        Integer khuId = spKhu.getSelectedItemPosition() > 0
                ? dsKhu.get(spKhu.getSelectedItemPosition() - 1).id : null;
        String maTrangThai = TrangThai.maTrangThaiHoaDon(
                String.valueOf(spTrangThai.getSelectedItem()));
        Integer quaHan = cbQuaHan.isChecked() ? 10 : null;

        ApiClient.get(requireContext()).dsHoaDon(khuId,
                        thang.isEmpty() ? null : thang, maTrangThai, quaHan)
                .enqueue(new ApiCallback<List<HoaDon>>(this) {
                    @Override
                    public void khiThanhCong(List<HoaDon> duLieu) {
                        keoXuong.setRefreshing(false);
                        trangThai.xong();
                        adapter.capNhat(duLieu);
                        if (duLieu == null || duLieu.isEmpty()) {
                            trangThai.rong(cbQuaHan.isChecked()
                                    ? "Không có hóa đơn nợ quá 10 ngày."
                                    : "Không có hóa đơn phù hợp bộ lọc.");
                        }
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, HoaDonFragment.this::taiHoaDon);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, HoaDonFragment.this::taiHoaDon);
                    }
                });
    }

    private void moHopThoaiPhatHanh() {
        if (dsKhu.isEmpty()) {
            GiaoDien.snack(requireView(), "Chưa có khu trọ để phát hành hóa đơn.");
            return;
        }
        View v = LayoutInflater.from(requireContext()).inflate(R.layout.dialog_phat_hanh, null);
        Spinner spKhuDialog = v.findViewById(R.id.sp_khu);
        TextInputLayout oThang = v.findViewById(R.id.o_thang);
        EditText edThangDialog = v.findViewById(R.id.ed_thang);

        String[] ten = new String[dsKhu.size()];
        for (int i = 0; i < dsKhu.size(); i++) {
            ten[i] = dsKhu.get(i).ten;
        }
        spKhuDialog.setAdapter(mau(ten));
        edThangDialog.setText(edThang.getText() == null ? DinhDang.thangNay() : edThang.getText().toString());

        androidx.appcompat.app.AlertDialog dialog = new MaterialAlertDialogBuilder(requireContext())
                .setTitle("Phát hành hóa đơn hàng loạt")
                .setView(v)
                .setNegativeButton("Hủy", null)
                .setPositiveButton("Phát hành", null)
                .create();
        dialog.setOnShowListener(d -> dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                .setOnClickListener(x -> {
                    String thang = edThangDialog.getText() == null
                            ? "" : edThangDialog.getText().toString().trim();
                    if (!thang.matches("\\d{4}-(0[1-9]|1[0-2])")) {
                        oThang.setError("Tháng phải có dạng YYYY-MM");
                        return;
                    }
                    KhuTro khu = dsKhu.get(spKhuDialog.getSelectedItemPosition());
                    dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE).setEnabled(false);
                    ApiClient.get(requireContext()).phatHanhHoaDon(thang, khu.id)
                            .enqueue(new ApiCallback<KetQuaPhatHanh>(this) {
                                @Override
                                public void khiThanhCong(KetQuaPhatHanh duLieu) {
                                    dialog.dismiss();
                                    hienKetQuaPhatHanh(duLieu);
                                    taiHoaDon();
                                }

                                @Override
                                public void khiLoi(String thongDiep, int maHttp) {
                                    dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                                            .setEnabled(true);
                                    oThang.setError(thongDiep);
                                }
                            });
                }));
        dialog.show();
    }

    private void hienKetQuaPhatHanh(KetQuaPhatHanh kq) {
        if (kq == null) {
            GiaoDien.snack(requireView(), "Đã gửi yêu cầu phát hành");
            return;
        }
        StringBuilder sb = new StringBuilder();
        sb.append("Đã tạo: ").append(kq.so_hoa_don_da_tao).append(" hóa đơn\n")
                .append("Tổng tiền: ").append(DinhDang.tien(kq.tong_tien)).append("\n");
        if (kq.bo_qua != null && !kq.bo_qua.isEmpty()) {
            sb.append("Bỏ qua: ").append(kq.bo_qua.size()).append(" phòng\n");
        }
        if (kq.thieu_chi_so != null && !kq.thieu_chi_so.isEmpty()) {
            sb.append("Thiếu chỉ số: ").append(kq.thieu_chi_so.size()).append(" phòng\n");
        }
        if (kq.canh_bao_bat_thuong != null && !kq.canh_bao_bat_thuong.isEmpty()) {
            sb.append("Cảnh báo điện bất thường: ")
                    .append(kq.canh_bao_bat_thuong.size()).append(" phòng\n");
        }
        new MaterialAlertDialogBuilder(requireContext())
                .setTitle("Kết quả phát hành " + DinhDang.thang(kq.thang))
                .setMessage(sb.toString())
                .setPositiveButton("Đóng", null)
                .show();
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        if (edThang == null) {
            return;
        }
        outState.putString("loc_thang", edThang.getText() == null
                ? "" : edThang.getText().toString().trim());
        outState.putInt("loc_khu", spKhu.getSelectedItemPosition());
        outState.putInt("loc_trang_thai", spTrangThai.getSelectedItemPosition());
        outState.putBoolean("loc_qua_han", cbQuaHan.isChecked());
    }
}
