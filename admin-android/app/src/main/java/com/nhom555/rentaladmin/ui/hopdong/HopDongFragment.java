package com.nhom555.rentaladmin.ui.hopdong;

import android.app.DatePickerDialog;
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
import com.nhom555.rentaladmin.data.model.HopDong;
import com.nhom555.rentaladmin.data.model.KhuTro;
import com.nhom555.rentaladmin.data.model.NguoiDung;
import com.nhom555.rentaladmin.data.model.Phong;
import com.nhom555.rentaladmin.data.model.YeuCauHopDong;
import com.nhom555.rentaladmin.data.model.YeuCauTrangThai;
import com.nhom555.rentaladmin.ui.common.TrangThaiManHinh;
import com.nhom555.rentaladmin.util.DinhDang;
import com.nhom555.rentaladmin.util.GiaoDien;
import com.nhom555.rentaladmin.util.TrangThai;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Locale;

/** Danh sách hợp đồng, tạo hợp đồng mới, gia hạn và kết thúc hợp đồng. */
public class HopDongFragment extends Fragment implements HopDongAdapter.ThaoTac {

    public static final String TAG = "555Rental-HopDong";
    private static final String[] TRANG_THAI = {"Tất cả", "Hiệu lực", "Hết hạn", "Đã hủy"};

