package com.nhom555.rentaladmin.ui.chiso;

import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton;
import com.google.android.material.textfield.TextInputLayout;
import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.ApiCallback;
import com.nhom555.rentaladmin.data.ApiClient;
import com.nhom555.rentaladmin.data.model.ChiSoDienNuoc;
import com.nhom555.rentaladmin.data.model.KetQuaGhiChiSo;
import com.nhom555.rentaladmin.data.model.KhuTro;
import com.nhom555.rentaladmin.data.model.Phong;
import com.nhom555.rentaladmin.data.model.YeuCauChiSo;
import com.nhom555.rentaladmin.ui.common.TrangThaiManHinh;
import com.nhom555.rentaladmin.util.DinhDang;
import com.nhom555.rentaladmin.util.GiaoDien;

import java.util.ArrayList;
import java.util.List;

/** Ghi chỉ số điện nước theo tháng và xem lịch sử chỉ số. */
public class ChiSoFragment extends Fragment implements ChiSoAdapter.ThaoTac {

    public static final String TAG = "555Rental-ChiSo";

    private TrangThaiManHinh trangThai;
    private SwipeRefreshLayout keoXuong;
    private Spinner spKhu;
    private EditText edThang;
    private ChiSoAdapter adapter;
    private final List<KhuTro> dsKhu = new ArrayList<>();
    private final List<Phong> dsPhong = new ArrayList<>();
    private boolean dangKhoiTao = true;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_chi_so, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        trangThai = new TrangThaiManHinh(view.findViewById(R.id.trang_thai));
        keoXuong = view.findViewById(R.id.keo_xuong);
        spKhu = view.findViewById(R.id.sp_khu);
        edThang = view.findViewById(R.id.ed_thang);
        edThang.setText(DinhDang.thangNay());

        RecyclerView ds = view.findViewById(R.id.danh_sach);
        ds.setLayoutManager(new LinearLayoutManager(requireContext()));
        adapter = new ChiSoAdapter(this);
        ds.setAdapter(adapter);

