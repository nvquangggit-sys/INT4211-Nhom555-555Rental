package com.nhom555.rentaladmin.ui.common;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.widget.Toast;

import com.nhom555.rentaladmin.data.TokenStore;
import com.nhom555.rentaladmin.ui.login.LoginActivity;

/**
 * Xử lý khi token hết hạn hoặc không hợp lệ (backend trả 401):
 * xóa phiên, đóng màn hình hiện tại và quay về đăng nhập.
 */
public final class PhienDangNhap {

    private PhienDangNhap() {
    }

    public static void hetHan(Activity activity, Context context) {
        TokenStore.dangXuat(context);
        Toast.makeText(context, "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.",
                Toast.LENGTH_LONG).show();
        Intent intent = new Intent(context, LoginActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        context.startActivity(intent);
        if (activity != null) {
            activity.finish();
        }
    }

    public static void dangXuat(Activity activity) {
        TokenStore.dangXuat(activity);
        Intent intent = new Intent(activity, LoginActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        activity.startActivity(intent);
        activity.finish();
    }
}
