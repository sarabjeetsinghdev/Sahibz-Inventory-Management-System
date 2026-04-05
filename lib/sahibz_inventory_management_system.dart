extension StringExtension on String {
  /// Capitalizes the first letter of the string.
  String capitalizeFirstLetter() {
    final firstletter = this[0];
    final rest = substring(1);
    return firstletter.toUpperCase() + rest;
  }

  // customize header table titles
  String customizeHeaderTableTitles() {
    String title = capitalizeFirstLetter();
    title = title
        .split(' ')
        .map((ele) => ele.capitalizeFirstLetter())
        .toList()
        .join(' ');
    if (title.contains('_')) {
      title = title
          .split('_')
          .map((ele) => ele.capitalizeFirstLetter())
          .toList()
          .join(' ');
    }
    return title;
  }
}