        spKhu.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View v, int position, long id) {
                if (!dangKhoiTao) {
                    taiChiSo();
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });

        view.findViewById(R.id.btn_xem).setOnClickListener(v -> {
            if (thangHopLe()) {
                taiChiSo();
            } else {
                GiaoDien.snack(requireView(), "Tháng phải có dạng YYYY-MM, ví dụ 2026-11");
            }
        });

        ExtendedFloatingActionButton fab = view.findViewById(R.id.fab_them);
        fab.setOnClickListener(v -> moHopThoai());

        keoXuong.setOnRefreshListener(this::taiChiSo);
        taiKhu();
        taiPhong();
    }

    private boolean thangHopLe() {
        String thang = edThang.getText() == null ? "" : edThang.getText().toString().trim();
        return thang.matches("\\d{4}-(0[1-9]|1[0-2])");
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
                        taiChiSo();
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        trangThai.loi(thongDiep, ChiSoFragment.this::taiKhu);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        trangThai.loi(thongDiep, ChiSoFragment.this::taiKhu);
                    }
                });
    }

    private void taiPhong() {
        ApiClient.get(requireContext()).dsPhong(null, "ALL", null, 100)
                .enqueue(new ApiCallback<List<Phong>>(this) {
                    @Override
                    public void khiThanhCong(List<Phong> duLieu) {
                        dsPhong.clear();
                        if (duLieu != null) {
                            dsPhong.addAll(duLieu);
                        }
                    }
                });
    }

    private void taiChiSo() {
        if (!keoXuong.isRefreshing()) {
            trangThai.dangTai();
        }
        Integer khuId = spKhu.getSelectedItemPosition() > 0
                ? dsKhu.get(spKhu.getSelectedItemPosition() - 1).id : null;
        String thang = edThang.getText() == null ? "" : edThang.getText().toString().trim();
        ApiClient.get(requireContext()).dsChiSo(khuId, thang.isEmpty() ? null : thang)
                .enqueue(new ApiCallback<List<ChiSoDienNuoc>>(this) {
                    @Override
                    public void khiThanhCong(List<ChiSoDienNuoc> duLieu) {
                        keoXuong.setRefreshing(false);
                        trangThai.xong();
                        adapter.capNhat(duLieu);
                        if (duLieu == null || duLieu.isEmpty()) {
                            trangThai.rong("Chưa ghi chỉ số cho tháng này.");
                        }
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, ChiSoFragment.this::taiChiSo);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, ChiSoFragment.this::taiChiSo);
                    }
                });
    }

    private void moHopThoai() {
        if (dsPhong.isEmpty()) {
            GiaoDien.snack(requireView(), "Đang tải danh sách phòng, thử lại sau ít giây.");
            taiPhong();
            return;
        }
        View v = LayoutInflater.from(requireContext()).inflate(R.layout.dialog_chi_so, null);
        Spinner spPhong = v.findViewById(R.id.sp_phong);
        TextInputLayout oThang = v.findViewById(R.id.o_thang);
        TextInputLayout oDienDau = v.findViewById(R.id.o_dien_dau);
        TextInputLayout oDienCuoi = v.findViewById(R.id.o_dien_cuoi);
        TextInputLayout oNuocDau = v.findViewById(R.id.o_nuoc_dau);
        TextInputLayout oNuocCuoi = v.findViewById(R.id.o_nuoc_cuoi);
        EditText edThangDialog = v.findViewById(R.id.ed_thang);
        EditText edDienDau = v.findViewById(R.id.ed_dien_dau);
        EditText edDienCuoi = v.findViewById(R.id.ed_dien_cuoi);
        EditText edNuocDau = v.findViewById(R.id.ed_nuoc_dau);
        EditText edNuocCuoi = v.findViewById(R.id.ed_nuoc_cuoi);
        TextView txtGoiY = v.findViewById(R.id.txt_goi_y);
        TextView txtTieuThu = v.findViewById(R.id.txt_tieu_thu_du_kien);

        List<String> ten = new ArrayList<>();
        for (Phong p : dsPhong) {
            ten.add("Phòng " + p.so_phong + " · " + p.ten_khu);
        }
        spPhong.setAdapter(mau(ten));
        edThangDialog.setText(edThang.getText() == null ? DinhDang.thangNay() : edThang.getText().toString());

        TextWatcher tinhLai = new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                capNhatTieuThu(txtTieuThu, edDienDau, edDienCuoi, edNuocDau, edNuocCuoi);
            }
        };
        edDienDau.addTextChangedListener(tinhLai);
        edDienCuoi.addTextChangedListener(tinhLai);
        edNuocDau.addTextChangedListener(tinhLai);
        edNuocCuoi.addTextChangedListener(tinhLai);

        spPhong.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view1, int position, long id) {
                if (position < 0 || position >= dsPhong.size()) {
                    return;
                }
                taiChiSoDau(dsPhong.get(position).id, chuoi(edThangDialog),
                        edDienDau, edNuocDau, txtGoiY);
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });
        if (!dsPhong.isEmpty()) {
            taiChiSoDau(dsPhong.get(0).id, chuoi(edThangDialog), edDienDau, edNuocDau, txtGoiY);
        }
        capNhatTieuThu(txtTieuThu, edDienDau, edDienCuoi, edNuocDau, edNuocCuoi);

        androidx.appcompat.app.AlertDialog dialog = new MaterialAlertDialogBuilder(requireContext())
                .setTitle("Ghi chỉ số điện nước")
                .setView(v)
                .setNegativeButton("Hủy", null)
                .setPositiveButton("Lưu", null)
                .create();
        dialog.setOnShowListener(d -> dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                .setOnClickListener(x -> {
                    oThang.setError(null);
                    oDienDau.setError(null);
                    oDienCuoi.setError(null);
                    oNuocDau.setError(null);
                    oNuocCuoi.setError(null);

                    String thang = chuoi(edThangDialog);
                    boolean hopLe = true;
                    if (!thang.matches("\\d{4}-(0[1-9]|1[0-2])")) {
                        oThang.setError("Tháng phải có dạng YYYY-MM");
                        hopLe = false;
                    }
                    Integer dienCuoi = soNguyen(edDienCuoi);
                    if (dienCuoi == null || dienCuoi < 0) {
                        oDienCuoi.setError("Chỉ số điện cuối không hợp lệ");
                        hopLe = false;
                    }
                    Integer nuocCuoi = soNguyen(edNuocCuoi);
                    if (nuocCuoi == null || nuocCuoi < 0) {
                        oNuocCuoi.setError("Chỉ số nước cuối không hợp lệ");
                        hopLe = false;
                    }
                    Integer dienDau = soNguyen(edDienDau);
                    if (!chuoi(edDienDau).isEmpty() && (dienDau == null || dienDau < 0)) {
                        oDienDau.setError("Không hợp lệ");
                        hopLe = false;
                    }
                    Integer nuocDau = soNguyen(edNuocDau);
                    if (!chuoi(edNuocDau).isEmpty() && (nuocDau == null || nuocDau < 0)) {
                        oNuocDau.setError("Không hợp lệ");
                        hopLe = false;
                    }
                    if (dienDau != null && dienCuoi != null && dienCuoi < dienDau) {
                        oDienCuoi.setError("Chỉ số cuối phải ≥ chỉ số đầu");
                        hopLe = false;
                    }
                    if (nuocDau != null && nuocCuoi != null && nuocCuoi < nuocDau) {
                        oNuocCuoi.setError("Chỉ số cuối phải ≥ chỉ số đầu");
                        hopLe = false;
                    }
                    if (!hopLe) {
                        return;
                    }

                    YeuCauChiSo body = new YeuCauChiSo();
                    body.phong_id = dsPhong.get(spPhong.getSelectedItemPosition()).id;
                    body.thang = thang;
                    body.dien_cuoi = dienCuoi;
                    body.nuoc_cuoi = nuocCuoi;
                    body.dien_dau = dienDau;
                    body.nuoc_dau = nuocDau;

                    dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE).setEnabled(false);
                    ApiClient.get(requireContext()).ghiChiSo(body)
                            .enqueue(new ApiCallback<KetQuaGhiChiSo>(this) {
                                @Override
                                public void khiThanhCong(KetQuaGhiChiSo duLieu) {
                                    dialog.dismiss();
                                    if (duLieu != null && duLieu.canh_bao != null) {
                                        new MaterialAlertDialogBuilder(requireContext())
                                                .setTitle("Cảnh báo tiêu thụ bất thường")
                                                .setMessage(duLieu.canh_bao.thong_diep
                                                        + "\n\nTiêu thụ tháng này: " + duLieu.canh_bao.tieu_thu_hien_tai
                                                        + " kWh\nTrung bình 3 tháng: " + DinhDang.so(duLieu.canh_bao.trung_binh_3_thang)
                                                        + " kWh\nTăng: " + DinhDang.so(duLieu.canh_bao.phan_tram_tang) + "%")
                                                .setPositiveButton("Đã hiểu", null)
                                                .show();
                                    } else {
                                        GiaoDien.snackThanhCong(requireView(), "Đã ghi chỉ số");
                                    }
                                    taiChiSo();
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

    /**
     * Lấy chỉ số cuối của bản ghi gần nhất trước tháng đang ghi để điền sẵn chỉ số đầu kỳ.
     * Người dùng vẫn có thể sửa tay nếu đồng hồ được thay mới.
     */
    private void taiChiSoDau(int phongId, String thang, EditText edDienDau, EditText edNuocDau,
                             TextView txtGoiY) {
        ApiClient.get(requireContext()).dsChiSoTheoPhong(phongId)
                .enqueue(new ApiCallback<List<ChiSoDienNuoc>>(this) {
                    @Override
                    public void khiThanhCong(List<ChiSoDienNuoc> duLieu) {
                        ChiSoDienNuoc truoc = null;
                        if (duLieu != null) {
                            for (ChiSoDienNuoc c : duLieu) {
                                if (c.thang != null && thang != null
                                        && c.thang.compareTo(thang) < 0) {
                                    truoc = c;
                                    break;
                                }
                            }
                        }
                        if (truoc == null) {
                            txtGoiY.setText("Chưa có chỉ số tháng trước. Nhập chỉ số đầu kỳ thủ công nếu cần.");
                            return;
                        }
                        edDienDau.setText(String.valueOf(truoc.dien_cuoi));
                        edNuocDau.setText(String.valueOf(truoc.nuoc_cuoi));
                        txtGoiY.setText("Chỉ số đầu lấy từ " + DinhDang.thang(truoc.thang)
                                + ": điện " + truoc.dien_cuoi + " kWh · nước "
                                + truoc.nuoc_cuoi + " m³");
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        txtGoiY.setText("Không tải được chỉ số tháng trước: " + thongDiep);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        txtGoiY.setText("Không tải được chỉ số tháng trước. Kiểm tra kết nối mạng.");
                    }
                });
    }

    /** Cập nhật dòng "Tiêu thụ dự kiến" ngay khi người dùng nhập chỉ số cuối. */
    private void capNhatTieuThu(TextView dich, EditText edDienDau, EditText edDienCuoi,
                                EditText edNuocDau, EditText edNuocCuoi) {
        Integer dienDau = soNguyen(edDienDau);
        Integer dienCuoi = soNguyen(edDienCuoi);
        Integer nuocDau = soNguyen(edNuocDau);
        Integer nuocCuoi = soNguyen(edNuocCuoi);

        if (dienCuoi == null && nuocCuoi == null) {
            dich.setText("Tiêu thụ dự kiến: —");
            return;
        }
        StringBuilder sb = new StringBuilder("Tiêu thụ dự kiến: ");
        if (dienDau != null && dienCuoi != null) {
            sb.append(Math.max(0, dienCuoi - dienDau)).append(" kWh điện");
        } else {
            sb.append("— kWh điện");
        }
        sb.append(" · ");
        if (nuocDau != null && nuocCuoi != null) {
            sb.append(Math.max(0, nuocCuoi - nuocDau)).append(" m³ nước");
        } else {
            sb.append("— m³ nước");
        }
        dich.setText(sb.toString());
    }

    private static String chuoi(EditText ed) {
        return ed.getText() == null ? "" : ed.getText().toString().trim();
    }

    private static Integer soNguyen(EditText ed) {
        String s = chuoi(ed);
        if (s.isEmpty()) {
            return null;
        }
        try {
            return Integer.parseInt(s);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    @Override
    public void chon(ChiSoDienNuoc c) {
        String noiDung = "Điện: " + c.dien_dau + " → " + c.dien_cuoi
                + " (" + c.tieu_thu_dien + " kWh)\n"
                + "Nước: " + c.nuoc_dau + " → " + c.nuoc_cuoi
                + " (" + c.tieu_thu_nuoc + " m³)\n"
                + "Người ghi: " + (c.ten_nguoi_ghi == null ? "—" : c.ten_nguoi_ghi) + "\n"
                + "Thời điểm: " + DinhDang.ngayGio(c.ghi_luc);
        new MaterialAlertDialogBuilder(requireContext())
                .setTitle("Chỉ số " + DinhDang.thang(c.thang))
                .setMessage(noiDung)
                .setPositiveButton("Đóng", null)
                .show();
    }
}
