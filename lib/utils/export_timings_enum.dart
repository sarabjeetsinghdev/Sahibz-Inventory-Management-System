enum ExportTimingsEnum {
  today('Today'),
  yesterday('Yesterday'),
  thisWeek('This Week'),
  thisBiMonth('This Half Month (15 days)'),
  thisMonth('This Month'),
  thisQuarter('This Quarter'),
  thisSixMonths('This Six Months'),
  thisYear('This Year'),
  allTime('All Time');

  const ExportTimingsEnum(this.displayName);
  final String displayName;
}
