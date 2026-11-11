-- =====================================================================
-- INT4211 - Nhóm 555 - Đề 12: Hệ thống quản lý nhà trọ - phòng cho thuê
-- schema.sql - Tạo toàn bộ 11 bảng trên PostgreSQL (Supabase)
--
-- Cách chạy:
--   1. Supabase -> SQL Editor -> dán toàn bộ tệp này -> Run
--   2. Dán tiếp seed.sql -> Run
--
-- Lưu ý: tệp này DROP bảng cũ trước khi tạo lại, chỉ dùng cho đồ án.
-- =====================================================================

-- Xóa theo thứ tự ngược khóa ngoại để chạy lại nhiều lần không lỗi
DROP TABLE IF EXISTS lich_xem_phong   CASCADE;
DROP TABLE IF EXISTS bao_su_co         CASCADE;
DROP TABLE IF EXISTS thanh_toan        CASCADE;
DROP TABLE IF EXISTS chi_tiet_hoa_don  CASCADE;
DROP TABLE IF EXISTS hoa_don           CASCADE;
DROP TABLE IF EXISTS chi_so_dien_nuoc  CASCADE;
DROP TABLE IF EXISTS hop_dong          CASCADE;
DROP TABLE IF EXISTS bieu_gia          CASCADE;
DROP TABLE IF EXISTS phong             CASCADE;
DROP TABLE IF EXISTS khu_tro           CASCADE;
DROP TABLE IF EXISTS nguoi_dung        CASCADE;

-- ---------------------------------------------------------------------
-- 1. nguoi_dung: tài khoản dùng chung cho chủ trọ, quản lý, người thuê
-- ---------------------------------------------------------------------
CREATE TABLE nguoi_dung (
    id             SERIAL PRIMARY KEY,
    email          VARCHAR(120) NOT NULL UNIQUE,
    mat_khau_hash  VARCHAR(100) NOT NULL,
    ho_ten         VARCHAR(100) NOT NULL,
    sdt            VARCHAR(15),
    cccd           VARCHAR(12) UNIQUE,
    vai_tro        VARCHAR(15) NOT NULL,
    CONSTRAINT nguoi_dung_vai_tro_ck
        CHECK (vai_tro IN ('CHU_TRO', 'QUAN_LY', 'NGUOI_THUE'))
);

-- ---------------------------------------------------------------------
-- 2. khu_tro: một khu/dãy trọ của chủ trọ
-- ---------------------------------------------------------------------
CREATE TABLE khu_tro (
    id          SERIAL PRIMARY KEY,
    ten         VARCHAR(100) NOT NULL,
    dia_chi     VARCHAR(200) NOT NULL,
    phuong_xa   VARCHAR(80)  NOT NULL,
    chu_tro_id  INTEGER      NOT NULL REFERENCES nguoi_dung(id) ON DELETE RESTRICT,
    tien_ich    TEXT
);

CREATE INDEX idx_khu_tro_chu_tro ON khu_tro(chu_tro_id);

-- ---------------------------------------------------------------------
-- 3. phong: phòng cho thuê thuộc một khu
-- ---------------------------------------------------------------------
CREATE TABLE phong (
    id           SERIAL PRIMARY KEY,
    khu_tro_id   INTEGER      NOT NULL REFERENCES khu_tro(id) ON DELETE RESTRICT,
    so_phong     VARCHAR(10)  NOT NULL,
    dien_tich    NUMERIC(5,1) NOT NULL,
    gia_thue     INTEGER      NOT NULL,
    suc_chua     INTEGER      NOT NULL,
    trang_thai   VARCHAR(10)  NOT NULL DEFAULT 'TRONG',
    anh_url      TEXT,
    CONSTRAINT phong_so_phong_uq UNIQUE (khu_tro_id, so_phong),
    CONSTRAINT phong_dien_tich_ck CHECK (dien_tich > 0),
    CONSTRAINT phong_gia_thue_ck  CHECK (gia_thue >= 0),
    CONSTRAINT phong_suc_chua_ck  CHECK (suc_chua >= 1),
    CONSTRAINT phong_trang_thai_ck
        CHECK (trang_thai IN ('TRONG', 'DA_THUE', 'DANG_SUA'))
);

CREATE INDEX idx_phong_khu_tro    ON phong(khu_tro_id);
CREATE INDEX idx_phong_trang_thai ON phong(trang_thai);

-- ---------------------------------------------------------------------
-- 4. bieu_gia: đơn giá điện, nước, rác, gửi xe của từng khu
-- ---------------------------------------------------------------------
CREATE TABLE bieu_gia (
    id           SERIAL PRIMARY KEY,
    khu_tro_id   INTEGER NOT NULL UNIQUE REFERENCES khu_tro(id) ON DELETE CASCADE,
    gia_dien     INTEGER NOT NULL,
    gia_nuoc     INTEGER NOT NULL,
    phi_rac      INTEGER NOT NULL DEFAULT 0,
    phi_gui_xe   INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT bieu_gia_gia_dien_ck  CHECK (gia_dien  >= 0),
    CONSTRAINT bieu_gia_gia_nuoc_ck  CHECK (gia_nuoc  >= 0),
    CONSTRAINT bieu_gia_phi_rac_ck   CHECK (phi_rac   >= 0),
    CONSTRAINT bieu_gia_phi_gui_xe_ck CHECK (phi_gui_xe >= 0)
);

