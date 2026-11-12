package com.nhom555.rentaladmin.ui.main;

import android.os.Bundle;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.fragment.app.Fragment;

import com.google.android.material.appbar.MaterialToolbar;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.google.android.material.navigation.NavigationView;
import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.ApiClient;
import com.nhom555.rentaladmin.data.TokenStore;
import com.nhom555.rentaladmin.ui.baocao.BaoCaoFragment;
import com.nhom555.rentaladmin.ui.chiso.ChiSoFragment;
import com.nhom555.rentaladmin.ui.common.PhienDangNhap;
import com.nhom555.rentaladmin.ui.hoadon.HoaDonFragment;
import com.nhom555.rentaladmin.ui.hopdong.HopDongFragment;
import com.nhom555.rentaladmin.ui.khutro.KhuTroFragment;
import com.nhom555.rentaladmin.ui.lichxem.LichXemFragment;
import com.nhom555.rentaladmin.ui.phong.PhongFragment;
import com.nhom555.rentaladmin.ui.suco.SuCoFragment;
import com.nhom555.rentaladmin.ui.thanhtoan.ThanhToanFragment;
import com.nhom555.rentaladmin.ui.tongquan.TongQuanFragment;
import com.nhom555.rentaladmin.util.DinhDang;

/** Activity chính: thanh điều hướng bên trái + vùng chứa các màn hình chức năng. */
public class MainActivity extends AppCompatActivity {

    public static final String TAG = "555Rental-Main";

    private DrawerLayout drawer;
    private MaterialToolbar toolbar;
    private NavigationView dieuHuong;
    private int dangChon = R.id.nav_tong_quan;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (!TokenStore.daDangNhap(this)) {
            PhienDangNhap.dangXuat(this);
            return;
        }
        setContentView(R.layout.activity_main);

        drawer = findViewById(R.id.drawer);
        toolbar = findViewById(R.id.toolbar);
        dieuHuong = findViewById(R.id.dieu_huong);

        toolbar.setNavigationOnClickListener(v -> drawer.openDrawer(GravityCompat.START));
        dieuHuong.setNavigationItemSelectedListener(this::chonMuc);
        apDungPhanQuyen();
        ganThongTinNguoiDung();

