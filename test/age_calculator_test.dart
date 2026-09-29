import 'package:flutter_test/flutter_test.dart';
import 'package:gr_book/core/age_calculator.dart';

AgeResult age(String dob, String asOf) => AgeCalculator.calculate(
      dateOfBirth: DateTime.parse(dob),
      asOf: DateTime.parse(asOf),
    );

void main() {
  test('ordinary date', () {
    final a = age('2020-01-15', '2026-09-28');
    expect([a.years, a.months, a.days], [6, 8, 13]);
  });

  test('31 Jan to 1 Mar never gives negative days', () {
    final a = age('2020-01-31', '2020-03-01');
    expect([a.years, a.months, a.days], [0, 1, 1]);
  });

  test('31 Mar to 30 Apr is a full month (matters for the 5y1m ECE rule)', () {
    final a = age('2021-03-31', '2026-04-30');
    expect([a.years, a.months, a.days], [5, 1, 0]);
    expect(
      AgeCalculator.isAtLeastMonths(
        dateOfBirth: DateTime(2021, 3, 31),
        asOf: DateTime(2026, 4, 30),
        minMonths: 61,
      ),
      isTrue,
    );
  });

  test('leap-day birthday', () {
    final a = age('2020-02-29', '2021-02-28');
    expect([a.years, a.months, a.days], [1, 0, 0]);
    final b = age('2020-02-29', '2021-03-01');
    expect([b.years, b.months, b.days], [1, 0, 1]);
  });

  test('exact birthday and same day', () {
    final a = age('2021-05-10', '2026-05-10');
    expect([a.years, a.months, a.days], [5, 0, 0]);
    final b = age('2021-05-10', '2021-05-10');
    expect([b.years, b.months, b.days], [0, 0, 0]);
  });

  test('day just before a month anniversary', () {
    final a = age('2021-04-15', '2026-05-14');
    expect([a.years, a.months, a.days], [5, 0, 29]);
  });

  test('date before birth throws', () {
    expect(() => age('2021-05-10', '2021-05-09'), throwsArgumentError);
  });

  test('isAtLeastMonths threshold', () {
    expect(
      AgeCalculator.isAtLeastMonths(
        dateOfBirth: DateTime(2021, 4, 1), asOf: DateTime(2026, 4, 30), minMonths: 61),
      isFalse,
    );
    expect(
      AgeCalculator.isAtLeastMonths(
        dateOfBirth: DateTime(2021, 4, 1), asOf: DateTime(2026, 5, 1), minMonths: 61),
      isTrue,
    );
  });
}
