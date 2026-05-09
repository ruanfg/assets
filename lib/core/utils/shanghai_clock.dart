class ShanghaiClock {
  const ShanghaiClock._();

  static const Duration _offset = Duration(hours: 8);

  static DateTime now() => DateTime.now().toUtc().add(_offset);

  static DateTime asShanghai(DateTime input) => input.toUtc().add(_offset);

  static String formatDate(DateTime input) {
    final value = asShanghai(input);
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static DateTime? tryParseDate(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    return DateTime.tryParse(input.trim());
  }
}
