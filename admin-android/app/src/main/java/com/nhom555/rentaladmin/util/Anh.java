package com.nhom555.rentaladmin.util;

import android.content.Context;
import android.text.TextUtils;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;

import androidx.appcompat.app.AlertDialog;

import com.bumptech.glide.Glide;
import com.bumptech.glide.load.engine.DiskCacheStrategy;
import com.nhom555.rentaladmin.data.TokenStore;

/**
 * Hiển thị ảnh đính kèm (biên lai thanh toán, ảnh sự cố).
 *
 * Backend trả về URL tuyệt đối (Supabase Storage) hoặc URL tương đối
 * "/uploads/..." khi chạy nội bộ, nên cần ghép thêm BASE_URL.
 */
public final class Anh {

    private Anh() {
    }

    /** Chuyển URL tương đối thành URL đầy đủ để Glide tải được. */
    public static String duongDan(Context context, String url) {
        if (TextUtils.isEmpty(url)) {
            return null;
        }
        if (url.startsWith("http://") || url.startsWith("https://")) {
            return url;
        }
        String base = TokenStore.layBaseUrl(context);
        if (!base.endsWith("/")) {
            base = base + "/";
        }
        if (url.startsWith("/")) {
            url = url.substring(1);
        }
        return base + url;
    }

    public static void tai(ImageView imageView, String url) {
        String day = duongDan(imageView.getContext(), url);
        if (day == null) {
            return;
        }
        Glide.with(imageView)
                .load(day)
                .diskCacheStrategy(DiskCacheStrategy.ALL)
                .centerCrop()
                .into(imageView);
    }

    /** Mở dialog xem ảnh lớn, bấm ra ngoài để đóng. */
    public static void xem(Context context, String url, String tieuDe) {
        String day = duongDan(context, url);
        if (day == null) {
            GiaoDien.hopThoai(context, tieuDe)
                    .setMessage("Không có ảnh đính kèm.")
                    .setPositiveButton("Đóng", null)
                    .show();
            return;
        }

        int padding = GiaoDien.dp(context, 12);
        ImageView imageView = new ImageView(context);
        imageView.setAdjustViewBounds(true);
        imageView.setScaleType(ImageView.ScaleType.FIT_CENTER);
        imageView.setLayoutParams(new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        FrameLayout khung = new FrameLayout(context);
        khung.setPadding(padding, padding, padding, padding);
        khung.addView(imageView);

        AlertDialog dialog = GiaoDien.hopThoai(context, tieuDe)
                .setView(khung)
                .setPositiveButton("Đóng", null)
                .create();
        dialog.show();

        Glide.with(context)
                .load(day)
                .diskCacheStrategy(DiskCacheStrategy.ALL)
                .fitCenter()
                .into(imageView);
    }
}
