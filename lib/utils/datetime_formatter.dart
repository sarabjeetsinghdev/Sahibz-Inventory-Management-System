import 'package:intl/intl.dart';

enum DateTimeParserEnum {
  wcdmyt12('EEEE, dd/MM/yyyy hh:mm a'),
  wcdmyt24('EEEE, dd/MM/yyyy HH:mm a'),
  dmyt12('dd/MM/yyyy hh:mm a'),
  dmyt24('dd/MM/yyyy HH:mm a'),
  mdyt12('MM/dd/yyyy hh:mm a'),
  mdyt24('MM/dd/yyyy HH:mm a'),
  ymdt12('yyyy/MM/dd hh:mm a'),
  ymdt24('yyyy/MM/dd HH:mm a');

  const DateTimeParserEnum(this.value);
  final String value;
}

DateTimeParserEnum? getDateTimeParserEnum(String value) {
  for (DateTimeParserEnum enumItem in DateTimeParserEnum.values) {
    if (enumItem.value == value) {
      return enumItem;
    }
  }
  return null;
}

List<String> getDateTimeParserList() {
  return DateTimeParserEnum.values.map((e) => e.value).toList();
}

String convertDateTimeString2Formatted(DateTime dateTime, DateTimeParserEnum parser) {
  String parsed = DateFormat(parser.value).format(dateTime);
  return parsed;
}

