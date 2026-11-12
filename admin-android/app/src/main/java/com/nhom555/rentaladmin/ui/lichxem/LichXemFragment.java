package com.nhom555.rentaladmin.ui.lichxem;

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
import com.nhom555.rentaladmin.data.model.KhuTro;
import com.nhom555.rentaladmin.data.model.LichXemPhong;
import com.nhom555.rentaladmin.data.model.YeuCauTrangThai;
import com.nhom555.rentaladmin.ui.common.TrangThaiManHinh;
import com.nhom555.rentaladmin.util.GiaoDien;
import com.nhom555.rentaladmin.util.TrangThai;

import java.util.ArrayList;
import java.util.List;

/** Danh sách lịch xem phòng, xác nhận hoặc từ chối lịch hẹn. */
public class LichXemFragment extends Fragment implements LichXemAdapter.ThaoTac {

    public static final String TAG = "555Rental-LichXem";

    private TrangThaiManHinh trangThai;
    private SwipeRefreshLayout keoXuong;
    private Spinner spKhu;
    private Spinner spTrangThai;
    private LichXemAdapter adapter;
    private final List<KhuTro> dsKhu = new ArrayList<>();
    private boolean dangKhoiTao = true;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_lich_xem, container, false);
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
        adapter = new LichXemAdapter(this);
        ds.setAdapter(adapter);

        spTrangThai.setAdapter(mau(TrangThai.dsTrangThaiLich()));
        AdapterView.OnItemSelectedListener chonLoc = new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View v, int position, long id) {
                if (!dangKhoiTao) {
                    taiLich();
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        };
        spKhu.setOnItemSelectedListener(chonLoc);
        spTrangThai.setOnItemSelectedListener(chonLoc);
        keoXuong.setOnRefreshListener(this::taiLich);
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
                        taiLich();
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        trangThai.loi(thongDiep, LichXemFragment.this::taiKhu);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        trangThai.loi(thongDiep, LichXemFragment.this::taiKhu);
                    }
                });
    }

    private void taiLich() {
        if (!keoXuong.isRefreshing()) {
            trangThai.dangTai();
        }
        Integer khuId = spKhu.getSelectedItemPosition() > 0
                ? dsKhu.get(spKhu.getSelectedItemPosition() - 1).id : null;
        String ma = TrangThai.maTrangThaiLich(String.valueOf(spTrangThai.getSelectedItem()));
        ApiClient.get(requireContext()).dsLichXem(khuId, ma)
                .enqueue(new ApiCallback<List<LichXemPhong>>(this) {
                    @Override
                    public void khiThanhCong(List<LichXemPhong> duLieu) {
                        keoXuong.setRefreshing(false);
                        trangThai.xong();
                        adapter.capNhat(duLieu);
                        if (duLieu == null || duLieu.isEmpty()) {
                            trangThai.rong("Không có lịch xem phù hợp bộ lọc.");
                        }
                    }

                    @Override
                    public void khiLoi(String thongDiep, int maHttp) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, LichXemFragment.this::taiLich);
                    }

                    @Override
                    public void khiMatKetNoi(String thongDiep) {
                        keoXuong.setRefreshing(false);
                        trangThai.loi(thongDiep, LichXemFragment.this::taiLich);
                    }
                });
    }

    @Override
    public void capNhat(LichXemPhong lich, String trangThaiMoi, String cauHoi, String nhanNut) {
        GiaoDien.xacNhan(this, "Cập nhật lịch xem", cauHoi, nhanNut,
                () -> ApiClient.get(requireContext())
                        .capNhatLichXem(lich.id, new YeuCauTrangThai(trangThaiMoi))
                        .enqueue(new ApiCallback<LichXemPhong>(this) {
                            @Override
                            public void khiThanhCong(LichXemPhong duLieu) {
                                GiaoDien.snackThanhCong(requireView(), "Đã cập nhật lịch xem");
                                taiLich();
                            }
                        }));
    }
}
