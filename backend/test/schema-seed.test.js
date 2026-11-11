// Kiểm tra schema.sql + seed.sql chạy sạch trên PostgreSQL nhúng (PGlite)
// và đủ số lượng dữ liệu mẫu tối thiểu theo đề.
// Chạy: npm run test:sql
const fs = require('fs');
const path = require('path');
const { PGlite } = require('@electric-sql/pglite');

const MONG_DOI = {
  phong: 60,
  hop_dong: 45,
  chi_so: 315,
  hoa_don: 270,
  chi_tiet: 1350,
  nguoi_thue: 45,
};

(async () => {
  const root = path.resolve(__dirname, '..');
  const db = new PGlite();
  for (const f of ['schema.sql', 'seed.sql']) {
    const sql = fs.readFileSync(path.join(root, f), 'utf8');
    console.log('=== chay ' + f + ' ===');
    const res = await db.exec(sql);
    if (res && res.length) {
      for (const r of res) {
        if (r.rows && r.rows.length) console.log(JSON.stringify(r.rows));
      }
    }
    console.log('OK ' + f);
  }
  const check = await db.query(`
    SELECT
      (SELECT count(*) FROM phong)::int AS phong,
      (SELECT count(*) FROM hop_dong)::int AS hop_dong,
      (SELECT count(*) FROM chi_so_dien_nuoc)::int AS chi_so,
      (SELECT count(*) FROM hoa_don)::int AS hoa_don,
      (SELECT count(*) FROM chi_tiet_hoa_don)::int AS chi_tiet,
      (SELECT count(*) FROM hoa_don WHERE trang_thai='QUA_HAN')::int AS qua_han,
      (SELECT count(*) FROM hoa_don WHERE trang_thai<>'DA_THU')::int AS con_no,
      (SELECT count(*) FROM nguoi_dung WHERE vai_tro='NGUOI_THUE')::int AS nguoi_thue
  `);
  console.log(check.rows[0]);
  const anomaly = await db.query(`
    WITH x AS (
      SELECT cs.phong_id, cs.thang, (cs.dien_cuoi-cs.dien_dau) AS tt,
        (SELECT avg(dien_cuoi-dien_dau) FROM (
            SELECT dien_cuoi, dien_dau FROM chi_so_dien_nuoc c2
            WHERE c2.phong_id=cs.phong_id AND c2.thang<cs.thang
            ORDER BY c2.thang DESC LIMIT 3
        ) t) AS tb
      FROM chi_so_dien_nuoc cs
    )
    SELECT count(*)::int AS so_phong_bat_thuong FROM x
    WHERE tb > 0 AND tt > tb*1.5
  `);
  console.log(anomaly.rows[0]);
  const sample = await db.query(`
    SELECT hd.id, hd.thang, hd.tong_tien, hd.da_thu, hd.trang_thai, hd.han_thanh_toan,
           (SELECT count(*) FROM chi_tiet_hoa_don ct WHERE ct.hoa_don_id=hd.id)::int AS so_khoan
    FROM hoa_don hd ORDER BY hd.id LIMIT 3
  `);
  console.log(sample.rows);
  const sai = Object.entries(MONG_DOI).filter(([k, v]) => Number(check.rows[0][k]) !== v);
  if (sai.length) {
    console.error('SAI SO LUONG:', sai.map(([k, v]) => `${k} mong doi ${v}, thuc te ${check.rows[0][k]}`).join('; '));
    process.exitCode = 1;
  } else {
    console.log('=== KET QUA: schema.sql + seed.sql dat, du so luong ===');
  }
  await db.close();
})().catch((e) => { console.error('LOI:', e); process.exit(1); });
