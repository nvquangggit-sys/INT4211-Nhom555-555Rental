package com.nhom555.rentaladmin.data;

import android.content.Context;
import android.content.SharedPreferences;

/**
 * Lưu token JWT và thông tin phiên đăng nhập bằng SharedPreferences.
 * Không lưu mật khẩu. Token bị xóa ngay khi backend trả 401.
 */
public final class TokenStore {

    private static final String PREF = "phien_555rental";
    private static final String KHOA_TOKEN = "token";
    private static final String KHOA_VAI_TRO = "vai_tro";
    private static final String KHOA_HO_TEN = "ho_ten";
    private static final String KHOA_EMAIL = "email";
    private static final String KHOA_ID = "id";
    private static final String KHOA_BASE_URL = "base_url";

    /** Địa chỉ API production. Có thể đổi trong màn hình đăng nhập (nút Cài đặt). */
    public static final String BASE_URL_MAC_DINH = "https://rental-nhom555-api.onrender.com/";

    private TokenStore() {
    }

    private static SharedPreferences prefs(Context context) {
        return context.getApplicationContext().getSharedPreferences(PREF, Context.MODE_PRIVATE);
    }

    public static void luuPhien(Context context, String token, int id, String hoTen,
                                String email, String vaiTro) {
        prefs(context).edit()
                .putString(KHOA_TOKEN, token)
                .putInt(KHOA_ID, id)
                .putString(KHOA_HO_TEN, hoTen)
                .putString(KHOA_EMAIL, email)
                .putString(KHOA_VAI_TRO, vaiTro)
                .apply();
    }

    public static void dangXuat(Context context) {
        prefs(context).edit()
                .remove(KHOA_TOKEN)
                .remove(KHOA_ID)
                .remove(KHOA_HO_TEN)
                .remove(KHOA_EMAIL)
                .remove(KHOA_VAI_TRO)
                .apply();
    }

    public static boolean daDangNhap(Context context) {
        return !layToken(context).isEmpty();
    }

    public static String layToken(Context context) {
        return prefs(context).getString(KHOA_TOKEN, "");
    }

    public static String vaiTro(Context context) {
        return prefs(context).getString(KHOA_VAI_TRO, "");
    }

    public static String hoTen(Context context) {
        return prefs(context).getString(KHOA_HO_TEN, "Người dùng");
    }

    public static String email(Context context) {
        return prefs(context).getString(KHOA_EMAIL, "");
    }

    public static int id(Context context) {
        return prefs(context).getInt(KHOA_ID, 0);
    }

    public static boolean laChuTro(Context context) {
        return "CHU_TRO".equals(vaiTro(context));
    }

    public static String layBaseUrl(Context context) {
        return prefs(context).getString(KHOA_BASE_URL, BASE_URL_MAC_DINH);
    }

    /** Chuẩn hóa URL: bắt buộc kết thúc bằng dấu / để Retrofit không ném lỗi. */
    public static void luuBaseUrl(Context context, String url) {
        String s = url == null ? "" : url.trim();
        if (s.isEmpty()) {
            s = BASE_URL_MAC_DINH;
        }
        if (!s.startsWith("http://") && !s.startsWith("https://")) {
            s = "https://" + s;
        }
        if (!s.endsWith("/")) {
            s = s + "/";
        }
        prefs(context).edit().putString(KHOA_BASE_URL, s).apply();
    }
}
