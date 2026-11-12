package com.nhom555.rentaladmin.ui.login;

import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Patterns;
import android.view.View;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.google.android.material.textfield.TextInputLayout;
import com.nhom555.rentaladmin.R;
import com.nhom555.rentaladmin.data.ApiCallback;
import com.nhom555.rentaladmin.data.ApiClient;
import com.nhom555.rentaladmin.data.TokenStore;
import com.nhom555.rentaladmin.data.model.KetQuaDangNhap;
import com.nhom555.rentaladmin.data.model.YeuCauDangNhap;
import com.nhom555.rentaladmin.ui.main.MainActivity;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/**
 * Màn hình đăng nhập.
 * - Kiểm tra định dạng email, mật khẩu tối thiểu 6 ký tự ngay trên app.
 * - Lưu JWT vào SharedPreferences, không lưu mật khẩu.
 * - Cho phép đổi địa chỉ API (hữu ích khi chạy backend local hoặc Render ngủ).
 */
public class LoginActivity extends AppCompatActivity {

    public static final String TAG = "555Rental-Login";

    private TextInputLayout oEmail;
    private TextInputLayout oMatKhau;
    private EditText edEmail;
    private EditText edMatKhau;
    private View btnDangNhap;
    private ProgressBar progress;
    private TextView txtLoi;
    private TextView txtApi;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (TokenStore.daDangNhap(this)) {
            moTrangChinh();
            return;
        }

        setContentView(R.layout.activity_login);
        oEmail = findViewById(R.id.o_email);
        oMatKhau = findViewById(R.id.o_mat_khau);
        edEmail = findViewById(R.id.ed_email);
        edMatKhau = findViewById(R.id.ed_mat_khau);
        btnDangNhap = findViewById(R.id.btn_dang_nhap);
        progress = findViewById(R.id.progress);
        txtLoi = findViewById(R.id.txt_loi);
        txtApi = findViewById(R.id.txt_api);

        if (savedInstanceState != null) {
            edEmail.setText(savedInstanceState.getString("email", ""));
        }

        btnDangNhap.setOnClickListener(v -> dangNhap());
        findViewById(R.id.txt_demo_chu_tro).setOnClickListener(v -> dienTaiKhoan("chutro@555rental.vn"));
        findViewById(R.id.txt_demo_quan_ly).setOnClickListener(v -> dienTaiKhoan("quanly@555rental.vn"));
        findViewById(R.id.btn_cai_dat_api).setOnClickListener(v -> moCaiDatApi());

        capNhatDiaChiApi();
    }

    private void capNhatDiaChiApi() {
        txtApi.setText("API: " + TokenStore.layBaseUrl(this));
    }

    private void dienTaiKhoan(String email) {
        edEmail.setText(email);
        edMatKhau.setText("123456");
        oEmail.setError(null);
        oMatKhau.setError(null);
    }

    private void dangNhap() {
        String email = edEmail.getText() == null ? "" : edEmail.getText().toString().trim();
        String matKhau = edMatKhau.getText() == null ? "" : edMatKhau.getText().toString();

        oEmail.setError(null);
        oMatKhau.setError(null);
        txtLoi.setVisibility(View.GONE);

        boolean hopLe = true;
        if (email.isEmpty()) {
            oEmail.setError("Vui lòng nhập email");
            hopLe = false;
        } else if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            oEmail.setError("Email không đúng định dạng");
            hopLe = false;
        }
        if (matKhau.isEmpty()) {
            oMatKhau.setError("Vui lòng nhập mật khẩu");
            hopLe = false;
        } else if (matKhau.length() < 6) {
            oMatKhau.setError("Mật khẩu phải có ít nhất 6 ký tự");
            hopLe = false;
        }
        if (!hopLe) {
            return;
        }

        batDauTai();
        ApiClient.get(this).dangNhap(new YeuCauDangNhap(email, matKhau))
                .enqueue(new Callback<KetQuaDangNhap>() {
                    @Override
                    public void onResponse(@NonNull Call<KetQuaDangNhap> call,
                                           @NonNull Response<KetQuaDangNhap> response) {
                        if (isFinishing() || isDestroyed()) {
                            return;
                        }
                        ketThucTai();
                        KetQuaDangNhap kq = response.body();
                        if (response.isSuccessful() && kq != null && kq.token != null
                                && kq.nguoiDung != null) {
                            String vaiTro = kq.nguoiDung.vai_tro;
                            if (!"CHU_TRO".equals(vaiTro) && !"QUAN_LY".equals(vaiTro)) {
                                hienLoi("Tài khoản này không có quyền quản trị.");
                                return;
                            }
                            TokenStore.luuPhien(LoginActivity.this, kq.token, kq.nguoiDung.id,
                                    kq.nguoiDung.ho_ten, kq.nguoiDung.email, vaiTro);
                            moTrangChinh();
                            return;
                        }
                        if (response.code() == 401) {
                            hienLoi("Email hoặc mật khẩu không đúng.");
                        } else {
                            hienLoi(ApiCallback.docThongDiepLoi(response));
                        }
                    }

                    @Override
                    public void onFailure(@NonNull Call<KetQuaDangNhap> call, @NonNull Throwable t) {
                        if (isFinishing() || isDestroyed()) {
                            return;
                        }
                        ketThucTai();
                        if (t instanceof java.net.SocketTimeoutException) {
                            hienLoi("Máy chủ đang khởi động (Render ngủ 15 phút). Vui lòng thử lại sau ít giây.");
                        } else if (t instanceof java.net.UnknownHostException) {
                            hienLoi("Không tìm thấy máy chủ. Kiểm tra địa chỉ API trong Cài đặt.");
                        } else {
                            hienLoi("Không kết nối được máy chủ. Kiểm tra Wi-Fi và thử lại.");
                        }
                    }
                });
    }

    private void moCaiDatApi() {
        EditText ed = new EditText(this);
        ed.setText(TokenStore.layBaseUrl(this));
        ed.setSingleLine(true);
        int pad = (int) (20 * getResources().getDisplayMetrics().density);
        ed.setPadding(pad, pad / 2, pad, pad / 2);

        new MaterialAlertDialogBuilder(this)
                .setTitle("Địa chỉ API")
                .setMessage("Nhập địa chỉ backend kết thúc bằng dấu /.\nVí dụ: https://rental-nhom555-api.onrender.com/")
                .setView(ed)
                .setNegativeButton("Hủy", null)
                .setPositiveButton("Lưu", (d, w) -> {
                    TokenStore.luuBaseUrl(this, ed.getText().toString());
                    ApiClient.datLai();
                    capNhatDiaChiApi();
                })
                .show();
    }

    private void batDauTai() {
        progress.setVisibility(View.VISIBLE);
        btnDangNhap.setEnabled(false);
        btnDangNhap.setAlpha(0.6f);
        txtLoi.setVisibility(View.GONE);
    }

    private void ketThucTai() {
        progress.setVisibility(View.GONE);
        btnDangNhap.setEnabled(true);
        btnDangNhap.setAlpha(1f);
    }

    private void hienLoi(String thongDiep) {
        txtLoi.setText(thongDiep);
        txtLoi.setVisibility(View.VISIBLE);
    }

    private void moTrangChinh() {
        Intent intent = new Intent(this, MainActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
        finish();
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        if (edEmail != null) {
            outState.putString("email", edEmail.getText() == null ? "" : edEmail.getText().toString());
        }
    }
}
