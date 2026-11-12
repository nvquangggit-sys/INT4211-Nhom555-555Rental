package com.nhom555.rentaladmin.ui.khutro;

import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;

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
import com.nhom555.rentaladmin.data.model.BieuGia;
import com.nhom555.rentaladmin.data.model.KhuTro;
import com.nhom555.rentaladmin.data.model.YeuCauBieuGia;
import com.nhom555.rentaladmin.data.model.YeuCauKhuTro;
import com.nhom555.rentaladmin.ui.common.TrangThaiManHinh;
import com.nhom555.rentaladmin.util.GiaoDien;

import java.util.List;

/** Danh sách khu trọ: thêm, sửa, xóa và cập nhật biểu giá (chỉ CHU_TRO). */
public class KhuTroFragment extends Fragment implements KhuTroAdapter.ThaoTac {

    public static final String TAG = "555Rental-KhuTro";

    private TrangThaiManHinh trangThai;
    private SwipeRefreshLayout keoXuong;
    private KhuTroAdapter adapter;
    private boolean laChuTro;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_khu_tro, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        laChuTro = TokenStore.laChuTro(requireContext());
        trangThai = new TrangThaiManHinh(view.findViewById(R.id.trang_thai));
        keoXuong = view.findViewById(R.id.keo_xuong);
        RecyclerView ds = view.findViewById(R.id.danh_sach);
        ds.setLayoutManager(new LinearLayoutManager(requireContext()));
        adapter = new KhuTroAdapter(laChuTro, this);
        ds.setAdapter(adapter);

        FloatingActionButton fab = view.findViewById(R.id.fab_them);
        fab.setVisibility(laChuTro ? View.VISIBLE : View.GONE);
        fab.setOnClickListener(v -> moHopThoai(null));

