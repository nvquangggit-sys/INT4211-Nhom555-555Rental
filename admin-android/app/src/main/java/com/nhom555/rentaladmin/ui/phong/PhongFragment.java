package com.nhom555.rentaladmin.ui.phong;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.Spinner;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import com.google.android.material.textfield.TextInputLayout;
import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.ApiCallback;
import com.nhom555.rentaladmin.data.ApiClient;
import com.nhom555.rentaladmin.data.TokenStore;
import com.nhom555.rentaladmin.data.model.KhuTro;
import com.nhom555.rentaladmin.data.model.KetQuaXoa;
import com.nhom555.rentaladmin.data.model.Phong;
import com.nhom555.rentaladmin.data.model.YeuCauPhong;
import com.nhom555.rentaladmin.ui.common.TrangThaiManHinh;
import com.nhom555.rentaladmin.util.DinhDang;
import com.nhom555.rentaladmin.util.GiaoDien;
import com.nhom555.rentaladmin.util.TrangThai;

import java.util.ArrayList;
import java.util.List;

/** Danh sách phòng có bộ lọc theo khu, trạng thái và số phòng. */
public class PhongFragment extends Fragment implements PhongAdapter.ThaoTac {

    public static final String TAG = "555Rental-Phong";

    private TrangThaiManHinh trangThai;
    private SwipeRefreshLayout keoXuong;
    private Spinner spKhu;
    private Spinner spTrangThai;
    private EditText edTim;
    private PhongAdapter adapter;
    private final List<KhuTro> dsKhu = new ArrayList<>();
    private boolean laChuTro;
    private boolean dangKhoiTao = true;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_phong, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        laChuTro = TokenStore.laChuTro(requireContext());
        trangThai = new TrangThaiManHinh(view.findViewById(R.id.trang_thai));
        keoXuong = view.findViewById(R.id.keo_xuong);
        spKhu = view.findViewById(R.id.sp_khu);
        spTrangThai = view.findViewById(R.id.sp_trang_thai);
        edTim = view.findViewById(R.id.ed_tim);

        RecyclerView ds = view.findViewById(R.id.danh_sach);
        ds.setLayoutManager(new LinearLayoutManager(requireContext()));
        adapter = new PhongAdapter(laChuTro, this);
        ds.setAdapter(adapter);

