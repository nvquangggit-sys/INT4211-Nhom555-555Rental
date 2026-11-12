package com.nhom555.rentaladmin.data;

import com.nhom555.rentaladmin.data.model.BaoCaoCongNo;
import com.nhom555.rentaladmin.data.model.BaoCaoDoanhThu;
import com.nhom555.rentaladmin.data.model.BaoCaoLapDay;
import com.nhom555.rentaladmin.data.model.BaoCaoTongQuan;
import com.nhom555.rentaladmin.data.model.BieuGia;
import com.nhom555.rentaladmin.data.model.ChiSoDienNuoc;
import com.nhom555.rentaladmin.data.model.HoaDon;
import com.nhom555.rentaladmin.data.model.HoaDonChiTiet;
import com.nhom555.rentaladmin.data.model.HopDong;
import com.nhom555.rentaladmin.data.model.KetQuaDangNhap;
import com.nhom555.rentaladmin.data.model.KetQuaGhiChiSo;
import com.nhom555.rentaladmin.data.model.KetQuaPhatHanh;
import com.nhom555.rentaladmin.data.model.KetQuaXoa;
import com.nhom555.rentaladmin.data.model.KhuTro;
import com.nhom555.rentaladmin.data.model.LichXemPhong;
import com.nhom555.rentaladmin.data.model.NguoiDung;
import com.nhom555.rentaladmin.data.model.Phong;
import com.nhom555.rentaladmin.data.model.SuCo;
import com.nhom555.rentaladmin.data.model.ThanhToan;
import com.nhom555.rentaladmin.data.model.TieuThuBatThuong;
import com.nhom555.rentaladmin.data.model.YeuCauBieuGia;
import com.nhom555.rentaladmin.data.model.YeuCauChiSo;
import com.nhom555.rentaladmin.data.model.YeuCauDangNhap;
import com.nhom555.rentaladmin.data.model.YeuCauHopDong;
import com.nhom555.rentaladmin.data.model.YeuCauKhuTro;
import com.nhom555.rentaladmin.data.model.YeuCauPhong;
import com.nhom555.rentaladmin.data.model.YeuCauTrangThai;

import java.util.List;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.DELETE;
import retrofit2.http.GET;
import retrofit2.http.PATCH;
import retrofit2.http.POST;
import retrofit2.http.Path;
import retrofit2.http.Query;

/**
 * Hợp đồng API với backend Nhóm 555 (xem backend/api.md).
 * Tên trường giữ đúng snake_case của backend để Gson ánh xạ trực tiếp.
 */
public interface ApiService {

    // ---------- Xác thực ----------
    @POST("auth/dang-nhap")
    Call<KetQuaDangNhap> dangNhap(@Body YeuCauDangNhap body);

    @GET("auth/toi")
    Call<NguoiDung> toi();

    // ---------- Khu trọ ----------
    @GET("khu-tro")
    Call<List<KhuTro>> dsKhuTro();

    @POST("khu-tro")
    Call<KhuTro> taoKhuTro(@Body YeuCauKhuTro body);

    @PATCH("khu-tro/{id}")
    Call<KhuTro> suaKhuTro(@Path("id") int id, @Body YeuCauKhuTro body);

    @DELETE("khu-tro/{id}")
    Call<KetQuaXoa> xoaKhuTro(@Path("id") int id);

    // ---------- Phòng ----------
    @GET("phong")
    Call<List<Phong>> dsPhong(@Query("khuTro") Integer khuTro,
                              @Query("trangThai") String trangThai,
                              @Query("q") String q,
                              @Query("limit") int limit);

    @POST("phong")
    Call<Phong> taoPhong(@Body YeuCauPhong body);

    @PATCH("phong/{id}")
    Call<Phong> suaPhong(@Path("id") int id, @Body YeuCauPhong body);

    @DELETE("phong/{id}")
    Call<KetQuaXoa> xoaPhong(@Path("id") int id);

    // ---------- Hợp đồng ----------
    @GET("hop-dong")
    Call<List<HopDong>> dsHopDong(@Query("khuTro") Integer khuTro,
                                  @Query("trangThai") String trangThai,
                                  @Query("q") String q);

