import '../roommate/utils/money_utils.dart';

class Formatters {
  Formatters._();

  static String currency(num value) {
    return MoneyUtils.formatCents(MoneyUtils.toCents(value));
  }
}