        keoXuong.setOnRefreshListener(this::taiDuLieu);
        taiDuLieu();
    }

    private void taiDuLieu() {
        if (!keoXuong.isRefreshing()) {
            trangThai.dangTai();
        }
        ApiClient.get(requireContext()).dsKhuTro()
                .enqueue(new ApiCallback<List<KhuTro>>(this) {
                    @Override
                    public void khiThanhCong(List<KhuTro> duLieu) {
                        keoXuong.setRefreshing(false);
                        trangThai.xong();
                        adapter.capNhat(duLieu);
                        if (duLieu == null || duLieu.isEmpty()) {
                            trangThai.rong(laChuTro
                                    ? "Chưa có khu trọ. Nhấn nút + để tạo khu đầu tiên."
                                    : "Chưa có khu trọ nào.");
                        }
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, KhuTroFragment.this::taiDuLieu);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, KhuTroFragment.this::taiDuLieu);
                    }
                });
    }

    private void moHopThoai(@Nullable KhuTro khu) {
        View v = LayoutInflater.from(requireContext()).inflate(R.layout.dialog_khu_tro, null);
        TextInputLayout oTen = v.findViewById(R.id.o_ten);
        TextInputLayout oDiaChi = v.findViewById(R.id.o_dia_chi);
        TextInputLayout oPhuongXa = v.findViewById(R.id.o_phuong_xa);
        TextInputLayout oGiaDien = v.findViewById(R.id.o_gia_dien);
        TextInputLayout oGiaNuoc = v.findViewById(R.id.o_gia_nuoc);
        TextInputLayout oPhiRac = v.findViewById(R.id.o_phi_rac);
        TextInputLayout oPhiGuiXe = v.findViewById(R.id.o_phi_gui_xe);
        EditText edTen = v.findViewById(R.id.ed_ten);
        EditText edDiaChi = v.findViewById(R.id.ed_dia_chi);
        EditText edPhuongXa = v.findViewById(R.id.ed_phuong_xa);
        EditText edTienIch = v.findViewById(R.id.ed_tien_ich);
        EditText edGiaDien = v.findViewById(R.id.ed_gia_dien);
        EditText edGiaNuoc = v.findViewById(R.id.ed_gia_nuoc);
        EditText edPhiRac = v.findViewById(R.id.ed_phi_rac);
        EditText edPhiGuiXe = v.findViewById(R.id.ed_phi_gui_xe);

        boolean taoMoi = khu == null;
        v.findViewById(R.id.nhan_bieu_gia).setVisibility(taoMoi ? View.VISIBLE : View.GONE);
        v.findViewById(R.id.khoi_bieu_gia).setVisibility(taoMoi ? View.VISIBLE : View.GONE);

        if (!taoMoi) {
            edTen.setText(khu.ten);
            edDiaChi.setText(khu.dia_chi);
            edPhuongXa.setText(khu.phuong_xa);
            edTienIch.setText(khu.tien_ich);
        } else {
            edGiaDien.setText("3800");
            edGiaNuoc.setText("18000");
            edPhiRac.setText("30000");
            edPhiGuiXe.setText("100000");
        }

        androidx.appcompat.app.AlertDialog dialog = new MaterialAlertDialogBuilder(requireContext())
                .setTitle(taoMoi ? "Thêm khu trọ" : "Sửa khu trọ")
                .setView(v)
                .setNegativeButton("Hủy", null)
                .setPositiveButton("Lưu", null)
                .create();

        dialog.setOnShowListener(d -> dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                .setOnClickListener(x -> {
                    oTen.setError(null);
                    oDiaChi.setError(null);
                    oPhuongXa.setError(null);

                    String ten = chuoi(edTen);
                    String diaChi = chuoi(edDiaChi);
                    String phuongXa = chuoi(edPhuongXa);
                    boolean hopLe = true;
                    if (ten.isEmpty()) {
                        oTen.setError("Nhập tên khu trọ");
                        hopLe = false;
                    }
                    if (diaChi.isEmpty()) {
                        oDiaChi.setError("Nhập địa chỉ");
                        hopLe = false;
                    }
                    if (phuongXa.isEmpty()) {
                        oPhuongXa.setError("Nhập phường/xã");
                        hopLe = false;
                    }
                    if (!hopLe) {
                        return;
                    }

                    YeuCauKhuTro body = new YeuCauKhuTro();
                    body.ten = ten;
                    body.dia_chi = diaChi;
                    body.phuong_xa = phuongXa;
                    body.tien_ich = chuoi(edTienIch);

                    Integer giaDien = null;
                    Integer giaNuoc = null;
                    Integer phiRac = null;
                    Integer phiGuiXe = null;
                    if (taoMoi) {
                        giaDien = so(edGiaDien);
                        giaNuoc = so(edGiaNuoc);
                        phiRac = so(edPhiRac);
                        phiGuiXe = so(edPhiGuiXe);
                        if (giaDien == null || giaDien < 0) {
                            oGiaDien.setError("Giá điện không hợp lệ");
                            hopLe = false;
                        }
                        if (giaNuoc == null || giaNuoc < 0) {
                            oGiaNuoc.setError("Giá nước không hợp lệ");
                            hopLe = false;
                        }
                        if (phiRac == null || phiRac < 0) {
                            oPhiRac.setError("Phí rác không hợp lệ");
                            hopLe = false;
                        }
                        if (phiGuiXe == null || phiGuiXe < 0) {
                            oPhiGuiXe.setError("Phí gửi xe không hợp lệ");
                            hopLe = false;
                        }
                        if (!hopLe) {
                            return;
                        }
                        body.bieu_gia = new YeuCauBieuGia(giaDien, giaNuoc, phiRac, phiGuiXe);
                    }

                    dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                            .setEnabled(false);
                    if (taoMoi) {
                        ApiClient.get(requireContext()).taoKhuTro(body)
                                .enqueue(new ApiCallback<KhuTro>(this) {
                                    @Override
                                    public void khiThanhCong(KhuTro duLieu) {
                                        dialog.dismiss();
                                        GiaoDien.snackThanhCong(requireView(), "Đã tạo khu trọ");
                                        taiDuLieu();
                                    }

                                    @Override
                                    public void khiLoi(String thongDiep, int maHttp) {
                                        dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                                                .setEnabled(true);
                                        oTen.setError(thongDiep);
                                    }
                                });
                    } else {
                        ApiClient.get(requireContext()).suaKhuTro(khu.id, body)
                                .enqueue(new ApiCallback<KhuTro>(this) {
                                    @Override
                                    public void khiThanhCong(KhuTro duLieu) {
                                        dialog.dismiss();
                                        GiaoDien.snackThanhCong(requireView(), "Đã cập nhật khu trọ");
                                        taiDuLieu();
                                    }

                                    @Override
                                    public void khiLoi(String thongDiep, int maHttp) {
                                        dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                                                .setEnabled(true);
                                        oTen.setError(thongDiep);
                                    }
                                });
                    }
                }));
        dialog.show();
    }

    private static String chuoi(EditText ed) {
        return ed.getText() == null ? "" : ed.getText().toString().trim();
    }

    private static Integer so(EditText ed) {
        try {
            return Integer.parseInt(chuoi(ed));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    @Override
    public void sua(KhuTro khu) {
        moHopThoai(khu);
    }

    @Override
    public void xoa(KhuTro khu) {
        GiaoDien.xacNhan(this, "Xóa khu trọ",
                "Bạn có chắc muốn xóa \"" + khu.ten + "\"? Chỉ xóa được khu chưa có phòng.",
                "Xóa", () -> ApiClient.get(requireContext()).xoaKhuTro(khu.id)
                        .enqueue(new ApiCallback<com.nhom555.rentaladmin.data.model.KetQuaXoa>(this) {
                            @Override
                            public void khiThanhCong(com.nhom555.rentaladmin.data.model.KetQuaXoa duLieu) {
                                GiaoDien.snackThanhCong(requireView(), "Đã xóa khu trọ");
                                taiDuLieu();
                            }
                        }));
    }

    @Override
    public void bieuGia(KhuTro khu) {
        if (!laChuTro) {
            return;
        }
        View v = LayoutInflater.from(requireContext()).inflate(R.layout.dialog_khu_tro, null);
        v.findViewById(R.id.o_ten).setVisibility(View.GONE);
        v.findViewById(R.id.o_dia_chi).setVisibility(View.GONE);
        v.findViewById(R.id.o_phuong_xa).setVisibility(View.GONE);
        v.findViewById(R.id.ed_tien_ich).setVisibility(View.GONE);
        v.findViewById(R.id.nhan_bieu_gia).setVisibility(View.VISIBLE);
        v.findViewById(R.id.khoi_bieu_gia).setVisibility(View.VISIBLE);

        TextInputLayout oGiaDien = v.findViewById(R.id.o_gia_dien);
        TextInputLayout oGiaNuoc = v.findViewById(R.id.o_gia_nuoc);
        TextInputLayout oPhiRac = v.findViewById(R.id.o_phi_rac);
        TextInputLayout oPhiGuiXe = v.findViewById(R.id.o_phi_gui_xe);
        EditText edGiaDien = v.findViewById(R.id.ed_gia_dien);
        EditText edGiaNuoc = v.findViewById(R.id.ed_gia_nuoc);
        EditText edPhiRac = v.findViewById(R.id.ed_phi_rac);
        EditText edPhiGuiXe = v.findViewById(R.id.ed_phi_gui_xe);
        edGiaDien.setText(String.valueOf(khu.gia_dien == null ? 0 : khu.gia_dien));
        edGiaNuoc.setText(String.valueOf(khu.gia_nuoc == null ? 0 : khu.gia_nuoc));
        edPhiRac.setText(String.valueOf(khu.phi_rac == null ? 0 : khu.phi_rac));
        edPhiGuiXe.setText(String.valueOf(khu.phi_gui_xe == null ? 0 : khu.phi_gui_xe));

        androidx.appcompat.app.AlertDialog dialog = new MaterialAlertDialogBuilder(requireContext())
                .setTitle("Biểu giá · " + khu.ten)
                .setView(v)
                .setNegativeButton("Hủy", null)
                .setPositiveButton("Lưu", null)
                .create();
        dialog.setOnShowListener(d -> dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                .setOnClickListener(x -> {
                    Integer giaDien = so(edGiaDien);
                    Integer giaNuoc = so(edGiaNuoc);
                    Integer phiRac = so(edPhiRac);
                    Integer phiGuiXe = so(edPhiGuiXe);
                    boolean hopLe = true;
                    if (giaDien == null || giaDien < 0) {
                        oGiaDien.setError("Không hợp lệ");
                        hopLe = false;
                    }
                    if (giaNuoc == null || giaNuoc < 0) {
                        oGiaNuoc.setError("Không hợp lệ");
                        hopLe = false;
                    }
                    if (phiRac == null || phiRac < 0) {
                        oPhiRac.setError("Không hợp lệ");
                        hopLe = false;
                    }
                    if (phiGuiXe == null || phiGuiXe < 0) {
                        oPhiGuiXe.setError("Không hợp lệ");
                        hopLe = false;
                    }
                    if (!hopLe) {
                        return;
                    }
                    dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE).setEnabled(false);
                    ApiClient.get(requireContext()).suaBieuGia(khu.id,
                                    new YeuCauBieuGia(giaDien, giaNuoc, phiRac, phiGuiXe))
                            .enqueue(new ApiCallback<BieuGia>(this) {
                                @Override
                                public void khiThanhCong(BieuGia duLieu) {
                                    dialog.dismiss();
                                    GiaoDien.snackThanhCong(requireView(), "Đã cập nhật biểu giá");
                                    taiDuLieu();
                                }

                                @Override
                                public void khiLoi(String thongDiep, int maHttp) {
                                    dialog.getButton(androidx.appcompat.app.AlertDialog.BUTTON_POSITIVE)
                                            .setEnabled(true);
                                    oGiaDien.setError(thongDiep);
                                }
                            });
                }));
        dialog.show();
    }
}