-- ---------------------------------------------------------------------
-- 5. hop_dong: hợp đồng thuê giữa một người thuê và một phòng
-- ---------------------------------------------------------------------
CREATE TABLE hop_dong (
    id             SERIAL PRIMARY KEY,
    phong_id       INTEGER NOT NULL REFERENCES phong(id) ON DELETE RESTRICT,
    nguoi_thue_id  INTEGER NOT NULL REFERENCES nguoi_dung(id) ON DELETE RESTRICT,
    bat_dau        DATE    NOT NULL,
    ket_thuc       DATE    NOT NULL,
    tien_coc       INTEGER NOT NULL,
    so_nguoi       INTEGER NOT NULL,
    trang_thai     VARCHAR(10) NOT NULL DEFAULT 'HIEU_LUC',
    CONSTRAINT hop_dong_ngay_ck    CHECK (ket_thuc > bat_dau),
    CONSTRAINT hop_dong_tien_coc_ck CHECK (tien_coc >= 0),
    CONSTRAINT hop_dong_so_nguoi_ck CHECK (so_nguoi >= 1),
    CONSTRAINT hop_dong_trang_thai_ck
        CHECK (trang_thai IN ('HIEU_LUC', 'HET_HAN', 'DA_HUY'))
);

CREATE INDEX idx_hop_dong_phong      ON hop_dong(phong_id);
CREATE INDEX idx_hop_dong_nguoi_thue ON hop_dong(nguoi_thue_id);
CREATE INDEX idx_hop_dong_trang_thai ON hop_dong(trang_thai);

-- ---------------------------------------------------------------------
-- 6. chi_so_dien_nuoc: chỉ số điện nước ghi hằng tháng cho từng phòng
-- ---------------------------------------------------------------------
CREATE TABLE chi_so_dien_nuoc (
    id          SERIAL PRIMARY KEY,
    phong_id    INTEGER      NOT NULL REFERENCES phong(id) ON DELETE RESTRICT,
    thang       CHAR(7)      NOT NULL,
    dien_dau    INTEGER      NOT NULL,
    dien_cuoi   INTEGER      NOT NULL,
    nuoc_dau    INTEGER      NOT NULL,
    nuoc_cuoi   INTEGER      NOT NULL,
    ghi_boi     INTEGER      NOT NULL REFERENCES nguoi_dung(id) ON DELETE RESTRICT,
    ghi_luc     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT chi_so_phong_thang_uq UNIQUE (phong_id, thang),
    CONSTRAINT chi_so_dien_dau_ck   CHECK (dien_dau  >= 0),
    CONSTRAINT chi_so_dien_cuoi_ck  CHECK (dien_cuoi >= dien_dau),
    CONSTRAINT chi_so_nuoc_dau_ck   CHECK (nuoc_dau  >= 0),
    CONSTRAINT chi_so_nuoc_cuoi_ck  CHECK (nuoc_cuoi >= nuoc_dau),
    CONSTRAINT chi_so_thang_ck
        CHECK (thang ~ '^[0-9]{4}-(0[1-9]|1[0-2])$')
);

CREATE INDEX idx_chi_so_thang ON chi_so_dien_nuoc(thang);

-- ---------------------------------------------------------------------
-- 7. hoa_don: hóa đơn tháng của một hợp đồng
-- ---------------------------------------------------------------------
CREATE TABLE hoa_don (
    id              SERIAL PRIMARY KEY,
    hop_dong_id     INTEGER NOT NULL REFERENCES hop_dong(id) ON DELETE RESTRICT,
    thang           CHAR(7) NOT NULL,
    tong_tien       INTEGER NOT NULL,
    da_thu          INTEGER NOT NULL DEFAULT 0,
    han_thanh_toan  DATE    NOT NULL,
    trang_thai      VARCHAR(10) NOT NULL DEFAULT 'CHUA_THU',
    CONSTRAINT hoa_don_hop_dong_thang_uq UNIQUE (hop_dong_id, thang),
    CONSTRAINT hoa_don_tong_tien_ck CHECK (tong_tien >= 0),
    CONSTRAINT hoa_don_da_thu_ck    CHECK (da_thu >= 0 AND da_thu <= tong_tien),
    CONSTRAINT hoa_don_trang_thai_ck
        CHECK (trang_thai IN ('CHUA_THU', 'MOT_PHAN', 'DA_THU', 'QUA_HAN')),
    CONSTRAINT hoa_don_thang_ck
        CHECK (thang ~ '^[0-9]{4}-(0[1-9]|1[0-2])$')
);

CREATE INDEX idx_hoa_don_thang     ON hoa_don(thang);
CREATE INDEX idx_hoa_don_trang_thai ON hoa_don(trang_thai);
CREATE INDEX idx_hoa_don_han       ON hoa_don(han_thanh_toan);

