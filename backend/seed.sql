-- =====================================================================
-- INT4211 - Nhóm 555 - Đề 12: Hệ thống quản lý nhà trọ - phòng cho thuê
-- seed.sql - Dữ liệu mẫu tối thiểu theo đề:
--   3 khu trọ, 60 phòng, 45 hợp đồng,
--   chỉ số điện nước 7 tháng (1 tháng gốc + 6 tháng billed),
--   270 hóa đơn (45 hợp đồng x 6 tháng) + chi tiết + thanh toán.
--
-- Chạy SAU schema.sql trong Supabase SQL Editor.
-- Dữ liệu dùng mốc CURRENT_DATE nên lúc nào chạy cũng "mới".
-- Tài khoản thử (mật khẩu chung: 123456):
--   chutro@555rental.vn    - CHU_TRO
--   quanly@555rental.vn    - QUAN_LY
--   nguoithue01@555rental.vn ... nguoithue45@555rental.vn - NGUOI_THUE
-- =====================================================================

TRUNCATE TABLE
    lich_xem_phong, bao_su_co, thanh_toan, chi_tiet_hoa_don, hoa_don,
    chi_so_dien_nuoc, hop_dong, bieu_gia, phong, khu_tro, nguoi_dung
RESTART IDENTITY CASCADE;

-- ---------------------------------------------------------------------
-- 1. Người dùng: 1 chủ trọ, 1 quản lý, 45 người thuê
--    Mật khẩu gốc của mọi tài khoản: 123456 (đã băm bcrypt)
-- ---------------------------------------------------------------------
INSERT INTO nguoi_dung (email, mat_khau_hash, ho_ten, sdt, cccd, vai_tro)
VALUES
    ('chutro@555rental.vn', '$2b$10$BnIfmPFBq4KNLBZSjVcxXeou1Col.oV/ksQlMZRyprca613OhQYWy',
     'Nguyễn Văn Chủ', '0901000001', '079001000001', 'CHU_TRO'),
    ('quanly@555rental.vn', '$2b$10$BnIfmPFBq4KNLBZSjVcxXeou1Col.oV/ksQlMZRyprca613OhQYWy',
     'Trần Thị Quản Lý', '0901000002', '079001000002', 'QUAN_LY');

INSERT INTO nguoi_dung (email, mat_khau_hash, ho_ten, sdt, cccd, vai_tro)
SELECT
    'nguoithue' || lpad(g::text, 2, '0') || '@555rental.vn',
    '$2b$10$BnIfmPFBq4KNLBZSjVcxXeou1Col.oV/ksQlMZRyprca613OhQYWy',
    (ARRAY['Nguyễn','Trần','Lê','Phạm','Hoàng','Vũ','Đặng','Bùi','Đỗ','Ngô','Dương','Lý'])[1 + ((g - 1) % 12)]
        || ' ' ||
    (ARRAY['An','Bình','Châu','Dũng','Giang','Hà','Hải','Hùng','Lan','Linh','Mai','Nam','Nga','Phong','Quân','Sơn','Tâm','Thảo','Trang','Tuấn','Vy','Yến','Khoa','Long','My'])[1 + ((g - 1) % 25)],
    '090' || lpad((1000000 + g)::text, 7, '0'),
    '0790' || lpad((10000000 + g)::text, 8, '0'),
    'NGUOI_THUE'
FROM generate_series(1, 45) AS g;

-- ---------------------------------------------------------------------
-- 2. Khu trọ + biểu giá
-- ---------------------------------------------------------------------
INSERT INTO khu_tro (ten, dia_chi, phuong_xa, chu_tro_id, tien_ich)
VALUES
    ('Khu trọ 555 Bình Thạnh', '12/5 Nguyễn Xí', 'Phường 26, Bình Thạnh, TP.HCM', 1,
     'Wifi, camera 24/7, giữ xe, máy giặt chung, sân phơi'),
    ('Khu trọ 555 Thủ Đức', '48 Đỗ Xuân Hợp', 'Phước Long B, Thủ Đức, TP.HCM', 1,
     'Wifi, camera, giữ xe, khu bếp chung, gần ĐH Bách Khoa'),
    ('Khu trọ 555 Gò Vấp', '231 Phan Huy Ích', 'Phường 15, Gò Vấp, TP.HCM', 1,
     'Wifi, camera, giữ xe, thang máy, gần chợ');