        if (savedInstanceState == null) {
            chonManHinh(manHinhMacDinh());
        } else {
            dangChon = savedInstanceState.getInt("dang_chon", manHinhMacDinh());
            dieuHuong.setCheckedItem(dangChon);
            toolbar.setTitle(tieuDeCua(dangChon));
        }
    }

    /**
     * Ẩn các mục menu không thuộc quyền của QUAN_LY.
     * Đây chỉ là lớp bảo vệ giao diện; backend vẫn là nơi chặn quyền thật (403).
     */
    private void apDungPhanQuyen() {
        if (TokenStore.laChuTro(this)) {
            return;
        }
        int[] cacMucChiChuTro = {
                R.id.nav_khu_tro, R.id.nav_phong, R.id.nav_hop_dong,
                R.id.nav_hoa_don, R.id.nav_thanh_toan, R.id.nav_lich_xem,
                R.id.nav_bao_cao
        };
        android.view.Menu menu = dieuHuong.getMenu();
        for (int id : cacMucChiChuTro) {
            android.view.MenuItem item = menu.findItem(id);
            if (item != null) {
                item.setVisible(false);
            }
        }
    }

    /** QUAN_LY chỉ làm việc với ghi chỉ số và sự cố nên mở thẳng màn hình ghi chỉ số. */
    private int manHinhMacDinh() {
        return TokenStore.laChuTro(this) ? R.id.nav_tong_quan : R.id.nav_chi_so;
    }

    private void ganThongTinNguoiDung() {
        View header = dieuHuong.getHeaderView(0);
        TextView txtAvatar = header.findViewById(R.id.txt_avatar);
        TextView txtTen = header.findViewById(R.id.txt_ten);
        TextView txtVaiTro = header.findViewById(R.id.txt_vai_tro);
        TextView txtEmail = header.findViewById(R.id.txt_email);

        String ten = TokenStore.hoTen(this);
        txtTen.setText(ten);
        txtEmail.setText(TokenStore.email(this));
        txtAvatar.setText(DinhDang.tenNgan(ten));
        txtVaiTro.setText(TokenStore.laChuTro(this) ? "Chủ trọ · toàn quyền" : "Quản lý khu trọ");
    }

    private boolean chonMuc(android.view.MenuItem item) {
        int id = item.getItemId();
        if (id == R.id.nav_dang_xuat) {
            drawer.closeDrawer(GravityCompat.START);
            xacNhanDangXuat();
            return true;
        }
        if (id == R.id.nav_doi_api) {
            drawer.closeDrawer(GravityCompat.START);
            moDoiApi();
            return true;
        }
        chonManHinh(id);
        return true;
    }

    private void chonManHinh(int id) {
        if (!duocPhep(id)) {
            id = manHinhMacDinh();
        }
        Fragment fragment;
        if (id == R.id.nav_khu_tro) {
            fragment = new KhuTroFragment();
        } else if (id == R.id.nav_phong) {
            fragment = new PhongFragment();
        } else if (id == R.id.nav_hop_dong) {
            fragment = new HopDongFragment();
        } else if (id == R.id.nav_chi_so) {
            fragment = new ChiSoFragment();
        } else if (id == R.id.nav_hoa_don) {
            fragment = new HoaDonFragment();
        } else if (id == R.id.nav_thanh_toan) {
            fragment = new ThanhToanFragment();
        } else if (id == R.id.nav_su_co) {
            fragment = new SuCoFragment();
        } else if (id == R.id.nav_lich_xem) {
            fragment = new LichXemFragment();
        } else if (id == R.id.nav_bao_cao) {
            fragment = new BaoCaoFragment();
        } else {
            id = R.id.nav_tong_quan;
            fragment = new TongQuanFragment();
        }

        dangChon = id;
        toolbar.setTitle(tieuDeCua(id));
        getSupportFragmentManager().beginTransaction()
                .setReorderingAllowed(true)
                .replace(R.id.khung_noi_dung, fragment)
                .commit();
        dieuHuong.setCheckedItem(id);
        drawer.closeDrawer(GravityCompat.START);
    }

    /** Cho phép QUAN_LY điều hướng tới màn hình ghi chỉ số / sự cố / tổng quan. */
    private boolean duocPhep(int id) {
        if (TokenStore.laChuTro(this)) {
            return true;
        }
        return id == R.id.nav_tong_quan || id == R.id.nav_chi_so || id == R.id.nav_su_co;
    }

    /** Cho phép các fragment chuyển màn hình qua thanh điều hướng. */
    public void moManHinh(int id) {
        chonManHinh(id);
    }

    private String tieuDeCua(int id) {
        if (id == R.id.nav_khu_tro) {
            return "Khu trọ";
        }
        if (id == R.id.nav_phong) {
            return "Phòng cho thuê";
        }
        if (id == R.id.nav_hop_dong) {
            return "Hợp đồng thuê";
        }
        if (id == R.id.nav_chi_so) {
            return "Ghi chỉ số điện nước";
        }
        if (id == R.id.nav_hoa_don) {
            return "Hóa đơn";
        }
        if (id == R.id.nav_thanh_toan) {
            return "Thanh toán";
        }
        if (id == R.id.nav_su_co) {
            return "Sự cố";
        }
        if (id == R.id.nav_lich_xem) {
            return "Lịch xem phòng";
        }
        if (id == R.id.nav_bao_cao) {
            return "Báo cáo";
        }
        return "Tổng quan";
    }

    private void xacNhanDangXuat() {
        new MaterialAlertDialogBuilder(this)
                .setTitle("Đăng xuất")
                .setMessage("Bạn có chắc muốn đăng xuất khỏi 555Rental Admin?")
                .setNegativeButton("Ở lại", null)
                .setPositiveButton("Đăng xuất", (d, w) -> PhienDangNhap.dangXuat(this))
                .show();
    }

    private void moDoiApi() {
        EditText ed = new EditText(this);
        ed.setText(TokenStore.layBaseUrl(this));
        ed.setSingleLine(true);
        int pad = (int) (20 * getResources().getDisplayMetrics().density);
        ed.setPadding(pad, pad / 2, pad, pad / 2);

        new MaterialAlertDialogBuilder(this)
                .setTitle("Địa chỉ API")
                .setMessage("Đổi địa chỉ backend (phải kết thúc bằng dấu /).")
                .setView(ed)
                .setNegativeButton("Hủy", null)
                .setPositiveButton("Lưu", (d, w) -> {
                    TokenStore.luuBaseUrl(this, ed.getText().toString());
                    ApiClient.datLai();
                    Toast.makeText(this, "Đã lưu địa chỉ API", Toast.LENGTH_SHORT).show();
                    chonManHinh(dangChon);
                })
                .show();
    }

    @Override
    public void onBackPressed() {
        if (drawer.isDrawerOpen(GravityCompat.START)) {
            drawer.closeDrawer(GravityCompat.START);
            return;
        }
        if (dangChon != manHinhMacDinh()) {
            chonManHinh(manHinhMacDinh());
            return;
        }
        super.onBackPressed();
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putInt("dang_chon", dangChon);
    }
}