    @POST("hop-dong")
    Call<HopDong> taoHopDong(@Body YeuCauHopDong body);

    @PATCH("hop-dong/{id}")
    Call<HopDong> suaHopDong(@Path("id") int id, @Body YeuCauTrangThai body);

    // ---------- Người dùng ----------
    @GET("nguoi-dung")
    Call<List<NguoiDung>> dsNguoiDung(@Query("vaiTro") String vaiTro,
                                      @Query("q") String q);

    // ---------- Biểu giá ----------
    @GET("bieu-gia/{khuTroId}")
    Call<BieuGia> layBieuGia(@Path("khuTroId") int khuTroId);

    @PATCH("bieu-gia/{khuTroId}")
    Call<BieuGia> suaBieuGia(@Path("khuTroId") int khuTroId, @Body YeuCauBieuGia body);

    // ---------- Chỉ số điện nước ----------
    @GET("chi-so-dien-nuoc")
    Call<List<ChiSoDienNuoc>> dsChiSo(@Query("khuTro") Integer khuTro,
                                      @Query("thang") String thang);

    @GET("chi-so-dien-nuoc")
    Call<List<ChiSoDienNuoc>> dsChiSoTheoPhong(@Query("phong") int phongId);

    @POST("chi-so-dien-nuoc")
    Call<KetQuaGhiChiSo> ghiChiSo(@Body YeuCauChiSo body);

    // ---------- Hóa đơn ----------
    @GET("hoa-don")
    Call<List<HoaDon>> dsHoaDon(@Query("khuTro") Integer khuTro,
                                @Query("thang") String thang,
                                @Query("trangThai") String trangThai,
                                @Query("quaHan") Integer quaHan);

    @GET("hoa-don/{id}")
    Call<HoaDonChiTiet> chiTietHoaDon(@Path("id") int id);

    @POST("hoa-don/phat-hanh")
    Call<KetQuaPhatHanh> phatHanhHoaDon(@Query("thang") String thang,
                                        @Query("khuTro") int khuTro);

    // ---------- Thanh toán ----------
    @GET("thanh-toan")
    Call<List<ThanhToan>> dsThanhToan(@Query("khuTro") Integer khuTro,
                                      @Query("hoaDon") Integer hoaDon);

    @PATCH("thanh-toan/{id}/xac-nhan")
    Call<Object> xacNhanThanhToan(@Path("id") int id);

    // ---------- Sự cố ----------
    @GET("bao-su-co")
    Call<List<SuCo>> dsSuCo(@Query("khuTro") Integer khuTro,
                            @Query("trangThai") String trangThai);

    @PATCH("bao-su-co/{id}")
    Call<SuCo> capNhatSuCo(@Path("id") int id, @Body YeuCauTrangThai body);

    // ---------- Lịch xem phòng ----------
    @GET("lich-xem-phong")
    Call<List<LichXemPhong>> dsLichXem(@Query("khuTro") Integer khuTro,
                                       @Query("trangThai") String trangThai);

    @PATCH("lich-xem-phong/{id}")
    Call<LichXemPhong> capNhatLichXem(@Path("id") int id, @Body YeuCauTrangThai body);

    // ---------- Báo cáo ----------
    @GET("bao-cao/tong-quan")
    Call<BaoCaoTongQuan> baoCaoTongQuan();

    @GET("bao-cao/cong-no")
    Call<BaoCaoCongNo> baoCaoCongNo(@Query("khuTro") Integer khuTro,
                                    @Query("thang") String thang);

    @GET("bao-cao/lap-day")
    Call<List<BaoCaoLapDay>> baoCaoLapDay(@Query("khuTro") Integer khuTro);

    @GET("bao-cao/doanh-thu")
    Call<BaoCaoDoanhThu> baoCaoDoanhThu(@Query("khuTro") Integer khuTro,
                                        @Query("tuThang") String tuThang,
                                        @Query("denThang") String denThang);

    @GET("bao-cao/tieu-thu-bat-thuong")
    Call<List<TieuThuBatThuong>> baoCaoTieuThuBatThuong(@Query("thang") String thang,
                                                        @Query("khuTro") Integer khuTro);
}
