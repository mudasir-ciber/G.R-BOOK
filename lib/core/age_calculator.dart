/// Calendar-accurate age calculation.
///
/// Deliberately NOT `days / 365` — that drifts wrong around leap years
/// and unevenly-sized months. Instead this walks whole years, then whole
/// months, then remaining days, borrowing from the previous unit exactly
/// the way a person counting on a calendar would.
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

    int years = ref.year - dob.year;
    int months = ref.month - dob.month;
    int days = ref.day - dob.day;

    if (days < 0) {
      // Borrow days from the previous month relative to `ref`.
      final prevMonthLastDay = _lastDayOfPreviousMonth(ref);
      days += prevMonthLastDay;
      months -= 1;
    }

    if (months < 0) {
      months += 12;
      years -= 1;
    }

    return AgeResult(years: years, months: months, days: days);
  }

  static int _lastDayOfPreviousMonth(DateTime ref) {
    // Day 0 of the current month == last day of the previous month.
    final firstOfCurrentMonth = DateTime(ref.year, ref.month, 1);
    final lastOfPrevMonth = firstOfCurrentMonth.subtract(const Duration(days: 1));
    return lastOfPrevMonth.day;
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