-- ---------------------------------------------------------------------
-- 8. chi_tiet_hoa_don: từng khoản trong hóa đơn
-- ---------------------------------------------------------------------
CREATE TABLE chi_tiet_hoa_don (
    id          SERIAL PRIMARY KEY,
    hoa_don_id  INTEGER NOT NULL REFERENCES hoa_don(id) ON DELETE CASCADE,
    ten_khoan   VARCHAR(60) NOT NULL,
    so_luong    NUMERIC(8,1) NOT NULL,
    don_gia     INTEGER NOT NULL,
    thanh_tien  INTEGER NOT NULL,
    CONSTRAINT chi_tiet_so_luong_ck   CHECK (so_luong >= 0),
    CONSTRAINT chi_tiet_don_gia_ck    CHECK (don_gia >= 0),
    CONSTRAINT chi_tiet_thanh_tien_ck CHECK (thanh_tien >= 0)
);

CREATE INDEX idx_chi_tiet_hoa_don ON chi_tiet_hoa_don(hoa_don_id);

-- ---------------------------------------------------------------------
-- 9. thanh_toan: một lần người thuê chuyển tiền cho một hóa đơn
-- ---------------------------------------------------------------------
CREATE TABLE thanh_toan (
    id             SERIAL PRIMARY KEY,
    hoa_don_id     INTEGER NOT NULL REFERENCES hoa_don(id) ON DELETE RESTRICT,
    so_tien        INTEGER NOT NULL,
    hinh_thuc      VARCHAR(15) NOT NULL,
    anh_bien_lai   TEXT,
    xac_nhan_boi   INTEGER REFERENCES nguoi_dung(id) ON DELETE SET NULL,
    thoi_diem      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT thanh_toan_so_tien_ck CHECK (so_tien > 0),
    CONSTRAINT thanh_toan_hinh_thuc_ck
        CHECK (hinh_thuc IN ('TIEN_MAT', 'CHUYEN_KHOAN'))
);

CREATE INDEX idx_thanh_toan_hoa_don ON thanh_toan(hoa_don_id);

-- ---------------------------------------------------------------------
-- 10. bao_su_co: sự cố người thuê báo
-- ---------------------------------------------------------------------
CREATE TABLE bao_su_co (
    id            SERIAL PRIMARY KEY,
    phong_id      INTEGER NOT NULL REFERENCES phong(id) ON DELETE RESTRICT,
    nguoi_bao_id  INTEGER NOT NULL REFERENCES nguoi_dung(id) ON DELETE RESTRICT,
    loai          VARCHAR(30) NOT NULL,
    mo_ta         TEXT NOT NULL,
    anh_url       TEXT,
    trang_thai    VARCHAR(12) NOT NULL DEFAULT 'MOI',
    xu_ly_luc     TIMESTAMPTZ,
    CONSTRAINT bao_su_co_trang_thai_ck
        CHECK (trang_thai IN ('MOI', 'DANG_XU_LY', 'DA_XU_LY'))
);

CREATE INDEX idx_bao_su_co_phong      ON bao_su_co(phong_id);
CREATE INDEX idx_bao_su_co_trang_thai ON bao_su_co(trang_thai);

-- ---------------------------------------------------------------------
-- 11. lich_xem_phong: khách đặt lịch xem phòng
-- ---------------------------------------------------------------------
CREATE TABLE lich_xem_phong (
    id         SERIAL PRIMARY KEY,
    phong_id   INTEGER NOT NULL REFERENCES phong(id) ON DELETE CASCADE,
    khach_id   INTEGER NOT NULL REFERENCES nguoi_dung(id) ON DELETE CASCADE,
    thoi_gian  TIMESTAMPTZ NOT NULL,
    trang_thai VARCHAR(12) NOT NULL DEFAULT 'CHO_XAC_NHAN',
    CONSTRAINT lich_xem_phong_trang_thai_ck
        CHECK (trang_thai IN ('CHO_XAC_NHAN', 'DA_XAC_NHAN', 'TU_CHOI'))
);

CREATE INDEX idx_lich_xem_phong_phong  ON lich_xem_phong(phong_id);
CREATE INDEX idx_lich_xem_phong_trang_thai ON lich_xem_phong(trang_thai);

-- =====================================================================
-- Ghi chú thiết kế (dùng cho phần bảo vệ):
-- - Tiền lưu INTEGER (đồng), không dùng FLOAT để tránh sai số.
-- - thang lưu CHAR(7) dạng YYYY-MM.
-- - UNIQUE(hop_dong_id, thang) chặn phát hành trùng hóa đơn.
-- - UNIQUE(phong_id, thang) chặn ghi trùng chỉ số.
-- - CHECK(dien_cuoi >= dien_dau) chặn công tơ chạy lùi ở tầng CSDL.
-- - Các nghiệp vụ nhiều bước (tạo hợp đồng, xác nhận thanh toán,
--   phát hành hóa đơn hàng loạt) dùng transaction ở backend.
-- =====================================================================
