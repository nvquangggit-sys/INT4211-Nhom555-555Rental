const { Pool } = require('pg');

// Supabase bắt buộc SSL. Khi chạy PostgreSQL nội bộ, đặt PGSSL=false trong .env.
const url = process.env.DATABASE_URL || '';
const batSSL = process.env.PGSSL !== 'false' && (
  /supabase\.(co|com)/.test(url) || /sslmode=require/.test(url) || process.env.NODE_ENV === 'production'
);

const pool = new Pool({
  connectionString: url,
  ssl: batSSL ? { rejectUnauthorized: false } : false,
  max: Number(process.env.PGPOOL_MAX || 5), // gói Free Supabase, đừng mở quá nhiều
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 20000,
});

pool.on('error', (e) => {
  console.error('[555Rental][db] Lỗi pool rảnh:', e.message);
});

// Luôn truyền tham số dạng $1, $2 - KHÔNG nối chuỗi SQL
const truyVan = (sql, params) => pool.query(sql, params);

// Dùng cho nghiệp vụ nhiều bước: tạo hợp đồng, xác nhận thanh toán,
// phát hành hóa đơn hàng loạt... Lỗi giữa chừng thì ROLLBACK.
async function trongGiaoDich(callback) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const ketQua = await callback(client);
    await client.query('COMMIT');
    return ketQua;
  } catch (e) {
    try { await client.query('ROLLBACK'); } catch (_) { /* bỏ qua */ }
    throw e;
  } finally {
    client.release();
  }
}

module.exports = { pool, truyVan, trongGiaoDich };
