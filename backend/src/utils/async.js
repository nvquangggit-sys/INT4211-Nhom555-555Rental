// Bọc handler async để lỗi Promise được chuyển cho error handler của Express.
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

module.exports = { asyncHandler };