INSERT INTO bieu_gia (khu_tro_id, gia_dien, gia_nuoc, phi_rac, phi_gui_xe)
VALUES
    (1, 3800, 18000, 30000, 100000),
    (2, 3500, 16000, 25000,  90000),
    (3, 4000, 20000, 35000, 120000);

-- ---------------------------------------------------------------------
-- 3. 60 phòng: mỗi khu 20 phòng
--    n 1..15  => DA_THUE (45 phòng, khớp 45 hợp đồng)
--    n 16..18 => TRONG   (9 phòng để Client tìm/đặt lịch)
--    n 19..20 => DANG_SUA
-- ---------------------------------------------------------------------
INSERT INTO phong (khu_tro_id, so_phong, dien_tich, gia_thue, suc_chua, trang_thai, anh_url)
SELECT
    k.id,
    (100 + n)::text,
    (15 + ((n - 1) % 4) * 5)::numeric(5,1),
    2500000 + ((n - 1) / 5) * 400000 + (k.id - 1) * 150000,
    2 + ((n - 1) % 3),
    CASE WHEN n <= 15 THEN 'DA_THUE' WHEN n <= 18 THEN 'TRONG' ELSE 'DANG_SUA' END,
    'https://picsum.photos/seed/555phong-' || k.id || '-' || n || '/800/600'
FROM khu_tro k
CROSS JOIN generate_series(1, 20) AS n
ORDER BY k.id, n;

-- ---------------------------------------------------------------------
-- 4. 45 hợp đồng: mỗi phòng DA_THUE một hợp đồng, mỗi người thuê 1 hợp đồng
-- ---------------------------------------------------------------------
WITH phong_thue AS (
    SELECT p.id AS phong_id, p.gia_thue, p.suc_chua,
           row_number() OVER (ORDER BY p.khu_tro_id, p.so_phong) AS rn
    FROM phong p
    WHERE p.trang_thai = 'DA_THUE'
),
nguoi_thue AS (
    SELECT id, row_number() OVER (ORDER BY id) AS rn
    FROM nguoi_dung
    WHERE vai_tro = 'NGUOI_THUE'
)
INSERT INTO hop_dong (phong_id, nguoi_thue_id, bat_dau, ket_thuc, tien_coc, so_nguoi, trang_thai)
SELECT
    p.phong_id,
    n.id,
    (date_trunc('month', CURRENT_DATE) - interval '10 months')::date,
    (date_trunc('month', CURRENT_DATE) + interval '2 months' - interval '1 day')::date,
    p.gia_thue,
    LEAST(p.suc_chua, 1 + (p.rn % 3)),
    'HIEU_LUC'
FROM phong_thue p
JOIN nguoi_thue n ON n.rn = p.rn;

