/// Ngày sinh chỉ có ngày/tháng/năm — tránh lệch 1 ngày do UTC.
class BirthDateUtils {
  BirthDateUtils._();

  /// Từ DatePicker (giữa đêm local) → chỉ lấy y-m-d.
  static DateTime fromPicker(DateTime picked) {
    return DateTime(picked.year, picked.month, picked.day);
  }

  /// Lưu Firestore: trưa UTC theo lịch đã chọn (không lệch ngày).
  static DateTime forStorage(DateTime calendarDate) {
    final d = fromPicker(calendarDate);
    return DateTime.utc(d.year, d.month, d.day, 12);
  }

  /// Đọc từ Firestore / ISO → ngày lịch local.
  static DateTime fromStored(DateTime stored) {
    final local = stored.isUtc ? stored.toLocal() : stored;
    return DateTime(local.year, local.month, local.day);
  }

  /// Hiển thị dd/MM/yyyy.
  static String formatVi(DateTime date) {
    final d = fromStored(date);
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  /// Session JSON: chỉ chuỗi ngày.
  static String toJsonValue(DateTime date) {
    final d = fromPicker(date);
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static DateTime fromJsonValue(dynamic raw) {
    if (raw is String) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
        final p = raw.split('-');
        return DateTime(
          int.parse(p[0]),
          int.parse(p[1]),
          int.parse(p[2]),
        );
      }
      return fromStored(DateTime.parse(raw));
    }
    return fromStored(DateTime.now());
  }
}
