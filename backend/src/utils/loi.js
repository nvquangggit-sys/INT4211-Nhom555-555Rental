// Lỗi nghiệp vụ có mã HTTP đi kèm, được error handler chung trả về JSON.
class LoiApi extends Error {
  constructor(ma, thongDiep, chiTiet) {
    super(thongDiep);
    this.ma = ma;
    this.chiTiet = chiTiet;
    this.laApi = true;
  }
}

function nem(ma, thongDiep, chiTiet) {
  throw new LoiApi(ma, thongDiep, chiTiet);
}

module.exports = { LoiApi, nem };