-- ---------------------------------------------------------------------
-- 5. Chỉ số điện nước 7 tháng cho 45 phòng có hợp đồng
--    m = 0 là tháng gốc (cách đây 7 tháng), m = 6 là tháng gần nhất
--    (cách đây 1 tháng). Hóa đơn chỉ tính cho m = 1..6.
--    Tháng gần nhất: các phòng có id % 9 = 1 tiêu thụ điện gấp 3 lần
--    để demo cảnh báo "tiêu thụ tăng vọt".
-- ---------------------------------------------------------------------
WITH hd AS (
    SELECT id AS hop_dong_id, phong_id,
           row_number() OVER (ORDER BY id) AS rn
    FROM hop_dong
),
m AS (
    SELECT generate_series(0, 6) AS m
),
tinh AS (
    SELECT
        hd.phong_id,
        m.m,
        (1000 + hd.phong_id * 41) AS dien_goc,
        (120 + hd.phong_id * 3)   AS nuoc_goc,
        (70 + ((hd.phong_id * 7 + m.m * 13) % 61)) AS dien_tt_goc,
        (5 + ((hd.phong_id * 3 + m.m * 5) % 8))    AS nuoc_tt
    FROM hd
    CROSS JOIN m
),
tinh2 AS (
    SELECT *,
           CASE
               WHEN tinh.m = 6 AND (tinh.phong_id % 9 = 1) THEN tinh.dien_tt_goc * 3
               ELSE tinh.dien_tt_goc
           END AS dien_tt
    FROM tinh
),
luy_ke AS (
    SELECT *,
           SUM(dien_tt) OVER (PARTITION BY phong_id ORDER BY m
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS dien_lk,
           SUM(nuoc_tt) OVER (PARTITION BY phong_id ORDER BY m
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS nuoc_lk
    FROM tinh2
)
INSERT INTO chi_so_dien_nuoc
    (phong_id, thang, dien_dau, dien_cuoi, nuoc_dau, nuoc_cuoi, ghi_boi, ghi_luc)
SELECT
    phong_id,
    to_char(date_trunc('month', CURRENT_DATE) - ((7 - m) || ' month')::interval, 'YYYY-MM'),
    dien_goc + dien_lk - dien_tt,
    dien_goc + dien_lk,
    nuoc_goc + nuoc_lk - nuoc_tt,
    nuoc_goc + nuoc_lk,
    CASE WHEN m % 2 = 0 THEN 2 ELSE 1 END,
    date_trunc('month', CURRENT_DATE) - ((7 - m) || ' month')::interval + interval '27 days'
FROM luy_ke;

-- ---------------------------------------------------------------------
-- 6. 270 hóa đơn (45 hợp đồng x 6 tháng) + chi tiết từng khoản
--    - Hóa đơn cũ: phần lớn đã thu, một số còn nợ để có công nợ quá 10 ngày
--    - Hóa đơn tháng gần nhất: hỗn hợp CHUA_THU / MOT_PHAN / DA_THU
-- ---------------------------------------------------------------------
WITH hd AS (
    SELECT h.id AS hop_dong_id, h.phong_id,
           p.gia_thue, p.khu_tro_id, p.so_phong,
           row_number() OVER (ORDER BY h.id) AS rn
    FROM hop_dong h
    JOIN phong p ON p.id = h.phong_id
),
m AS (SELECT generate_series(1, 6) AS mi),
x AS (
    SELECT
        hd.hop_dong_id, hd.phong_id, hd.gia_thue, hd.khu_tro_id, hd.so_phong, hd.rn, m.mi,
        to_char(date_trunc('month', CURRENT_DATE) - (m.mi || ' month')::interval, 'YYYY-MM') AS thang,
        (cs.dien_cuoi - cs.dien_dau) AS dien_tt,
        (cs.nuoc_cuoi - cs.nuoc_dau) AS nuoc_tt,
        bg.gia_dien, bg.gia_nuoc, bg.phi_rac, bg.phi_gui_xe
    FROM hd
    CROSS JOIN m
    JOIN chi_so_dien_nuoc cs
      ON cs.phong_id = hd.phong_id
     AND cs.thang = to_char(date_trunc('month', CURRENT_DATE) - (m.mi || ' month')::interval, 'YYYY-MM')
    JOIN bieu_gia bg ON bg.khu_tro_id = hd.khu_tro_id
),
y AS (
    SELECT x.*,
           (gia_thue + dien_tt * gia_dien + nuoc_tt * gia_nuoc + phi_rac + phi_gui_xe) AS tong,
           (to_date(thang, 'YYYY-MM') + interval '1 month' + interval '9 days')::date AS han
    FROM x
),
z AS (
    SELECT y.*,
           CASE
               WHEN mi >= 4 AND (rn % 9 = 0) THEN 'CHUA_THU'
               WHEN mi = 3 AND (rn % 5 = 0) THEN 'MOT_PHAN'
               WHEN mi = 3 AND (rn % 7 = 0) THEN 'CHUA_THU'
               WHEN mi = 2 AND (rn % 4 = 0) THEN 'MOT_PHAN'
               WHEN mi = 2 AND (rn % 6 = 0) THEN 'CHUA_THU'
               WHEN mi = 1 AND (rn % 3 = 0) THEN 'CHUA_THU'
               WHEN mi = 1 AND (rn % 3 = 1) THEN 'MOT_PHAN'
               ELSE 'DA_THU'
           END AS tt_goc
    FROM y
)
INSERT INTO hoa_don (hop_dong_id, thang, tong_tien, da_thu, han_thanh_toan, trang_thai)
SELECT
    hop_dong_id,
    thang,
    tong,
    CASE WHEN tt_goc = 'DA_THU' THEN tong
         WHEN tt_goc = 'MOT_PHAN' THEN tong / 2
         ELSE 0 END,
    han,
    CASE WHEN tt_goc = 'DA_THU' THEN 'DA_THU'
         WHEN han < CURRENT_DATE - 10 THEN 'QUA_HAN'
         ELSE tt_goc END
FROM z;

-- Chi tiết hóa đơn: 5 khoản x 270 hóa đơn = 1350 dòng
INSERT INTO chi_tiet_hoa_don (hoa_don_id, ten_khoan, so_luong, don_gia, thanh_tien)
SELECT hd.id, 'Tiền phòng', 1, p.gia_thue, p.gia_thue
FROM hoa_don hd
JOIN hop_dong h ON h.id = hd.hop_dong_id
JOIN phong p ON p.id = h.phong_id

UNION ALL

SELECT hd.id, 'Tiền điện',
       (cs.dien_cuoi - cs.dien_dau), bg.gia_dien,
       (cs.dien_cuoi - cs.dien_dau) * bg.gia_dien
FROM hoa_don hd
JOIN hop_dong h ON h.id = hd.hop_dong_id
JOIN phong p ON p.id = h.phong_id
JOIN bieu_gia bg ON bg.khu_tro_id = p.khu_tro_id
JOIN chi_so_dien_nuoc cs ON cs.phong_id = p.id AND cs.thang = hd.thang

UNION ALL

SELECT hd.id, 'Tiền nước',
       (cs.nuoc_cuoi - cs.nuoc_dau), bg.gia_nuoc,
       (cs.nuoc_cuoi - cs.nuoc_dau) * bg.gia_nuoc
FROM hoa_don hd
JOIN hop_dong h ON h.id = hd.hop_dong_id
JOIN phong p ON p.id = h.phong_id
JOIN bieu_gia bg ON bg.khu_tro_id = p.khu_tro_id
JOIN chi_so_dien_nuoc cs ON cs.phong_id = p.id AND cs.thang = hd.thang

UNION ALL

SELECT hd.id, 'Phí rác', 1, bg.phi_rac, bg.phi_rac
FROM hoa_don hd
JOIN hop_dong h ON h.id = hd.hop_dong_id
JOIN phong p ON p.id = h.phong_id
JOIN bieu_gia bg ON bg.khu_tro_id = p.khu_tro_id

UNION ALL

SELECT hd.id, 'Phí gửi xe', 1, bg.phi_gui_xe, bg.phi_gui_xe
FROM hoa_don hd
JOIN hop_dong h ON h.id = hd.hop_dong_id
JOIN phong p ON p.id = h.phong_id
JOIN bieu_gia bg ON bg.khu_tro_id = p.khu_tro_id;

-- ---------------------------------------------------------------------
-- 7. Thanh toán: hóa đơn đã thu có biên lai, 3 hóa đơn chờ chủ trọ xác nhận
-- ---------------------------------------------------------------------
INSERT INTO thanh_toan (hoa_don_id, so_tien, hinh_thuc, anh_bien_lai, xac_nhan_boi, thoi_diem)
SELECT
    hd.id,
    hd.da_thu,
    'CHUYEN_KHOAN',
    CASE WHEN hd.id % 3 = 0
         THEN 'https://picsum.photos/seed/bienlai-' || hd.id || '/600/800'
         ELSE NULL END,
    1,
    (hd.han_thanh_toan - interval '2 days' + interval '10 hours')::timestamptz
FROM hoa_don hd
WHERE hd.da_thu > 0;

-- 3 giao dịch người thuê báo đã chuyển khoản, chờ xác nhận (xac_nhan_boi NULL)
INSERT INTO thanh_toan (hoa_don_id, so_tien, hinh_thuc, anh_bien_lai, xac_nhan_boi, thoi_diem)
SELECT
    hd.id,
    hd.tong_tien - hd.da_thu,
    'CHUYEN_KHOAN',
    'https://picsum.photos/seed/cho-xac-nhan-' || hd.id || '/600/800',
    NULL,
    now() - interval '1 day'
FROM hoa_don hd
WHERE hd.trang_thai IN ('CHUA_THU', 'QUA_HAN')
  AND hd.tong_tien > hd.da_thu
ORDER BY hd.id DESC
LIMIT 3;

-- ---------------------------------------------------------------------
-- 8. Báo sự cố: 10 sự cố ở nhiều trạng thái
-- ---------------------------------------------------------------------
INSERT INTO bao_su_co (phong_id, nguoi_bao_id, loai, mo_ta, anh_url, trang_thai, xu_ly_luc)
SELECT
    h.phong_id,
    h.nguoi_thue_id,
    (ARRAY['Hỏng điện','Dột trần','Nước yếu','Khóa cửa hỏng','Máy lạnh không lạnh'])[1 + ((h.id - 1) % 5)],
    (ARRAY[
        'Ổ điện phòng bị chập, tắt aptomat sau khi dùng máy giặt.',
        'Trần phía cửa sổ bị dột khi mưa lớn, nước chảy xuống sàn.',
        'Vòi nước ở nhà vệ sinh chảy rất yếu vào buổi tối.',
        'Chốt khóa cửa chính bị kẹt, khó mở từ bên ngoài.',
        'Máy lạnh chạy nhưng không mát, tiếng ồn lớn.'
    ])[1 + ((h.id - 1) % 5)],
    'https://picsum.photos/seed/suco-' || h.id || '/800/600',
    CASE WHEN h.id % 3 = 0 THEN 'MOI'
         WHEN h.id % 3 = 1 THEN 'DANG_XU_LY'
         ELSE 'DA_XU_LY' END,
    CASE WHEN h.id % 3 = 2 THEN now() - interval '2 days' ELSE NULL END
FROM hop_dong h
WHERE h.id <= 10;

-- ---------------------------------------------------------------------
-- 9. Lịch xem phòng: 9 lịch cho các phòng đang trống, đủ 3 trạng thái
-- ---------------------------------------------------------------------
WITH phong_trong AS (
    SELECT id, row_number() OVER (ORDER BY id) AS rn
    FROM phong
    WHERE trang_thai = 'TRONG'
),
khach AS (
    SELECT id, row_number() OVER (ORDER BY id) AS rn
    FROM nguoi_dung
    WHERE vai_tro = 'NGUOI_THUE'
)
INSERT INTO lich_xem_phong (phong_id, khach_id, thoi_gian, trang_thai)
SELECT
    p.id,
    k.id,
    (CURRENT_DATE + (p.rn || ' days')::interval + interval '9 hours')::timestamptz,
    CASE WHEN p.rn % 3 = 0 THEN 'CHO_XAC_NHAN'
         WHEN p.rn % 3 = 1 THEN 'DA_XAC_NHAN'
         ELSE 'TU_CHOI' END
FROM phong_trong p
JOIN khach k ON k.rn = p.rn;

-- =====================================================================
-- 10. Kiểm tra số lượng sau khi seed (kỳ vọng: 47 / 3 / 60 / 3 / 45 /
--     315 / 270 / 1350 / 273 / 10 / 9)
-- =====================================================================
SELECT 'nguoi_dung' AS bang, count(*) AS so_dong FROM nguoi_dung
UNION ALL SELECT 'khu_tro',          count(*) FROM khu_tro
UNION ALL SELECT 'phong',            count(*) FROM phong
UNION ALL SELECT 'bieu_gia',         count(*) FROM bieu_gia
UNION ALL SELECT 'hop_dong',         count(*) FROM hop_dong
UNION ALL SELECT 'chi_so_dien_nuoc', count(*) FROM chi_so_dien_nuoc
UNION ALL SELECT 'hoa_don',          count(*) FROM hoa_don
UNION ALL SELECT 'chi_tiet_hoa_don', count(*) FROM chi_tiet_hoa_don
UNION ALL SELECT 'thanh_toan',       count(*) FROM thanh_toan
UNION ALL SELECT 'bao_su_co',        count(*) FROM bao_su_co
UNION ALL SELECT 'lich_xem_phong',   count(*) FROM lich_xem_phong
ORDER BY bang;
