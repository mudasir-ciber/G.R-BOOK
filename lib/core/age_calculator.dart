/// Calendar-accurate age calculation.
///
/// Deliberately NOT `days / 365` — that drifts wrong around leap years
/// and unevenly-sized months. See [AgeCalculator.calculate] for the
/// calendar-anniversary method actually used.
class AgeResult {
  final int years;
  final int months;
  final int days;

  const AgeResult({required this.years, required this.months, required this.days});

  /// Total age expressed in whole months (years*12 + months), ignoring
  /// the leftover days. Used for admission/promotion month thresholds
  /// (e.g. "5 years 1 month" == 61 months).
  int get totalMonths => years * 12 + months;

  /// Human-readable form, e.g. "5 years 3 months 12 days".
  String format() {
    final parts = <String>[];
    parts.add('$years ${years == 1 ? 'year' : 'years'}');
    parts.add('$months ${months == 1 ? 'month' : 'months'}');
    parts.add('$days ${days == 1 ? 'day' : 'days'}');
    return parts.join(' ');
  }

  /// Compact form, e.g. "5y 3m 12d" — useful for list rows.
  String formatShort() => '${years}y ${months}m ${days}d';

  @override
  String toString() => format();
}

class AgeCalculator {
  AgeCalculator._();

  /// Calculates calendar-accurate age between [dateOfBirth] and [asOf].
  ///
  /// Method: count whole months from the date of birth, where "DOB plus
  /// N months" is clamped to the last day of a shorter month (31 Jan
  /// plus 1 month = 28/29 Feb; 29 Feb plus 1 year = 28 Feb). The days
  /// are then simply the calendar days since that anniversary, so they
  /// can never be negative and never exceed the length of a month.
  ///
  /// Throws [ArgumentError] if [asOf] is before [dateOfBirth] — a student
  /// cannot have a negative age; callers should surface this as a
  /// validation error rather than silently clamping it.
  static AgeResult calculate({
    required DateTime dateOfBirth,
    required DateTime asOf,
  }) {
    final dob = DateTime(dateOfBirth.year, dateOfBirth.month, dateOfBirth.day);
    final ref = DateTime(asOf.year, asOf.month, asOf.day);

    if (ref.isBefore(dob)) {
      throw ArgumentError(
        'Reference date ($ref) is before date of birth ($dob); cannot compute age.',
      );
    }

    var totalMonths = (ref.year - dob.year) * 12 + (ref.month - dob.month);
    if (_addMonthsClamped(dob, totalMonths).isAfter(ref)) {
      totalMonths -= 1;
    }
    final anniversary = _addMonthsClamped(dob, totalMonths);

    // Both are plain calendar dates (midnight), so difference in whole
    // days is exact; using UTC avoids daylight-saving hour shifts.
    final days = DateTime.utc(ref.year, ref.month, ref.day)
        .difference(DateTime.utc(anniversary.year, anniversary.month, anniversary.day))
        .inDays;

    return AgeResult(years: totalMonths ~/ 12, months: totalMonths % 12, days: days);
  }

  /// [date] plus [months] calendar months, clamped to the target
  /// month's last day when the day-of-month doesn't exist there.
  static DateTime _addMonthsClamped(DateTime date, int months) {
    final zeroBased = date.month - 1 + months;
    final year = date.year + zeroBased ~/ 12;
    final month = zeroBased % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, date.day > lastDay ? lastDay : date.day);
  }

  /// Convenience: is [dateOfBirth] at least [minMonths] old as of [asOf]?
  /// Used for ECE admission (>= 36 months) and ECE->Class1 promotion
  /// (>= 61 months) — both configurable, never hard-coded at the call site.
  static bool isAtLeastMonths({
    required DateTime dateOfBirth,
    required DateTime asOf,
    required int minMonths,
  }) {
    final age = calculate(dateOfBirth: dateOfBirth, asOf: asOf);
    return age.totalMonths >= minMonths;
  }
}