    private TrangThaiManHinh trangThai;
    private SwipeRefreshLayout keoXuong;
    private Spinner spKhu;
    private Spinner spTrangThai;
    private EditText edTim;
    private HopDongAdapter adapter;
    private final List<KhuTro> dsKhu = new ArrayList<>();
    private final List<Phong> dsPhongTrong = new ArrayList<>();
    private final List<NguoiDung> dsNguoiThue = new ArrayList<>();
    private boolean laChuTro;
    private boolean dangKhoiTao = true;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_hop_dong, container, false);
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
        adapter = new HopDongAdapter(laChuTro, this);
        ds.setAdapter(adapter);

        spTrangThai.setAdapter(mau(TRANG_THAI));
        AdapterView.OnItemSelectedListener chonLoc = new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View v, int position, long id) {
                if (!dangKhoiTao) {
                    taiHopDong();
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        };
        spKhu.setOnItemSelectedListener(chonLoc);
        spTrangThai.setOnItemSelectedListener(chonLoc);
        view.findViewById(R.id.btn_tim).setOnClickListener(v -> taiHopDong());
        edTim.setOnEditorActionListener((v, actionId, event) -> {
            taiHopDong();
            return true;
        });

        FloatingActionButton fab = view.findViewById(R.id.fab_them);
        fab.setVisibility(laChuTro ? View.VISIBLE : View.GONE);
        fab.setOnClickListener(v -> moHopThoaiTao());

        keoXuong.setOnRefreshListener(() -> {
            taiHopDong();
            taiDuLieuPhu();
        });
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
                        taiHopDong();
                        taiDuLieuPhu();
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        trangThai.loi(thongDiep, HopDongFragment.this::taiKhu);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        trangThai.loi(thongDiep, HopDongFragment.this::taiKhu);
                    }
                });
    }

    private void taiDuLieuPhu() {
        ApiClient.get(requireContext()).dsPhong(null, "TRONG", null, 100)
                .enqueue(new ApiCallback<List<Phong>>(this) {
                    @Override
                    public void khiThanhCong(List<Phong> duLieu) {
                        dsPhongTrong.clear();
                        if (duLieu != null) {
                            dsPhongTrong.addAll(duLieu);
                        }
                    }
                });
        ApiClient.get(requireContext()).dsNguoiDung("NGUOI_THUE", null)
                .enqueue(new ApiCallback<List<NguoiDung>>(this) {
                    @Override
                    public void khiThanhCong(List<NguoiDung> duLieu) {
                        dsNguoiThue.clear();
                        if (duLieu != null) {
                            dsNguoiThue.addAll(duLieu);
                        }
                    }
                });
    }

    private void taiHopDong() {
        if (!keoXuong.isRefreshing()) {
            trangThai.dangTai();
        }
        Integer khuId = spKhu.getSelectedItemPosition() > 0
                ? dsKhu.get(spKhu.getSelectedItemPosition() - 1).id : null;
        String trangThaiChon = String.valueOf(spTrangThai.getSelectedItem());
        String ma;
        if ("Hiệu lực".equals(trangThaiChon)) {
            ma = "HIEU_LUC";
        } else if ("Hết hạn".equals(trangThaiChon)) {
            ma = "HET_HAN";
        } else if ("Đã hủy".equals(trangThaiChon)) {
            ma = "DA_HUY";
        } else {
            ma = null;
        }
        String q = edTim.getText() == null ? "" : edTim.getText().toString().trim();

        ApiClient.get(requireContext()).dsHopDong(khuId, ma, q.isEmpty() ? null : q)
                .enqueue(new ApiCallback<List<HopDong>>(this) {
                    @Override
                    public void khiThanhCong(List<HopDong> duLieu) {
                        keoXuong.setRefreshing(false);
                        trangThai.xong();
                        adapter.capNhat(duLieu);
                        if (duLieu == null || duLieu.isEmpty()) {
                            trangThai.rong("Không có hợp đồng phù hợp bộ lọc.");
                        }
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, HopDongFragment.this::taiHopDong);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, HopDongFragment.this::taiHopDong);
                    }
                });
    }

    private void moHopThoaiTao() {
        if (dsPhongTrong.isEmpty() || dsNguoiThue.isEmpty()) {
            GiaoDien.snack(requireView(), "Đang tải danh sách phòng trống / người thuê, thử lại sau ít giây.");
            taiDuLieuPhu();
            return;
        }
        View v = LayoutInflater.from(requireContext()).inflate(R.layout.dialog_hop_dong, null);
        Spinner spPhong = v.findViewById(R.id.sp_phong);
        Spinner spNguoiThue = v.findViewById(R.id.sp_nguoi_thue);
        TextInputLayout oBatDau = v.findViewById(R.id.o_bat_dau);
        TextInputLayout oKetThuc = v.findViewById(R.id.o_ket_thuc);
        TextInputLayout oTienCoc = v.findViewById(R.id.o_tien_coc);
        TextInputLayout oSoNguoi = v.findViewById(R.id.o_so_nguoi);
        EditText edBatDau = v.findViewById(R.id.ed_bat_dau);
        EditText edKetThuc = v.findViewById(R.id.ed_ket_thuc);
        EditText edTienCoc = v.findViewById(R.id.ed_tien_coc);
        EditText edSoNguoi = v.findViewById(R.id.ed_so_nguoi);

        String[] tenPhong = new String[dsPhongTrong.size()];
        for (int i = 0; i < dsPhongTrong.size(); i++) {
            Phong p = dsPhongTrong.get(i);
            tenPhong[i] = "Phòng " + p.so_phong + " · " + p.ten_khu
                    + " · " + DinhDang.tien(p.gia_thue);
        }
        spPhong.setAdapter(mau(tenPhong));
        String[] tenNguoi = new String[dsNguoiThue.size()];
        for (int i = 0; i < dsNguoiThue.size(); i++) {
            NguoiDung n = dsNguoiThue.get(i);
            tenNguoi[i] = n.ho_ten + " · " + n.email;
        }
        spNguoiThue.setAdapter(mau(tenNguoi));

        Calendar homNay = Calendar.getInstance();
        edBatDau.setText(ngay(homNay));
        homNay.add(Calendar.YEAR, 1);
        edKetThuc.setText(ngay(homNay));
        edTienCoc.setText("0");
        edSoNguoi.setText("1");

        edBatDau.setOnClickListener(x -> chonNgay(edBatDau));
        edKetThuc.setOnClickListener(x -> chonNgay(edKetThuc));

        spPhong.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view1, int position, long id) {
                Phong p = dsPhongTrong.get(position);
                TextViewGoiY(v, "Sức chứa tối đa " + p.suc_chua
                        + " người · Giá thuê " + DinhDang.tien(p.gia_thue));
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });

        androidx.appcompat.app.AlertDialog dialog = new MaterialAlertDialogBuilder(requireContext())
                .setTitle("Tạo hợp đồng thuê")
                .setView(v)
                .setNegativeButton("Hủy", null)
                .setPositiveButton("Tạo", null)
                .create();
        dialog.setOnShowListener(d -> dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                .setOnClickListener(x -> {
                    oBatDau.setError(null);
                    oKetThuc.setError(null);
                    oTienCoc.setError(null);
                    oSoNguoi.setError(null);
                    String batDau = chuoi(edBatDau);
                    String ketThuc = chuoi(edKetThuc);
                    boolean hopLe = true;
                    if (!batDau.matches("\\d{4}-\\d{2}-\\d{2}")) {
                        oBatDau.setError("Chọn ngày bắt đầu");
                        hopLe = false;
                    }
                    if (!ketThuc.matches("\\d{4}-\\d{2}-\\d{2}")) {
                        oKetThuc.setError("Chọn ngày kết thúc");
                        hopLe = false;
                    } else if (ketThuc.compareTo(batDau) <= 0) {
                        oKetThuc.setError("Ngày kết thúc phải sau ngày bắt đầu");
                        hopLe = false;
                    }
                    Integer tienCoc = soNguyen(edTienCoc);
                    if (tienCoc == null || tienCoc < 0) {
                        oTienCoc.setError("Tiền cọc không hợp lệ");
                        hopLe = false;
                    }
                    Integer soNguoi = soNguyen(edSoNguoi);
                    if (soNguoi == null || soNguoi < 1) {
                        oSoNguoi.setError("Số người tối thiểu 1");
                        hopLe = false;
                    } else {
                        int vt = spPhong.getSelectedItemPosition();
                        if (vt >= 0 && vt < dsPhongTrong.size()
                                && soNguoi > dsPhongTrong.get(vt).suc_chua) {
                            oSoNguoi.setError("Vượt sức chứa tối đa "
                                    + dsPhongTrong.get(vt).suc_chua + " người");
                            hopLe = false;
                        }
                    }
                    if (!hopLe) {
                        return;
                    }

                    YeuCauHopDong body = new YeuCauHopDong();
                    body.phong_id = dsPhongTrong.get(spPhong.getSelectedItemPosition()).id;
                    body.nguoi_thue_id = dsNguoiThue.get(spNguoiThue.getSelectedItemPosition()).id;
                    body.bat_dau = batDau;
                    body.ket_thuc = ketThuc;
                    body.tien_coc = tienCoc;
                    body.so_nguoi = soNguoi;

                    dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE).setEnabled(false);
                    ApiClient.get(requireContext()).taoHopDong(body)
                            .enqueue(new ApiCallback<HopDong>(this) {
                                @Override
                                public void khiThanhCong(HopDong duLieu) {
                                    dialog.dismiss();
                                    GiaoDien.snackThanhCong(requireView(), "Đã tạo hợp đồng");
                                    taiHopDong();
                                    taiDuLieuPhu();
                                }

                                @Override
                                public void khiLoi(String thongDiep, int maHttp) {
                                    dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                                            .setEnabled(true);
                                    oBatDau.setError(thongDiep);
                                }
                            });
                }));
        dialog.show();
    }

    private void TextViewGoiY(View root, String noiDung) {
        android.widget.TextView tv = root.findViewById(R.id.txt_goi_y);
        tv.setText(noiDung);
    }

    private void chonNgay(EditText ed) {
        Calendar c = Calendar.getInstance();
        try {
            String[] phan = chuoi(ed).split("-");
            c.set(Integer.parseInt(phan[0]), Integer.parseInt(phan[1]) - 1,
                    Integer.parseInt(phan[2]));
        } catch (RuntimeException ignored) {
            // dùng ngày hôm nay
        }
        new DatePickerDialog(requireContext(), (view, nam, thang, ngay) -> {
            Calendar chon = Calendar.getInstance();
            chon.set(nam, thang, ngay);
            ed.setText(ngay(chon));
        }, c.get(Calendar.YEAR), c.get(Calendar.MONTH), c.get(Calendar.DAY_OF_MONTH)).show();
    }

    private static String ngay(Calendar c) {
        return String.format(Locale.US, "%04d-%02d-%02d",
                c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH));
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

    @Override
    public void giaHan(HopDong hopDong) {
        EditText ed = new EditText(requireContext());
        ed.setText(hopDong.ket_thuc);
        ed.setSingleLine(true);
        ed.setOnClickListener(v -> chonNgay(ed));
        ed.setFocusable(false);
        int pad = (int) (20 * getResources().getDisplayMetrics().density);
        ed.setPadding(pad, pad / 2, pad, pad / 2);

        androidx.appcompat.app.AlertDialog dialog = new MaterialAlertDialogBuilder(requireContext())
                .setTitle("Gia hạn hợp đồng")
                .setMessage("Chọn ngày kết thúc mới cho phòng " + hopDong.so_phong + ".")
                .setView(ed)
                .setNegativeButton("Hủy", null)
                .setPositiveButton("Lưu", null)
                .create();
        dialog.setOnShowListener(d -> dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                .setOnClickListener(v -> {
                    String moi = chuoi(ed);
                    if (!moi.matches("\\d{4}-\\d{2}-\\d{2}")) {
                        GiaoDien.snack(requireView(), "Ngày không hợp lệ (YYYY-MM-DD)");
                        return;
                    }
                    String batDau = hopDong.bat_dau == null ? ""
                            : hopDong.bat_dau.substring(0, Math.min(10, hopDong.bat_dau.length()));
                    if (!batDau.isEmpty() && moi.compareTo(batDau) <= 0) {
                        GiaoDien.snack(requireView(),
                                "Ngày kết thúc mới phải sau ngày bắt đầu "
                                        + DinhDang.ngay(hopDong.bat_dau));
                        return;
                    }
                    YeuCauTrangThai body = new YeuCauTrangThai();
                    body.ket_thuc = moi;
                    dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE).setEnabled(false);
                    ApiClient.get(requireContext()).suaHopDong(hopDong.id, body)
                            .enqueue(new ApiCallback<HopDong>(this) {
                                @Override
                                public void khiThanhCong(HopDong duLieu) {
                                    dialog.dismiss();
                                    GiaoDien.snackThanhCong(requireView(), "Đã gia hạn hợp đồng");
                                    taiHopDong();
                                }

                                @Override
                                public void khiLoi(String thongDiep, int maHttp) {
                                    dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                                            .setEnabled(true);
                                    GiaoDien.snack(requireView(), thongDiep);
                                }
                            });
                }));
        dialog.show();
    }

    @Override
    public void ketThuc(HopDong hopDong) {
        GiaoDien.xacNhan(this, "Kết thúc hợp đồng",
                "Kết thúc hợp đồng phòng " + hopDong.so_phong + "? Phòng sẽ trở về trạng thái Trống.",
                "Kết thúc", () -> ApiClient.get(requireContext())
                        .suaHopDong(hopDong.id, new YeuCauTrangThai("DA_HUY"))
                        .enqueue(new ApiCallback<HopDong>(this) {
                            @Override
                            public void khiThanhCong(HopDong duLieu) {
                                GiaoDien.snackThanhCong(requireView(), "Đã kết thúc hợp đồng");
                                taiHopDong();
                                taiDuLieuPhu();
                            }
                        }));
    }

    @Override
    public void chon(HopDong hopDong) {
        String noiDung = "Khu: " + (hopDong.ten_khu == null ? "—" : hopDong.ten_khu) + "\n"
                + "Người thuê: " + (hopDong.ten_nguoi_thue == null ? "—" : hopDong.ten_nguoi_thue) + "\n"
                + "SĐT: " + (hopDong.sdt_nguoi_thue == null ? "—" : hopDong.sdt_nguoi_thue) + "\n"
                + "Thời hạn: " + DinhDang.ngay(hopDong.bat_dau) + " → " + DinhDang.ngay(hopDong.ket_thuc) + "\n"
                + "Tiền cọc: " + DinhDang.tien(hopDong.tien_coc) + "\n"
                + "Số người: " + hopDong.so_nguoi + "\n"
                + "Trạng thái: " + TrangThai.hopDong(hopDong.trang_thai).nhan;
        new MaterialAlertDialogBuilder(requireContext())
                .setTitle("Hợp đồng #" + hopDong.id)
                .setMessage(noiDung)
                .setPositiveButton("Đóng", null)
                .show();
    }
}
