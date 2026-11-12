package com.nhom555.rentaladmin.data;

import android.app.Activity;
import android.content.Context;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;

import com.nhom555.rentaladmin.data.model.LoiPhanHoi;
import com.nhom555.rentaladmin.ui.common.PhienDangNhap;

import java.io.IOException;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/**
 * Callback Retrofit dùng chung:
 * - 2xx  -> khiThanhCong
 * - 401  -> xóa token, đưa về màn hình đăng nhập (tự đăng xuất khi token hết hạn)
 * - khác -> đọc {"loi": "..."} của backend rồi báo lỗi
 * - lỗi mạng -> thông báo thân thiện, không làm app văng.
 *
 * Mọi callback kiểm tra màn hình còn sống trước khi chạm vào View,
 * tránh NullPointerException khi người dùng đã rời màn hình.
 */
public abstract class ApiCallback<T> implements Callback<T> {

    private final Fragment fragment;
    private final Activity activity;
    private final Context context;

    protected ApiCallback(@NonNull Fragment fragment) {
        this.fragment = fragment;
        this.activity = fragment.getActivity();
        this.context = fragment.requireContext().getApplicationContext();
    }

    protected ApiCallback(@NonNull Activity activity) {
        this.fragment = null;
        this.activity = activity;
        this.context = activity.getApplicationContext();
    }

    /** Trả về true nếu màn hình vẫn còn để cập nhật giao diện. */
    public boolean conSong() {
        if (fragment != null) {
            return fragment.isAdded() && fragment.getContext() != null;
        }
        return activity != null && !activity.isFinishing() && !activity.isDestroyed();
    }

    protected Context layContext() {
        return context;
    }

    protected Activity layActivity() {
        return activity;
    }

    /** Gọi khi API trả về thành công (2xx). Có thể trả body null với 204. */
    public abstract void khiThanhCong(T duLieu);

    /** Gọi khi backend trả mã lỗi 4xx/5xx (trừ 401). Mặc định hiện Toast. */
    public void khiLoi(String thongDiep, int maHttp) {
        if (conSong()) {
            Toast.makeText(context, thongDiep, Toast.LENGTH_LONG).show();
        }
    }

    /** Gọi khi không kết nối được máy chủ. Mặc định hiện Toast. */
    public void khiMatKetNoi(String thongDiep) {
        if (conSong()) {
            Toast.makeText(context, thongDiep, Toast.LENGTH_LONG).show();
        }
    }

    /** Gọi trước khi request chạy, dùng để bật ProgressBar. */
    public void khiBatDau() {
    }

    /** Gọi sau khi request kết thúc (thành công hay lỗi), dùng để tắt ProgressBar. */
    public void khiKetThuc() {
    }

    @Override
    public void onResponse(@NonNull Call<T> call, @NonNull Response<T> response) {
        if (!conSong()) {
            return;
        }
        khiKetThuc();
        if (response.isSuccessful()) {
            khiThanhCong(response.body());
            return;
        }
        if (response.code() == 401) {
            PhienDangNhap.hetHan(activity, context);
            return;
        }
        khiLoi(docThongDiepLoi(response), response.code());
    }

    @Override
    public void onFailure(@NonNull Call<T> call, @NonNull Throwable t) {
        if (!conSong()) {
            return;
        }
        khiKetThuc();
        String thongDiep = "Không kết nối được máy chủ. Kiểm tra Wi-Fi và thử lại.";
        if (t instanceof java.net.SocketTimeoutException) {
            thongDiep = "Máy chủ đang khởi động (Render ngủ 15 phút). Vui lòng thử lại sau ít giây.";
        } else if (t instanceof java.net.UnknownHostException) {
            thongDiep = "Không tìm thấy máy chủ. Kiểm tra địa chỉ API trong phần Cài đặt.";
        }
        khiMatKetNoi(thongDiep);
    }

    /** Đọc trường "loi" trong JSON lỗi của backend, nếu không có thì trả thông báo mặc định. */
    public static String docThongDiepLoi(Response<?> response) {
        int ma = response.code();
        ResponseBody body = response.errorBody();
        if (body != null) {
            try {
                LoiPhanHoi loi = ApiClient.gson().fromJson(body.string(), LoiPhanHoi.class);
                if (loi != null && loi.loi != null && !loi.loi.trim().isEmpty()) {
                    return loi.loi;
                }
            } catch (IOException | RuntimeException ignored) {
                // rơi xuống thông báo mặc định
            }
        }
        switch (ma) {
            case 400:
                return "Dữ liệu không hợp lệ (400)";
            case 403:
                return "Tài khoản của bạn không có quyền thực hiện thao tác này (403)";
            case 404:
                return "Không tìm thấy dữ liệu (404)";
            case 409:
                return "Dữ liệu đã thay đổi hoặc bị trùng (409)";
            case 500:
                return "Máy chủ gặp lỗi (500). Vui lòng thử lại.";
            default:
                return "Lỗi máy chủ (" + ma + ")";
        }
    }
}
