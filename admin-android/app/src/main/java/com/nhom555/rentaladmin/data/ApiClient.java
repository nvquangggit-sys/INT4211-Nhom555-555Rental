package com.nhom555.rentaladmin.data;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

/**
 * Khởi tạo Retrofit dùng chung cho toàn app.
 *
 * - BASE_URL lấy từ TokenStore (mặc định là API Render của nhóm 555, có dấu / cuối).
 * - Interceptor tự gắn Authorization: Bearer <token> vào mọi request.
 * - Timeout 90 giây vì Render gói Free ngủ sau 15 phút, lần gọi đầu rất chậm.
 */
public final class ApiClient {

    public static final String TAG = "555Rental-API";
    private static final long TIMEOUT_GIAY = 90;

    private static volatile Retrofit retrofit;
    private static volatile String baseUrlDangDung;
    private static volatile ApiService apiService;
    private static Gson gson;

    private ApiClient() {
    }

    public static Gson gson() {
        if (gson == null) {
            gson = new GsonBuilder().setLenient().create();
        }
        return gson;
    }

    public static ApiService get(Context context) {
        Context app = context.getApplicationContext();
        String baseUrl = TokenStore.layBaseUrl(app);
        if (apiService == null || !baseUrl.equals(baseUrlDangDung)) {
            synchronized (ApiClient.class) {
                if (apiService == null || !baseUrl.equals(baseUrlDangDung)) {
                    retrofit = taoRetrofit(app, baseUrl);
                    apiService = retrofit.create(ApiService.class);
                    baseUrlDangDung = baseUrl;
                }
            }
        }
        return apiService;
    }

    /** Gọi khi người dùng đổi địa chỉ API để buộc tạo lại Retrofit. */
    public static void datLai() {
        synchronized (ApiClient.class) {
            retrofit = null;
            apiService = null;
            baseUrlDangDung = null;
        }
    }

    private static Retrofit taoRetrofit(Context app, String baseUrl) {
        OkHttpClient.Builder builder = new OkHttpClient.Builder()
                .connectTimeout(TIMEOUT_GIAY, TimeUnit.SECONDS)
                .readTimeout(TIMEOUT_GIAY, TimeUnit.SECONDS)
                .writeTimeout(TIMEOUT_GIAY, TimeUnit.SECONDS)
                .retryOnConnectionFailure(true)
                .addInterceptor(chain -> {
                    Request.Builder r = chain.request().newBuilder()
                            .addHeader("Accept", "application/json")
                            .addHeader("User-Agent", "555Rental-Admin-Android");
                    String token = TokenStore.layToken(app);
                    if (!token.isEmpty()) {
                        r.addHeader("Authorization", "Bearer " + token);
                    }
                    return chain.proceed(r.build());
                });

        boolean goLoi = (app.getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0;
        if (goLoi) {
            HttpLoggingInterceptor log = new HttpLoggingInterceptor(message -> Log.d(TAG, message));
            log.setLevel(HttpLoggingInterceptor.Level.BODY);
            builder.addInterceptor(log);
        }

        return new Retrofit.Builder()
                .baseUrl(baseUrl)
                .client(builder.build())
                .addConverterFactory(GsonConverterFactory.create(gson()))
                .build();
    }
}