        spTrangThai.setAdapter(mau(TrangThai.dsTrangThaiPhong()));
        spTrangThai.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View v, int position, long id) {
                if (!dangKhoiTao) {
                    taiPhong();
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });

        spKhu.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View v, int position, long id) {
                if (!dangKhoiTao) {
                    taiPhong();
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });

        view.findViewById(R.id.btn_tim).setOnClickListener(v -> taiPhong());
        edTim.setOnEditorActionListener((v, actionId, event) -> {
            taiPhong();
            return true;
        });

        FloatingActionButton fab = view.findViewById(R.id.fab_them);
        fab.setVisibility(laChuTro ? View.VISIBLE : View.GONE);
        fab.setOnClickListener(v -> moHopThoai(null));

        keoXuong.setOnRefreshListener(this::taiPhong);
        taiKhu();
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
                        dangKhoiTao = false;
                        taiPhong();
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        trangThai.loi(thongDiep, PhongFragment.this::taiKhu);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        trangThai.loi(thongDiep, PhongFragment.this::taiKhu);
                    }
                });
    }

    private void taiPhong() {
        if (!keoXuong.isRefreshing()) {
            trangThai.dangTai();
        }
        Integer khuId = null;
        if (spKhu.getSelectedItemPosition() > 0) {
            khuId = dsKhu.get(spKhu.getSelectedItemPosition() - 1).id;
        }
        String maTrangThai = TrangThai.maTrangThaiPhong(
                String.valueOf(spTrangThai.getSelectedItem()));
        if (maTrangThai == null) {
            // Backend mặc định chỉ trả phòng TRONG nếu không truyền trạng thái.
            maTrangThai = "ALL";
        }
        String q = edTim.getText() == null ? "" : edTim.getText().toString().trim();

        ApiClient.get(requireContext()).dsPhong(khuId, maTrangThai,
                        q.isEmpty() ? null : q, 100)
                .enqueue(new ApiCallback<List<Phong>>(this) {
                    @Override
                    public void khiThanhCong(List<Phong> duLieu) {
                        keoXuong.setRefreshing(false);
                        trangThai.xong();
                        adapter.capNhat(duLieu);
                        if (duLieu == null || duLieu.isEmpty()) {
                            trangThai.rong("Không tìm thấy phòng phù hợp bộ lọc.");
                        }
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, PhongFragment.this::taiPhong);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, PhongFragment.this::taiPhong);
                    }
                });
    }

    private void moHopThoai(@Nullable Phong phong) {
        if (dsKhu.isEmpty()) {
            GiaoDien.snack(requireView(), "Chưa có khu trọ. Hãy tạo khu trước.");
            return;
        }
        View v = LayoutInflater.from(requireContext()).inflate(R.layout.dialog_phong, null);
        Spinner spKhuDialog = v.findViewById(R.id.sp_khu);
        Spinner spTrangThaiDialog = v.findViewById(R.id.sp_trang_thai);
        TextInputLayout oSoPhong = v.findViewById(R.id.o_so_phong);
        TextInputLayout oDienTich = v.findViewById(R.id.o_dien_tich);
        TextInputLayout oGiaThue = v.findViewById(R.id.o_gia_thue);
        TextInputLayout oSucChua = v.findViewById(R.id.o_suc_chua);
        EditText edSoPhong = v.findViewById(R.id.ed_so_phong);
        EditText edDienTich = v.findViewById(R.id.ed_dien_tich);
        EditText edGiaThue = v.findViewById(R.id.ed_gia_thue);
        EditText edSucChua = v.findViewById(R.id.ed_suc_chua);

        String[] tenKhu = new String[dsKhu.size()];
        for (int i = 0; i < dsKhu.size(); i++) {
            tenKhu[i] = dsKhu.get(i).ten;
        }
        spKhuDialog.setAdapter(mau(tenKhu));
        spTrangThaiDialog.setAdapter(mau(TrangThai.dsTrangThaiPhong()));
        spTrangThaiDialog.setSelection(1);

        boolean taoMoi = phong == null;
        if (!taoMoi) {
            for (int i = 0; i < dsKhu.size(); i++) {
                if (dsKhu.get(i).id == phong.khu_tro_id) {
                    spKhuDialog.setSelection(i);
                    break;
                }
            }
            edSoPhong.setText(phong.so_phong);
            edDienTich.setText(DinhDang.so(phong.dien_tich));
            edGiaThue.setText(String.valueOf(phong.gia_thue));
            edSucChua.setText(String.valueOf(phong.suc_chua));
            int vt = 0;
            String[] dsTrangThai = TrangThai.dsTrangThaiPhong();
            for (int i = 0; i < dsTrangThai.length; i++) {
                if (TrangThai.maTrangThaiPhong(dsTrangThai[i]) != null
                        && TrangThai.maTrangThaiPhong(dsTrangThai[i]).equals(phong.trang_thai)) {
                    vt = i;
                    break;
                }
            }
            spTrangThaiDialog.setSelection(vt);
        }

        androidx.appcompat.app.AlertDialog dialog = new MaterialAlertDialogBuilder(requireContext())
                .setTitle(taoMoi ? "Thêm phòng" : "Sửa phòng")
                .setView(v)
                .setNegativeButton("Hủy", null)
                .setPositiveButton("Lưu", null)
                .create();

        dialog.setOnShowListener(d -> dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                .setOnClickListener(x -> {
                    oSoPhong.setError(null);
                    oDienTich.setError(null);
                    oGiaThue.setError(null);
                    oSucChua.setError(null);

                    String soPhong = chuoi(edSoPhong);
                    boolean hopLe = true;
                    if (soPhong.isEmpty()) {
                        oSoPhong.setError("Nhập số phòng");
                        hopLe = false;
                    }
                    Double dienTich = soThuc(edDienTich);
                    if (dienTich == null || dienTich <= 0) {
                        oDienTich.setError("Diện tích phải lớn hơn 0");
                        hopLe = false;
                    }
                    Integer giaThue = soNguyen(edGiaThue);
                    if (giaThue == null || giaThue < 0) {
                        oGiaThue.setError("Giá thuê không hợp lệ");
                        hopLe = false;
                    }
                    Integer sucChua = soNguyen(edSucChua);
                    if (sucChua == null || sucChua < 1) {
                        oSucChua.setError("Sức chứa tối thiểu 1 người");
                        hopLe = false;
                    }
                    if (!hopLe) {
                        return;
                    }

                    YeuCauPhong body = new YeuCauPhong();
                    body.khu_tro_id = dsKhu.get(spKhuDialog.getSelectedItemPosition()).id;
                    body.so_phong = soPhong;
                    body.dien_tich = dienTich;
                    body.gia_thue = giaThue;
                    body.suc_chua = sucChua;
                    String nhanTrangThai = String.valueOf(spTrangThaiDialog.getSelectedItem());
                    body.trang_thai = TrangThai.maTrangThaiPhong(nhanTrangThai);
                    if (body.trang_thai == null) {
                        body.trang_thai = "TRONG";
                    }

                    dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE).setEnabled(false);
                    if (taoMoi) {
                        ApiClient.get(requireContext()).taoPhong(body)
                                .enqueue(new ApiCallback<Phong>(this) {
                                    @Override
                                    public void khiThanhCong(Phong duLieu) {
                                        dialog.dismiss();
                                        GiaoDien.snackThanhCong(requireView(), "Đã thêm phòng");
                                        taiPhong();
                                    }

                                    @Override
                                    public void khiLoi(String thongDiep, int maHttp) {
                                        dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                                                .setEnabled(true);
                                        oSoPhong.setError(thongDiep);
                                    }
                                });
                    } else {
                        ApiClient.get(requireContext()).suaPhong(phong.id, body)
                                .enqueue(new ApiCallback<Phong>(this) {
                                    @Override
                                    public void khiThanhCong(Phong duLieu) {
                                        dialog.dismiss();
                                        GiaoDien.snackThanhCong(requireView(), "Đã cập nhật phòng");
                                        taiPhong();
                                    }

                                    @Override
                                    public void khiLoi(String thongDiep, int maHttp) {
                                        dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                                                .setEnabled(true);
                                        oSoPhong.setError(thongDiep);
                                    }
                                });
                    }
                }));
        dialog.show();
    }

    private static String chuoi(EditText ed) {
        return ed.getText() == null ? "" : ed.getText().toString().trim();
    }

    private static Integer soNguyen(EditText ed) {
        try {
            return Integer.parseInt(chuoi(ed));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static Double soThuc(EditText ed) {
        try {
            return Double.parseDouble(chuoi(ed).replace(',', '.'));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    @Override
    public void sua(Phong phong) {
        moHopThoai(phong);
    }

    @Override
    public void xoa(Phong phong) {
        GiaoDien.xacNhan(this, "Xóa phòng",
                "Xóa phòng " + phong.so_phong + "? Chỉ xóa được phòng chưa có hợp đồng và chỉ số.",
                "Xóa", () -> ApiClient.get(requireContext()).xoaPhong(phong.id)
                        .enqueue(new ApiCallback<KetQuaXoa>(this) {
                            @Override
                            public void khiThanhCong(KetQuaXoa duLieu) {
                                GiaoDien.snackThanhCong(requireView(), "Đã xóa phòng");
                                taiPhong();
                            }
                        }));
    }

    @Override
    public void chon(Phong phong) {
        String noiDung = (phong.ten_khu == null ? "" : phong.ten_khu + "\n")
                + "Diện tích: " + DinhDang.so(phong.dien_tich) + " m²\n"
                + "Sức chứa: " + phong.suc_chua + " người\n"
                + "Giá thuê: " + DinhDang.tien(phong.gia_thue) + "/tháng\n"
                + "Trạng thái: " + TrangThai.phong(phong.trang_thai).nhan;
        new MaterialAlertDialogBuilder(requireContext())
                .setTitle("Phòng " + phong.so_phong)
                .setMessage(noiDung)
                .setPositiveButton("Đóng", null)
                .show();
    }
}
