import 'package:intl/intl.dart';

class MoneyUtils {
  MoneyUtils._();

  static final NumberFormat _phpWhole = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 0,
  );
  static final NumberFormat _phpWithDecimal = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  static int toCents(num amount) => (amount * 100).round();

  static double toMajor(int cents) => cents / 100.0;

  static String formatCents(int cents) {
    if (cents % 100 == 0) {
      return _phpWhole.format(cents / 100);
    }
    return _phpWithDecimal.format(cents / 100);
  }
}
