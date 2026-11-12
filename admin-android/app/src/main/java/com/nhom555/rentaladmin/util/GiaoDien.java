package com.nhom555.rentaladmin.util;

import android.content.Context;
import android.graphics.drawable.GradientDrawable;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.TextView;

import androidx.appcompat.app.AlertDialog;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;

import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.google.android.material.snackbar.Snackbar;
import com.nhom555.rentaladmin.R;

/** Các hàm giao diện dùng chung: badge trạng thái, dialog xác nhận, Snackbar. */
public final class GiaoDien {

    private GiaoDien() {
    }

    /** Gắn nhãn trạng thái dạng "viên thuốc" với màu chữ/nền tương ứng. */
    public static void ganBadge(TextView view, TrangThai.HienThi tt) {
        view.setText(tt.nhan);
        view.setTextColor(ContextCompat.getColor(view.getContext(), tt.mauChu));
        GradientDrawable nen = new GradientDrawable();
        nen.setColor(ContextCompat.getColor(view.getContext(), tt.mauNen));
        nen.setCornerRadius(dp(view.getContext(), 999));
        view.setBackground(nen);
    }

    public static int dp(Context context, float giaTri) {
        return Math.round(giaTri * context.getResources().getDisplayMetrics().density);
    }

    /** Dialog xác nhận trước thao tác xóa / thay đổi quan trọng. */
    public static void xacNhan(Fragment fragment, String tieuDe, String noiDung,
                               String nhanDongY, Runnable khiDongY) {
        new MaterialAlertDialogBuilder(fragment.requireContext())
                .setTitle(tieuDe)
                .setMessage(noiDung)
                .setNegativeButton("Hủy", null)
                .setPositiveButton(nhanDongY, (d, w) -> khiDongY.run())
                .show();
    }

    public static AlertDialog.Builder hopThoai(Context context, String tieuDe) {
        return new MaterialAlertDialogBuilder(context).setTitle(tieuDe);
    }

    public static void snack(View view, String thongDiep) {
        Snackbar.make(view, thongDiep, Snackbar.LENGTH_LONG).show();
    }

    public static void snackThanhCong(View view, String thongDiep) {
        Snackbar.make(view, thongDiep, Snackbar.LENGTH_LONG)
                .setBackgroundTint(ContextCompat.getColor(view.getContext(), R.color.success))
                .show();
    }

    public static void anBanPhim(View view) {
        InputMethodManager imm = (InputMethodManager) view.getContext()
                .getSystemService(Context.INPUT_METHOD_SERVICE);
        if (imm != null) {
            imm.hideSoftInputFromWindow(view.getWindowToken(), 0);
        }
    }
}
