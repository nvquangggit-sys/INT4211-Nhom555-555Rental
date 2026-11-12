package com.nhom555.rentaladmin.util;

import java.text.NumberFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;

/** Định dạng tiền, ngày, tháng theo kiểu Việt Nam. */
public final class DinhDang {

    private static final Locale VI = Locale.forLanguageTag("vi-VN");
    private static final NumberFormat TIEN = NumberFormat.getInstance(VI);
    private static final NumberFormat SO = NumberFormat.getInstance(VI);

    private DinhDang() {
    }

    /** 4080000 -> "4.080.000 đ" */
    public static String tien(long giaTri) {
        return TIEN.format(giaTri) + " đ";
    }

    /** 4080000 -> "4,08 tr" (dùng cho nhãn biểu đồ). */
    public static String tienNgan(long giaTri) {
        if (Math.abs(giaTri) >= 1_000_000_000L) {
            return String.format(VI, "%.2f tỷ", giaTri / 1_000_000_000.0);
        }
        if (Math.abs(giaTri) >= 1_000_000L) {
            return String.format(VI, "%.2f tr", giaTri / 1_000_000.0);
        }
        if (Math.abs(giaTri) >= 1_000L) {
            return String.format(VI, "%.0f ng", giaTri / 1_000.0);
        }
        return String.valueOf(giaTri);
    }

    public static String so(double giaTri) {
        if (giaTri == Math.rint(giaTri)) {
            return String.valueOf((long) giaTri);
        }
        return SO.format(giaTri);
    }

    /** "2026-11-01" hoặc ISO 8601 -> "01/11/2026". */
    public static String ngay(String giaTri) {
        if (giaTri == null || giaTri.trim().isEmpty()) {
            return "—";
        }
        String s = giaTri.trim();
        String[] mau = {"yyyy-MM-dd'T'HH:mm:ss.SSSXXX", "yyyy-MM-dd'T'HH:mm:ssXXX",
                "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd"};
        for (String m : mau) {
            try {
                SimpleDateFormat f = new SimpleDateFormat(m, Locale.US);
                f.setLenient(false);
                Date d = f.parse(s);
                if (d != null) {
                    return new SimpleDateFormat("dd/MM/yyyy", VI).format(d);
                }
            } catch (ParseException ignored) {
                // thử mẫu tiếp theo
            }
        }
        return s;
    }

    public static String ngayGio(String giaTri) {
        if (giaTri == null || giaTri.trim().isEmpty()) {
            return "—";
        }
        String s = giaTri.trim();
        String[] mau = {"yyyy-MM-dd'T'HH:mm:ss.SSSXXX", "yyyy-MM-dd'T'HH:mm:ssXXX",
                "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd"};
        for (String m : mau) {
            try {
                SimpleDateFormat f = new SimpleDateFormat(m, Locale.US);
                f.setLenient(false);
                Date d = f.parse(s);
                if (d != null) {
                    return new SimpleDateFormat("HH:mm dd/MM/yyyy", VI).format(d);
                }
            } catch (ParseException ignored) {
                // thử mẫu tiếp theo
            }
        }
        return s;
    }

    /** "2026-11" -> "Tháng 11/2026". */
    public static String thang(String giaTri) {
        if (giaTri == null || !giaTri.matches("\\d{4}-\\d{2}")) {
            return giaTri == null ? "—" : giaTri;
        }
        return "Tháng " + giaTri.substring(5, 7) + "/" + giaTri.substring(0, 4);
    }

    public static String homNay() {
        return new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date());
    }

    public static String thangNay() {
        return new SimpleDateFormat("yyyy-MM", Locale.US).format(new Date());
    }

    public static String thangTruoc(String thang) {
        try {
            SimpleDateFormat f = new SimpleDateFormat("yyyy-MM", Locale.US);
            f.setLenient(false);
            Date d = f.parse(thang);
            Calendar c = Calendar.getInstance();
            c.setTime(d);
            c.add(Calendar.MONTH, -1);
            return new SimpleDateFormat("yyyy-MM", Locale.US).format(c.getTime());
        } catch (ParseException e) {
            return thangNay();
        }
    }

    /** Số ngày từ hôm nay tới ngày yyyy-MM-dd (âm nếu đã qua). */
    public static int soNgayTuHomNay(String ngay) {
        try {
            SimpleDateFormat f = new SimpleDateFormat("yyyy-MM-dd", Locale.US);
            f.setLenient(false);
            Date d = f.parse(ngay);
            Calendar homNay = Calendar.getInstance();
            homNay.set(Calendar.HOUR_OF_DAY, 0);
            homNay.set(Calendar.MINUTE, 0);
            homNay.set(Calendar.SECOND, 0);
            homNay.set(Calendar.MILLISECOND, 0);
            long lech = d.getTime() - homNay.getTimeInMillis();
            return (int) Math.round(lech / 86_400_000.0);
        } catch (ParseException e) {
            return 0;
        }
    }

    /** Rút gọn tên: "Nguyễn Văn Chủ" -> "Chủ". */
    public static String tenNgan(String hoTen) {
        if (hoTen == null || hoTen.trim().isEmpty()) {
            return "?";
        }
        String[] phan = hoTen.trim().split("\\s+");
        return phan[phan.length - 1].substring(0, 1).toUpperCase(VI);
    }
}
