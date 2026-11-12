package com.nhom555.rentaladmin.util;

import com.nhom555.rentaladmin.R;

/** Nhãn tiếng Việt và màu hiển thị cho các trạng thái của backend. */
public final class TrangThai {

    public static final class HienThi {
        public final String nhan;
        public final int mauChu;
        public final int mauNen;

        public HienThi(String nhan, int mauChu, int mauNen) {
            this.nhan = nhan;
            this.mauChu = mauChu;
            this.mauNen = mauNen;
        }
    }

    private TrangThai() {
    }

    public static HienThi phong(String ma) {
        if (ma == null) {
            return new HienThi("Không rõ", R.color.text_secondary, R.color.bg);
        }
        switch (ma) {
            case "TRONG":
                return new HienThi("Trống", R.color.success, R.color.success_bg);
            case "DA_THUE":
                return new HienThi("Đã thuê", R.color.brand_700, R.color.info_bg);
            case "DANG_SUA":
                return new HienThi("Đang sửa", R.color.warning, R.color.warning_bg);
            default:
                return new HienThi(ma, R.color.text_secondary, R.color.bg);
        }
    }

    public static HienThi hopDong(String ma) {
        if (ma == null) {
            return new HienThi("Không rõ", R.color.text_secondary, R.color.bg);
        }
        switch (ma) {
            case "HIEU_LUC":
                return new HienThi("Hiệu lực", R.color.success, R.color.success_bg);
            case "HET_HAN":
                return new HienThi("Hết hạn", R.color.warning, R.color.warning_bg);
            case "DA_HUY":
                return new HienThi("Đã hủy", R.color.danger, R.color.danger_bg);
            default:
                return new HienThi(ma, R.color.text_secondary, R.color.bg);
        }
    }

    public static HienThi hoaDon(String ma) {
        if (ma == null) {
            return new HienThi("Không rõ", R.color.text_secondary, R.color.bg);
        }
        switch (ma) {
            case "CHUA_THU":
                return new HienThi("Chưa thu", R.color.warning, R.color.warning_bg);
            case "MOT_PHAN":
                return new HienThi("Thu một phần", R.color.brand_700, R.color.info_bg);
            case "DA_THU":
                return new HienThi("Đã thu", R.color.success, R.color.success_bg);
            case "QUA_HAN":
                return new HienThi("Quá hạn", R.color.danger, R.color.danger_bg);
            default:
                return new HienThi(ma, R.color.text_secondary, R.color.bg);
        }
    }

    public static HienThi suCo(String ma) {
        if (ma == null) {
            return new HienThi("Không rõ", R.color.text_secondary, R.color.bg);
        }
        switch (ma) {
            case "MOI":
                return new HienThi("Mới", R.color.danger, R.color.danger_bg);
            case "DANG_XU_LY":
                return new HienThi("Đang xử lý", R.color.warning, R.color.warning_bg);
            case "DA_XU_LY":
                return new HienThi("Đã xử lý", R.color.success, R.color.success_bg);
            default:
                return new HienThi(ma, R.color.text_secondary, R.color.bg);
        }
    }

    public static HienThi lichXem(String ma) {
        if (ma == null) {
            return new HienThi("Không rõ", R.color.text_secondary, R.color.bg);
        }
        switch (ma) {
            case "CHO_XAC_NHAN":
                return new HienThi("Chờ xác nhận", R.color.warning, R.color.warning_bg);
            case "DA_XAC_NHAN":
                return new HienThi("Đã xác nhận", R.color.success, R.color.success_bg);
            case "TU_CHOI":
                return new HienThi("Từ chối", R.color.danger, R.color.danger_bg);
            default:
                return new HienThi(ma, R.color.text_secondary, R.color.bg);
        }
    }

    public static HienThi hinhThuc(String ma) {
        if ("TIEN_MAT".equals(ma)) {
            return new HienThi("Tiền mặt", R.color.brand_700, R.color.info_bg);
        }
        return new HienThi("Chuyển khoản", R.color.brand_700, R.color.brand_50);
    }

    public static String[] dsTrangThaiPhong() {
        return new String[]{"Tất cả", "Trống", "Đã thuê", "Đang sửa"};
    }

    public static String maTrangThaiPhong(String nhan) {
        if ("Trống".equals(nhan)) {
            return "TRONG";
        }
        if ("Đã thuê".equals(nhan)) {
            return "DA_THUE";
        }
        if ("Đang sửa".equals(nhan)) {
            return "DANG_SUA";
        }
        return null;
    }

    public static String[] dsTrangThaiHoaDon() {
        return new String[]{"Tất cả", "Chưa thu", "Thu một phần", "Đã thu", "Quá hạn"};
    }

    public static String maTrangThaiHoaDon(String nhan) {
        if ("Chưa thu".equals(nhan)) {
            return "CHUA_THU";
        }
        if ("Thu một phần".equals(nhan)) {
            return "MOT_PHAN";
        }
        if ("Đã thu".equals(nhan)) {
            return "DA_THU";
        }
        if ("Quá hạn".equals(nhan)) {
            return "QUA_HAN";
        }
        return null;
    }

    public static String[] dsTrangThaiSuCo() {
        return new String[]{"Tất cả", "Mới", "Đang xử lý", "Đã xử lý"};
    }

    public static String maTrangThaiSuCo(String nhan) {
        if ("Mới".equals(nhan)) {
            return "MOI";
        }
        if ("Đang xử lý".equals(nhan)) {
            return "DANG_XU_LY";
        }
        if ("Đã xử lý".equals(nhan)) {
            return "DA_XU_LY";
        }
        return null;
    }

    public static String[] dsTrangThaiLich() {
        return new String[]{"Tất cả", "Chờ xác nhận", "Đã xác nhận", "Từ chối"};
    }

    public static String maTrangThaiLich(String nhan) {
        if ("Chờ xác nhận".equals(nhan)) {
            return "CHO_XAC_NHAN";
        }
        if ("Đã xác nhận".equals(nhan)) {
            return "DA_XAC_NHAN";
        }
        if ("Từ chối".equals(nhan)) {
            return "TU_CHOI";
        }
        return null;
    }
}
