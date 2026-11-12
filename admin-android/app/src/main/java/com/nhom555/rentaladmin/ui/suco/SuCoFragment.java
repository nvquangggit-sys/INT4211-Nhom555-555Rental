package com.nhom555.rentaladmin.ui.suco;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.Spinner;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.ApiCallback;
import com.nhom555.rentaladmin.data.ApiClient;
import com.nhom555.rentaladmin.data.model.KhuTro;
import com.nhom555.rentaladmin.data.model.SuCo;
import com.nhom555.rentaladmin.data.model.YeuCauTrangThai;
import com.nhom555.rentaladmin.ui.common.TrangThaiManHinh;
import com.nhom555.rentaladmin.util.Anh;
import com.nhom555.rentaladmin.util.DinhDang;
import com.nhom555.rentaladmin.util.GiaoDien;
import com.nhom555.rentaladmin.util.TrangThai;

import java.util.ArrayList;
import java.util.List;

/** Danh sách sự cố và cập nhật trạng thái xử lý. */
public class SuCoFragment extends Fragment implements SuCoAdapter.ThaoTac {

    public static final String TAG = "555Rental-SuCo";

    private TrangThaiManHinh trangThai;
    private SwipeRefreshLayout keoXuong;
    private Spinner spKhu;
    private Spinner spTrangThai;
    private SuCoAdapter adapter;
    private final List<KhuTro> dsKhu = new ArrayList<>();
    private boolean dangKhoiTao = true;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_su_co, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        trangThai = new TrangThaiManHinh(view.findViewById(R.id.trang_thai));
        keoXuong = view.findViewById(R.id.keo_xuong);
        spKhu = view.findViewById(R.id.sp_khu);
        spTrangThai = view.findViewById(R.id.sp_trang_thai);

        RecyclerView ds = view.findViewById(R.id.danh_sach);
        ds.setLayoutManager(new LinearLayoutManager(requireContext()));
        adapter = new SuCoAdapter(this);
        ds.setAdapter(adapter);

        spTrangThai.setAdapter(mau(TrangThai.dsTrangThaiSuCo()));
        AdapterView.OnItemSelectedListener chonLoc = new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View v, int position, long id) {
                if (!dangKhoiTao) {
                    taiSuCo();
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        };
        spKhu.setOnItemSelectedListener(chonLoc);
        spTrangThai.setOnItemSelectedListener(chonLoc);
        keoXuong.setOnRefreshListener(this::taiSuCo);
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
                        taiSuCo();
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        trangThai.loi(thongDiep, SuCoFragment.this::taiKhu);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        trangThai.loi(thongDiep, SuCoFragment.this::taiKhu);
                    }
                });
    }

    private void taiSuCo() {
        if (!keoXuong.isRefreshing()) {
            trangThai.dangTai();
        }
        Integer khuId = spKhu.getSelectedItemPosition() > 0
                ? dsKhu.get(spKhu.getSelectedItemPosition() - 1).id : null;
        String ma = TrangThai.maTrangThaiSuCo(String.valueOf(spTrangThai.getSelectedItem()));
        ApiClient.get(requireContext()).dsSuCo(khuId, ma)
                .enqueue(new ApiCallback<List<SuCo>>(this) {
                    @Override
                    public void khiThanhCong(List<SuCo> duLieu) {
                        keoXuong.setRefreshing(false);
                        trangThai.xong();
                        adapter.capNhat(duLieu);
                        if (duLieu == null || duLieu.isEmpty()) {
                            trangThai.rong("Không có sự cố phù hợp bộ lọc.");
                        }
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, SuCoFragment.this::taiSuCo);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, SuCoFragment.this::taiSuCo);
                    }
                });
    }

    @Override
    public void xemChiTiet(SuCo suCo) {
        View view = LayoutInflater.from(requireContext())
                .inflate(R.layout.dialog_su_co, null, false);

        TextView txtLoai = view.findViewById(R.id.txt_loai);
        TextView txtPhong = view.findViewById(R.id.txt_phong);
        TextView txtTrangThai = view.findViewById(R.id.txt_trang_thai);
        TextView txtMoTa = view.findViewById(R.id.txt_mo_ta);
        TextView txtNguoiBao = view.findViewById(R.id.txt_nguoi_bao);
        TextView txtXuLyLuc = view.findViewById(R.id.txt_xu_ly_luc);
        ImageView imgAnh = view.findViewById(R.id.img_anh);
        TextView txtXemAnh = view.findViewById(R.id.txt_xem_anh);

        txtLoai.setText(suCo.loai == null ? "Sự cố" : suCo.loai);
        txtPhong.setText("Phòng " + suCo.so_phong
                + (suCo.ten_khu == null ? "" : " · " + suCo.ten_khu));
        GiaoDien.ganBadge(txtTrangThai, TrangThai.suCo(suCo.trang_thai));
        txtMoTa.setText(suCo.mo_ta == null ? "Không có mô tả." : suCo.mo_ta);
        txtNguoiBao.setText("Người báo: "
                + (suCo.ten_nguoi_bao == null ? "—" : suCo.ten_nguoi_bao)
                + (suCo.sdt_nguoi_bao == null ? "" : " · " + suCo.sdt_nguoi_bao));

        if (suCo.xu_ly_luc != null) {
            txtXuLyLuc.setVisibility(View.VISIBLE);
            txtXuLyLuc.setText("Xử lý lúc " + DinhDang.ngayGio(suCo.xu_ly_luc));
        }

        if (suCo.anh_url != null && !suCo.anh_url.isEmpty()) {
            imgAnh.setVisibility(View.VISIBLE);
            txtXemAnh.setVisibility(View.VISIBLE);
            Anh.tai(imgAnh, suCo.anh_url);
            View.OnClickListener moAnh = v ->
                    Anh.xem(requireContext(), suCo.anh_url, "Ảnh sự cố");
            imgAnh.setOnClickListener(moAnh);
            txtXemAnh.setOnClickListener(moAnh);
        }

        new MaterialAlertDialogBuilder(requireContext())
                .setTitle("Chi tiết sự cố")
                .setView(view)
                .setPositiveButton("Đóng", null)
                .show();
    }

    @Override
    public void doiTrangThai(SuCo suCo, String trangThaiMoi, String cauHoi) {
        GiaoDien.xacNhan(this, "Cập nhật sự cố", cauHoi, "Đồng ý",
                () -> ApiClient.get(requireContext())
                        .capNhatSuCo(suCo.id, new YeuCauTrangThai(trangThaiMoi))
                        .enqueue(new ApiCallback<SuCo>(this) {
                            @Override
                            public void khiThanhCong(SuCo duLieu) {
                                GiaoDien.snackThanhCong(requireView(), "Đã cập nhật sự cố");
                                taiSuCo();
                            }
                        }));
    }
}
