// Kiểm thử end-to-end backend trên PostgreSQL nhúng (PGlite).
// Chạy: npm run test:api  (cần devDependencies @electric-sql/pglite*)
// Script tự chạy schema.sql + seed.sql, mở socket PostgreSQL, khởi động Express
// trên cổng test rồi gọi API thật bằng fetch.
const fs = require('fs');
const path = require('path');
const { PGlite } = require('@electric-sql/pglite');
const { PGLiteSocketServer } = require('@electric-sql/pglite-socket');

const ROOT = path.resolve(__dirname, '..');
const PORT_DB = Number(process.env.TEST_PG_PORT || 55432);
const PORT_API = Number(process.env.TEST_API_PORT || 3100);

let dem = 0, dat = 0, hong = 0;
const ketQua = [];
function ok(ten) { dem++; dat++; ketQua.push(`  ĐẠT  ${ten}`); }
function loi(ten, chiTiet) { dem++; hong++; ketQua.push(`  HỎNG ${ten}${chiTiet ? ' -> ' + chiTiet : ''}`); }

async function goi(method, duongDan, { token, body, headers } = {}) {
  const h = { ...(headers || {}) };
  if (token) h.Authorization = `Bearer ${token}`;
  let payload = body;
  if (body && !(body instanceof FormData)) {
    h['Content-Type'] = 'application/json';
    payload = JSON.stringify(body);
  }
  const res = await fetch(`http://127.0.0.1:${PORT_API}${duongDan}`, { method, headers: h, body: payload });
  const text = await res.text();
  let json = null;
  try { json = text ? JSON.parse(text) : null; } catch (_) { json = text; }
  return { status: res.status, body: json, headers: res.headers };
}

function kiemTra(ten, dieuKien, chiTiet) {
  if (dieuKien) ok(ten);
  else loi(ten, typeof chiTiet === 'function' ? chiTiet() : chiTiet);
}

