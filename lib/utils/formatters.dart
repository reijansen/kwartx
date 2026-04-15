import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _phpCurrency = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
  );

  static String currency(num value) => _phpCurrency.format(value);
}
