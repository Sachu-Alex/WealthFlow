import 'package:intl/intl.dart';

final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _currencyDecFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final _dateFmt = DateFormat('dd MMM yyyy');
final _shortDateFmt = DateFormat('dd MMM');
final _monthYearFmt = DateFormat('MMM yyyy');
final _monthShortFmt = DateFormat('MMM');

String formatCurrency(double amount) => _currencyFmt.format(amount);
String formatCurrencyDec(double amount) => _currencyDecFmt.format(amount);
String formatDate(DateTime date) => _dateFmt.format(date);
String formatShortDate(DateTime date) => _shortDateFmt.format(date);
String formatMonthYear(DateTime date) => _monthYearFmt.format(date);
String formatMonthShort(DateTime date) => _monthShortFmt.format(date);
String formatPercent(double value) => '${value.toStringAsFixed(2)}%';

String formatCompactCurrency(double amount) {
  if (amount >= 10000000) {
    return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
  } else if (amount >= 100000) {
    return '₹${(amount / 100000).toStringAsFixed(2)}L';
  } else if (amount >= 1000) {
    return '₹${(amount / 1000).toStringAsFixed(1)}K';
  }
  return formatCurrency(amount);
}