(async () => {
  const db = new PGlite();
  await db.exec(fs.readFileSync(path.join(ROOT, 'schema.sql'), 'utf8'));
  await db.exec(fs.readFileSync(path.join(ROOT, 'seed.sql'), 'utf8'));

  const server = new PGLiteSocketServer({ db, port: PORT_DB, host: '127.0.0.1', maxConnections: 5 });
  await server.start();

  process.env.DATABASE_URL = `postgresql://postgres:postgres@127.0.0.1:${PORT_DB}/postgres`;
  process.env.PGSSL = 'false';
  process.env.JWT_SECRET = 'chuoi_bi_mat_test_nhom_555_toi_thieu_32_ky_tu';
  process.env.NODE_ENV = 'test';
  process.env.PGPOOL_MAX = '1';
  process.env.PUBLIC_BASE_URL = `http://127.0.0.1:${PORT_API}`;

  const app = require(path.join(ROOT, 'src', 'index.js'));
  const httpServer = await new Promise((resolve) => {
    const s = app.listen(PORT_API, () => resolve(s));
  });

  const { Client } = require('pg');
  const client = new Client({ connectionString: process.env.DATABASE_URL, ssl: false });
  await client.connect();

  try {
    console.log('=== BẮT ĐẦU KIỂM THỬ API ===');

    // 1. Health
    let r = await goi('GET', '/health');
    kiemTra('GET /health trả 200 và db ok', r.status === 200 && r.body.db === 'ok', () => JSON.stringify(r.body));

    // 2. Đăng nhập
    r = await goi('POST', '/auth/dang-nhap', { body: { email: 'chutro@555rental.vn', matKhau: '123456' } });
    kiemTra('Đăng nhập chủ trọ trả 200 + token', r.status === 200 && r.body.token && r.body.nguoiDung.vai_tro === 'CHU_TRO', () => JSON.stringify(r.body));
    const admin = r.body.token;
    const adminId = r.body.nguoiDung.id;

    r = await goi('POST', '/auth/dang-nhap', { body: { email: 'quanly@555rental.vn', matKhau: '123456' } });
    kiemTra('Đăng nhập quản lý trả 200', r.status === 200 && r.body.token, () => JSON.stringify(r.body));
    const quanLy = r.body.token;

    r = await goi('POST', '/auth/dang-nhap', { body: { email: 'nguoithue01@555rental.vn', matKhau: '123456' } });
    kiemTra('Đăng nhập người thuê 01 trả 200', r.status === 200 && r.body.token, () => JSON.stringify(r.body));
    const tenant = r.body.token;
    const tenantId = r.body.nguoiDung.id;

    r = await goi('POST', '/auth/dang-nhap', { body: { email: 'chutro@555rental.vn', matKhau: 'sai_mat_khau' } });
    kiemTra('Sai mật khẩu trả 401', r.status === 401, () => JSON.stringify(r.body));

    r = await goi('GET', '/auth/toi');
    kiemTra('GET /auth/toi không token trả 401', r.status === 401, () => JSON.stringify(r.body));

    r = await goi('GET', '/auth/toi', { token: admin });
    kiemTra('GET /auth/toi có token trả đúng hồ sơ', r.status === 200 && r.body.email === 'chutro@555rental.vn', () => JSON.stringify(r.body));

    // Token ký bằng thuật toán khác HS256 phải bị từ chối (chống alg confusion)
    const jwtLib = require('jsonwebtoken');
    const tokenHS512 = jwtLib.sign({ id: adminId, vaiTro: 'CHU_TRO' }, process.env.JWT_SECRET, { algorithm: 'HS512' });
    r = await goi('GET', '/auth/toi', { token: tokenHS512 });
    kiemTra('Token ký HS512 bị từ chối 401', r.status === 401, () => JSON.stringify(r.body));

    // 3. Phân quyền
    r = await goi('GET', '/khu-tro', { token: tenant });
    kiemTra('Người thuê gọi /khu-tro trả 403', r.status === 403, () => JSON.stringify(r.body));

    r = await goi('GET', '/nguoi-dung?vaiTro=NGUOI_THUE', { token: tenant });
    kiemTra('Người thuê gọi /nguoi-dung trả 403', r.status === 403, () => JSON.stringify(r.body));

    r = await goi('GET', '/nguoi-dung?vaiTro=NGUOI_THUE', { token: admin });
    kiemTra('Chủ trọ lấy 45 người thuê, không lộ mật khẩu', r.status === 200 && r.body.length === 45 && !('mat_khau_hash' in (r.body[0] || {})), () => JSON.stringify(r.body && r.body[0]));

    r = await goi('GET', '/khu-tro', { token: admin });
    kiemTra('Chủ trọ thấy 3 khu trọ', r.status === 200 && r.body.length === 3, () => JSON.stringify(r.body));

    r = await goi('GET', '/khu-tro', { token: quanLy });
    kiemTra('Quản lý xem được khu trọ', r.status === 200 && r.body.length === 3, () => JSON.stringify(r.body));

    // 4. Tìm phòng công khai
    r = await goi('GET', '/phong?trangThai=TRONG');
    kiemTra('GET /phong?trangThai=TRONG trả 9 phòng', r.status === 200 && r.body.length === 9, () => JSON.stringify(r.body && r.body.length));

    r = await goi('GET', '/phong?khuVuc=Th%E1%BB%A7%20%C4%90%E1%BB%A9c');
    kiemTra('Lọc theo khu vực Thủ Đức trả 3 phòng trống', r.status === 200 && r.body.length === 3, () => JSON.stringify(r.body));

    r = await goi('GET', '/phong?giaTu=2500000&giaDen=3000000&trangThai=ALL');
    kiemTra('Lọc khoảng giá trả danh sách', r.status === 200 && Array.isArray(r.body), () => JSON.stringify(r.body));

    r = await goi('GET', "/phong?khuVuc=%27%3B%20DROP%20TABLE%20phong%3B%20--");
    const conBang = await client.query("SELECT count(*)::int AS n FROM information_schema.tables WHERE table_name='phong'");
    kiemTra('Thử SQL injection không làm mất bảng phong', r.status === 200 && conBang.rows[0].n === 1, () => JSON.stringify(r.body));

    r = await goi('GET', '/phong?dienTichTu=abc');
    kiemTra('Lọc diện tích không phải số trả 400', r.status === 400, () => JSON.stringify(r.body));

    r = await goi('GET', '/phong?dienTichTu=25&dienTichDen=20&trangThai=ALL');
    kiemTra('Lọc khoảng diện tích hợp lệ trả 200', r.status === 200 && Array.isArray(r.body), () => JSON.stringify(r.body));

    r = await goi('GET', '/phong?limit=-5');
    kiemTra('limit âm được kẹp về 1, không trả 500', r.status === 200 && Array.isArray(r.body) && r.body.length === 1, () => JSON.stringify(r.body && r.body.length));

    r = await goi('GET', '/phong/16');
    kiemTra('GET /phong/:id công khai trả chi tiết phòng', r.status === 200 && r.body.so_phong === '116', () => JSON.stringify(r.body));

    // 5. Hợp đồng + phòng
    r = await goi('GET', '/hop-dong', { token: admin });
    kiemTra('GET /hop-dong trả 45 hợp đồng', r.status === 200 && r.body.length === 45, () => JSON.stringify(r.body && r.body.length));

    r = await goi('POST', '/hop-dong', {
      token: admin,
      body: { phong_id: 16, nguoi_thue_id: tenantId, bat_dau: '2026-11-01', ket_thuc: '2027-11-01', tien_coc: 3000000, so_nguoi: 2 },
    });
    kiemTra('POST /hop-dong tạo hợp đồng cho phòng trống trả 201', r.status === 201 && r.body.trang_thai === 'HIEU_LUC' && r.body.ten_khu, () => JSON.stringify(r.body));
    const hopDongMoi = r.body.id;

    r = await goi('POST', '/hop-dong', {
      token: admin,
      body: { phong_id: 16, nguoi_thue_id: tenantId, bat_dau: '2026-11-01', ket_thuc: '2027-11-01', tien_coc: 3000000, so_nguoi: 2 },
    });
    kiemTra('Tạo hợp đồng trùng phòng đã thuê trả 409', r.status === 409, () => JSON.stringify(r.body));

    r = await goi('POST', '/hop-dong', {
      token: admin,
      body: { phong_id: 17, nguoi_thue_id: tenantId, bat_dau: '2026-11-01', ket_thuc: '2027-11-01', tien_coc: 3000000, so_nguoi: 99 },
    });
    kiemTra('Số người vượt sức chứa trả 400', r.status === 400, () => JSON.stringify(r.body));

    r = await goi('DELETE', '/phong/16', { token: admin });
    kiemTra('Xóa phòng đang có hợp đồng trả 409', r.status === 409, () => JSON.stringify(r.body));

    r = await goi('PATCH', `/hop-dong/${hopDongMoi}`, { token: admin, body: { trang_thai: 'DA_HUY' } });
    kiemTra('Hủy hợp đồng trả 200', r.status === 200 && r.body.trang_thai === 'DA_HUY', () => JSON.stringify(r.body));

    const p16 = await client.query('SELECT trang_thai FROM phong WHERE id=16');
    kiemTra('Hủy hợp đồng trả phòng về TRONG', p16.rows[0].trang_thai === 'TRONG', () => p16.rows[0].trang_thai);

    r = await goi('PATCH', `/hop-dong/${hopDongMoi}`, { token: admin, body: { trang_thai: 'HIEU_LUC' } });
    kiemTra('Không kích hoạt lại hợp đồng đã hủy (409)', r.status === 409, () => JSON.stringify(r.body));

    r = await goi('PATCH', `/hop-dong/${hopDongMoi}`, { token: admin, body: { ket_thuc: '2026-10-01' } });
    kiemTra('Sửa ngày kết thúc trước ngày bắt đầu trả 400', r.status === 400, () => JSON.stringify(r.body));

    const p16Sau = await client.query('SELECT trang_thai FROM phong WHERE id=16');
    kiemTra('Thao tác hợp đồng lỗi không đổi trạng thái phòng', p16Sau.rows[0].trang_thai === 'TRONG', () => p16Sau.rows[0].trang_thai);

    r = await goi('DELETE', '/khu-tro/1', { token: admin });
    kiemTra('Xóa khu còn phòng trả 409', r.status === 409, () => JSON.stringify(r.body));

    // 6. Biểu giá
    r = await goi('PATCH', '/bieu-gia/1', { token: quanLy, body: { gia_dien: 4000 } });
    kiemTra('Quản lý sửa biểu giá trả 403', r.status === 403, () => JSON.stringify(r.body));

    r = await goi('PATCH', '/bieu-gia/1', { token: admin, body: { gia_dien: 3900 } });
    kiemTra('Chủ trọ sửa biểu giá trả 200', r.status === 200 && r.body.gia_dien === 3900, () => JSON.stringify(r.body));

    // 7. Chỉ số điện nước
    const phong1 = await client.query(
      `SELECT * FROM chi_so_dien_nuoc WHERE phong_id=1 ORDER BY thang DESC LIMIT 1`);
    const truoc1 = phong1.rows[0];
    const thangNay = (await client.query(`SELECT to_char(CURRENT_DATE,'YYYY-MM') AS t`)).rows[0].t;

    r = await goi('POST', '/chi-so-dien-nuoc', {
      token: admin,
      body: { phong_id: 1, thang: thangNay, dien_cuoi: truoc1.dien_cuoi + 330, nuoc_cuoi: truoc1.nuoc_cuoi + 9 },
    });
    kiemTra('Ghi chỉ số tháng hiện tại trả 201', r.status === 201, () => JSON.stringify(r.body));
    kiemTra('Chỉ số tự lấy đầu kỳ từ tháng trước', r.body && r.body.chi_so && r.body.chi_so.dien_dau === truoc1.dien_cuoi, () => JSON.stringify(r.body && r.body.chi_so));
    kiemTra('Có cảnh báo điện tăng vọt', r.body && r.body.canh_bao && r.body.canh_bao.loai === 'DIEN_TANG_VOT', () => JSON.stringify(r.body && r.body.canh_bao));

    r = await goi('POST', '/chi-so-dien-nuoc', {
      token: admin,
      body: { phong_id: 1, thang: thangNay, dien_cuoi: truoc1.dien_cuoi + 400, nuoc_cuoi: truoc1.nuoc_cuoi + 9 },
    });
    kiemTra('Ghi trùng tháng trả 409', r.status === 409, () => JSON.stringify(r.body));

    r = await goi('POST', '/chi-so-dien-nuoc', {
      token: admin,
      body: { phong_id: 2, thang: thangNay, dien_cuoi: 10, nuoc_cuoi: 10 },
    });
    kiemTra('Chỉ số cuối < đầu trả 400 đúng trường', r.status === 400 && r.body.chi_tiet && r.body.chi_tiet.truong === 'dien_cuoi', () => JSON.stringify(r.body));

    // 8. Phát hành hóa đơn hàng loạt
    // Thêm chỉ số tháng hiện tại cho 15 phòng khu 2 bằng SQL để test bulk
    await client.query(
      `INSERT INTO chi_so_dien_nuoc (phong_id, thang, dien_dau, dien_cuoi, nuoc_dau, nuoc_cuoi, ghi_boi)
       SELECT cs.phong_id, $1::char(7), cs.dien_cuoi, cs.dien_cuoi + 100 + (cs.phong_id % 30), cs.nuoc_cuoi, cs.nuoc_cuoi + 6, 1
         FROM chi_so_dien_nuoc cs
         JOIN phong p ON p.id = cs.phong_id
        WHERE p.khu_tro_id = 2
          AND cs.thang = to_char(CURRENT_DATE - interval '1 month', 'YYYY-MM')`,
      [thangNay]
    );

    r = await goi('POST', `/hoa-don/phat-hanh?thang=${thangNay}`, { token: admin });
    kiemTra('Phát hành thiếu khuTro trả 400 với thông báo rõ', r.status === 400 && /khuTro/.test(r.body.loi || ''), () => JSON.stringify(r.body));

    r = await goi('POST', `/hoa-don/phat-hanh?thang=${thangNay}&khuTro=2`, { token: admin });
    kiemTra('Phát hành hóa đơn khu 2 tạo 15 hóa đơn', r.status === 201 && r.body.so_hoa_don_da_tao === 15, () => JSON.stringify(r.body && { tao: r.body.so_hoa_don_da_tao, thieu: r.body.thieu_chi_so, bo: r.body.bo_qua }));
    kiemTra('Phát hành có cảnh báo bất thường', r.body && Array.isArray(r.body.canh_bao_bat_thuong), () => JSON.stringify(r.body && r.body.canh_bao_bat_thuong));
    const hoaDonMoi = r.body.da_tao && r.body.da_tao[0];

    r = await goi('POST', `/hoa-don/phat-hanh?thang=${thangNay}&khuTro=2`, { token: admin });
    kiemTra('Phát hành lần 2 bỏ qua 15 hóa đơn cũ (không nhân đôi)', r.status === 201 && r.body.so_hoa_don_da_tao === 0 && r.body.bo_qua.length === 15, () => JSON.stringify({ tao: r.body.so_hoa_don_da_tao, bo: r.body.bo_qua.length }));

    r = await goi('POST', `/hoa-don/phat-hanh?thang=${thangNay}&khuTro=1`, { token: tenant });
    kiemTra('Người thuê phát hành hóa đơn trả 403', r.status === 403, () => JSON.stringify(r.body));

    // Kiểm tra hóa đơn mới có đủ 5 khoản và tổng đúng
    const ct = await client.query('SELECT * FROM chi_tiet_hoa_don WHERE hoa_don_id=$1 ORDER BY id', [hoaDonMoi.hoa_don_id]);
    const tongCt = ct.rows.reduce((s, x) => s + Number(x.thanh_tien), 0);
    kiemTra('Hóa đơn mới có đủ 5 khoản', ct.rows.length === 5, () => JSON.stringify(ct.rows));
    kiemTra('Tổng chi tiết bằng tong_tien hóa đơn', tongCt === hoaDonMoi.tong_tien, () => `${tongCt} vs ${hoaDonMoi.tong_tien}`);

    r = await goi('GET', `/hoa-don/${hoaDonMoi.hoa_don_id}`, { token: admin });
    kiemTra('GET chi tiết hóa đơn có chi_tiet + chi_so', r.status === 200 && r.body.chi_tiet.length === 5 && r.body.chi_so, () => JSON.stringify(r.body && Object.keys(r.body)));

    // 9. Hóa đơn + công nợ
    r = await goi('GET', '/hoa-don', { token: admin });
    kiemTra('GET /hoa-don trả 270+ hóa đơn', r.status === 200 && r.body.length >= 270, () => JSON.stringify(r.body && r.body.length));

    r = await goi('GET', '/hoa-don?quaHan=10', { token: admin });
    kiemTra('Lọc phòng nợ quá 10 ngày trả >= 8 hóa đơn', r.status === 200 && r.body.length >= 8, () => JSON.stringify(r.body && r.body.length));

    r = await goi('GET', '/hoa-don', { token: tenant });
    kiemTra('Người thuê gọi danh sách hóa đơn admin trả 403', r.status === 403, () => JSON.stringify(r.body));

    // 10. Thanh toán
    const pending = await client.query('SELECT * FROM thanh_toan WHERE xac_nhan_boi IS NULL ORDER BY id LIMIT 1');
    const tt = pending.rows[0];

    // Test rollback: ép trigger lỗi khi cập nhật hóa đơn, xác nhận phải hoàn nguyên
    await client.query(
      `CREATE OR REPLACE FUNCTION chan_cap_nhat_hoa_don() RETURNS trigger AS $$
       BEGIN RAISE EXCEPTION 'loi test rollback'; END; $$ LANGUAGE plpgsql`
    );
    await client.query(
      'CREATE TRIGGER test_rollback BEFORE UPDATE ON hoa_don FOR EACH ROW EXECUTE FUNCTION chan_cap_nhat_hoa_don()'
    );
    // Lỗi này là chủ đích của ca kiểm thử, tạm ẩn log lỗi của server cho sạch kết quả.
    const gocConsoleError = console.error;
    console.error = () => {};
    r = await goi('PATCH', `/thanh-toan/${tt.id}/xac-nhan`, { token: admin });
    console.error = gocConsoleError;
    kiemTra('Lỗi giữa transaction xác nhận thanh toán trả 500', r.status === 500, () => JSON.stringify(r.body));
    const ttSauRollback = await client.query('SELECT xac_nhan_boi FROM thanh_toan WHERE id=$1', [tt.id]);
    kiemTra('Rollback giữ nguyên giao dịch chưa xác nhận', ttSauRollback.rows[0].xac_nhan_boi === null, () => JSON.stringify(ttSauRollback.rows[0]));
    await client.query('DROP TRIGGER test_rollback ON hoa_don');

    r = await goi('PATCH', `/thanh-toan/${tt.id}/xac-nhan`, { token: admin });
    kiemTra('Xác nhận thanh toán trả 200', r.status === 200 && r.body.thanh_toan.xac_nhan_boi === adminId, () => JSON.stringify(r.body));
    const hdSau = await client.query('SELECT da_thu, tong_tien, trang_thai FROM hoa_don WHERE id=$1', [tt.hoa_don_id]);
    kiemTra('Xác nhận cộng đúng tiền vào hóa đơn', hdSau.rows[0].da_thu >= tt.so_tien, () => JSON.stringify(hdSau.rows[0]));

    r = await goi('PATCH', `/thanh-toan/${tt.id}/xac-nhan`, { token: admin });
    kiemTra('Xác nhận lần 2 trả 409', r.status === 409, () => JSON.stringify(r.body));

    r = await goi('GET', '/hoa-don/cua-toi', { token: tenant });
    kiemTra('Người thuê xem hóa đơn của mình', r.status === 200 && r.body.length >= 1 && Array.isArray(r.body[0].chi_tiet), () => JSON.stringify(r.body && r.body.length));
    const hoaDonCuaToi = r.body.find((x) => x.tong_tien > x.da_thu && !x.thanh_toan.some((y) => y.xac_nhan_boi === null));
    kiemTra('Có hóa đơn còn nợ để test thanh toán', !!hoaDonCuaToi, () => JSON.stringify(r.body && r.body.map((x) => ({ id: x.id, con: x.tong_tien - x.da_thu }))));

    r = await goi('POST', '/thanh-toan', {
      token: tenant,
      body: { hoa_don_id: hoaDonCuaToi.id, so_tien: 100000, hinh_thuc: 'CHUYEN_KHOAN' },
    });
    kiemTra('Chuyển khoản thiếu ảnh biên lai trả 400', r.status === 400, () => JSON.stringify(r.body));

    r = await goi('POST', '/thanh-toan', {
      token: tenant,
      body: { hoa_don_id: hoaDonCuaToi.id, so_tien: 100000, hinh_thuc: 'CHUYEN_KHOAN', anh_bien_lai: 'https://picsum.photos/seed/test/600/800' },
    });
    kiemTra('Người thuê gửi xác nhận chuyển khoản trả 201', r.status === 201 && r.body.thanh_toan.xac_nhan_boi === null, () => JSON.stringify(r.body));

    r = await goi('POST', '/thanh-toan', {
      token: tenant,
      body: { hoa_don_id: hoaDonCuaToi.id, so_tien: 100000, hinh_thuc: 'CHUYEN_KHOAN', anh_bien_lai: 'https://picsum.photos/seed/test/600/800' },
    });
    kiemTra('Gửi trùng giao dịch chờ xác nhận trả 409', r.status === 409, () => JSON.stringify(r.body));

    r = await goi('GET', '/thanh-toan/cua-toi', { token: tenant });
    kiemTra('Người thuê xem lịch sử thanh toán', r.status === 200 && r.body.length >= 1, () => JSON.stringify(r.body && r.body.length));

    // 11. Sự cố
    r = await goi('POST', '/bao-su-co', {
      token: tenant,
      body: { phong_id: 1, loai: 'Hỏng điện', mo_ta: 'Ổ điện bị chập', anh_url: 'https://picsum.photos/seed/suco-test/800/600' },
    });
    kiemTra('Người thuê báo sự cố trả 201', r.status === 201 && r.body.trang_thai === 'MOI', () => JSON.stringify(r.body));
    const suCoId = r.body.id;

    r = await goi('PATCH', `/bao-su-co/${suCoId}`, { token: quanLy, body: { trang_thai: 'DA_XU_LY' } });
    kiemTra('Quản lý xử lý sự cố trả 200 + xu_ly_luc', r.status === 200 && r.body.xu_ly_luc, () => JSON.stringify(r.body));

    r = await goi('POST', '/bao-su-co', {
      token: tenant,
      body: { phong_id: 21, loai: 'Khác', mo_ta: 'Test phòng không thuê' },
    });
    kiemTra('Báo sự cố phòng không có hợp đồng trả 403', r.status === 403, () => JSON.stringify(r.body));

    // 12. Lịch xem phòng
    const thoiGian = new Date(Date.now() + 3 * 86400000).toISOString();
    r = await goi('POST', '/lich-xem-phong', { token: tenant, body: { phong_id: 17, thoi_gian: thoiGian } });
    kiemTra('Đặt lịch xem phòng trống trả 201', r.status === 201 && r.body.trang_thai === 'CHO_XAC_NHAN', () => JSON.stringify(r.body));
    const lichId = r.body.id;

    r = await goi('POST', '/lich-xem-phong', { token: tenant, body: { phong_id: 17, thoi_gian: thoiGian } });
    kiemTra('Đặt trùng giờ cùng phòng trả 409', r.status === 409, () => JSON.stringify(r.body));

    r = await goi('POST', '/lich-xem-phong', { token: tenant, body: { phong_id: 17, thoi_gian: '2020-01-01T09:00:00.000Z' } });
    kiemTra('Đặt lịch quá khứ trả 400', r.status === 400, () => JSON.stringify(r.body));

    r = await goi('PATCH', `/lich-xem-phong/${lichId}`, { token: quanLy, body: { trang_thai: 'DA_XAC_NHAN' } });
    kiemTra('Quản lý xác nhận lịch xem trả 200', r.status === 200 && r.body.trang_thai === 'DA_XAC_NHAN', () => JSON.stringify(r.body));

    r = await goi('GET', '/lich-xem-phong?trangThai=CHO_XAC_NHAN', { token: quanLy });
    kiemTra('Lọc lịch chờ xác nhận trả danh sách', r.status === 200 && Array.isArray(r.body), () => JSON.stringify(r.body && r.body.length));

    // 13. Hợp đồng / nhắc hạn client
    r = await goi('GET', '/hop-dong/cua-toi', { token: tenant });
    kiemTra('Người thuê xem hợp đồng của tôi', r.status === 200 && r.body.length === 1 && r.body[0].so_ngay_con_lai !== undefined, () => JSON.stringify(r.body));

    r = await goi('GET', '/nhac-han', { token: tenant });
    kiemTra('Nhắc hạn trả hóa đơn + hợp đồng', r.status === 200 && Array.isArray(r.body.hoa_don) && Array.isArray(r.body.hop_dong), () => JSON.stringify(r.body));

    // 14. Báo cáo
    r = await goi('GET', '/bao-cao/cong-no', { token: admin });
    kiemTra('Báo cáo công nợ trả tổng hợp + chi tiết', r.status === 200 && r.body.tong_hop.length === 3 && r.body.chi_tiet.length >= 8, () => JSON.stringify({ t: r.body.tong_hop, c: r.body.chi_tiet && r.body.chi_tiet.length }));

    r = await goi('GET', '/bao-cao/lap-day', { token: admin });
    kiemTra('Báo cáo lấp đầy trả 3 khu', r.status === 200 && r.body.length === 3 && r.body[0].ty_le_lap_day !== undefined, () => JSON.stringify(r.body));

    r = await goi('GET', '/bao-cao/doanh-thu', { token: admin });
    kiemTra('Báo cáo doanh thu chủ trọ trả theo khu + tháng', r.status === 200 && r.body.theo_khu.length === 3 && r.body.theo_thang.length >= 6, () => JSON.stringify(r.body && r.body.tong));

    r = await goi('GET', '/bao-cao/doanh-thu', { token: quanLy });
    kiemTra('Quản lý xem doanh thu trả 403', r.status === 403, () => JSON.stringify(r.body));

    r = await goi('GET', '/bao-cao/tieu-thu-bat-thuong', { token: admin });
    kiemTra('Báo cáo tiêu thụ bất thường trả >= 5 phòng', r.status === 200 && r.body.length >= 5, () => JSON.stringify(r.body && r.body.length));

    r = await goi('GET', '/bao-cao/tong-quan', { token: admin });
    kiemTra('Tổng quan chủ trọ có doanh thu tháng', r.status === 200 && r.body.phong && r.body.hoa_don_thang_nay, () => JSON.stringify(r.body));

    r = await goi('GET', '/bao-cao/tong-quan', { token: quanLy });
    kiemTra('Tổng quan quản lý KHÔNG có doanh thu', r.status === 200 && !r.body.hoa_don_thang_nay, () => JSON.stringify(r.body));

    // 14b. Trạng thái hóa đơn được suy ra từ dữ liệu, không "đóng băng" theo cột cũ
    const quaHan = await client.query(
      `SELECT id FROM hoa_don
        WHERE tong_tien > da_thu AND han_thanh_toan < CURRENT_DATE - 10
        ORDER BY id LIMIT 1`
    );
    const hoaDonQuaHanId = quaHan.rows[0].id;
    await client.query(`UPDATE hoa_don SET trang_thai = 'CHUA_THU' WHERE id = $1`, [hoaDonQuaHanId]);

    r = await goi('GET', '/hoa-don?trangThai=QUA_HAN', { token: admin });
    kiemTra('Hóa đơn quá hạn vẫn được nhận diện dù cột trang_thai là CHUA_THU',
      r.status === 200 && r.body.some((x) => x.id === hoaDonQuaHanId), () => JSON.stringify(r.body && r.body.length));

    r = await goi('GET', `/hoa-don/${hoaDonQuaHanId}`, { token: admin });
    kiemTra('Chi tiết hóa đơn quá hạn trả trang_thai QUA_HAN', r.status === 200 && r.body.trang_thai === 'QUA_HAN', () => JSON.stringify(r.body && r.body.trang_thai));

    // 15. 404
    r = await goi('GET', '/khong-ton-tai');
    kiemTra('Đường dẫn lạ trả 404', r.status === 404, () => JSON.stringify(r.body));

    // 16. Đăng ký
    r = await goi('POST', '/auth/dang-ky', { body: { email: 'moi555@test.vn', matKhau: '123456', hoTen: 'Người Mới' } });
    kiemTra('Đăng ký tài khoản mới trả 201 + token', r.status === 201 && r.body.token, () => JSON.stringify(r.body));

    r = await goi('POST', '/auth/dang-ky', { body: { email: 'moi555@test.vn', matKhau: '123456', hoTen: 'Người Mới' } });
    kiemTra('Đăng ký trùng email trả 409', r.status === 409, () => JSON.stringify(r.body));

    r = await goi('POST', '/auth/dang-ky', { body: { email: 'a'.repeat(115) + '@test.vn', matKhau: '123456', hoTen: 'Email Dài' } });
    kiemTra('Đăng ký email quá 120 ký tự trả 400', r.status === 400, () => JSON.stringify(r.body));

    // 17. Trường không bắt buộc gửi chuỗi rỗng thì lưu null, không lỗi 400
    r = await goi('POST', '/khu-tro', {
      token: admin,
      body: { ten: 'Khu Kiểm Thử Rỗng', dia_chi: '1 Đường Kiểm Thử', phuong_xa: 'Phường Kiểm Thử', tien_ich: '' },
    });
    kiemTra('Tạo khu với tiện ích rỗng trả 201 và lưu null', r.status === 201 && r.body.tien_ich === null, () => JSON.stringify(r.body));
    const khuRongId = r.body.id;

    r = await goi('POST', '/phong', {
      token: admin,
      body: { khu_tro_id: khuRongId, so_phong: '999', dien_tich: 20, gia_thue: 2000000, suc_chua: 2, anh_url: '' },
    });
    kiemTra('Tạo phòng với ảnh rỗng trả 201 và lưu null', r.status === 201 && r.body.anh_url === null, () => JSON.stringify(r.body));

    // 18. Chủ trọ không được thấy dữ liệu cá nhân của người thuê khu khác
    const chuKhac = await client.query(
      `INSERT INTO nguoi_dung (email, mat_khau_hash, ho_ten, vai_tro)
       VALUES ('chusoi555@test.vn', 'x', 'Chủ Sở Hữu Khác', 'CHU_TRO') RETURNING id`
    );
    const khuKhac = await client.query(
      `INSERT INTO khu_tro (ten, dia_chi, phuong_xa, chu_tro_id)
       VALUES ('Khu Người Khác', '2 Đường Khác', 'Phường Khác', $1) RETURNING id`,
      [chuKhac.rows[0].id]
    );
    const phongKhac = await client.query(
      `INSERT INTO phong (khu_tro_id, so_phong, dien_tich, gia_thue, suc_chua, trang_thai)
       VALUES ($1, '888', 20, 2000000, 2, 'DA_THUE') RETURNING id`,
      [khuKhac.rows[0].id]
    );
    const nguoiThueKhac = await client.query(
      `INSERT INTO nguoi_dung (email, mat_khau_hash, ho_ten, sdt, cccd, vai_tro)
       VALUES ('nguoithuela555@test.vn', 'x', 'Người Thuê Lạ', '0900000000', '099999999999', 'NGUOI_THUE') RETURNING id`
    );
    await client.query(
      `INSERT INTO hop_dong (phong_id, nguoi_thue_id, bat_dau, ket_thuc, tien_coc, so_nguoi, trang_thai)
       VALUES ($1, $2, CURRENT_DATE, CURRENT_DATE + 365, 0, 1, 'HIEU_LUC')`,
      [phongKhac.rows[0].id, nguoiThueKhac.rows[0].id]
    );

    r = await goi('GET', '/nguoi-dung?vaiTro=NGUOI_THUE&q=nguoithuela555', { token: admin });
    kiemTra('Chủ trọ không thấy người thuê của khu người khác', r.status === 200 && r.body.length === 0, () => JSON.stringify(r.body));

    r = await goi('GET', '/nguoi-dung?vaiTro=NGUOI_THUE&q=nguoithuela555', { token: quanLy });
    kiemTra('Quản lý vẫn thấy người thuê toàn hệ thống', r.status === 200 && r.body.length === 1, () => JSON.stringify(r.body));

  } catch (e) {
    console.error('LỖI TEST:', e);
    hong++;
  } finally {
    console.log(ketQua.join('\n'));
    console.log(`\n=== KẾT QUẢ: ${dat}/${dem} đạt, ${hong} hỏng ===`);
    await new Promise((resolve) => httpServer.close(resolve));
    await client.end().catch(() => {});
    const { pool } = require(path.join(ROOT, 'src', 'db.js'));
    await pool.end().catch(() => {});
    await server.stop();
    await db.close();
    process.exit(hong > 0 ? 1 : 0);
  }
})();
