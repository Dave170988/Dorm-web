DateTime addMonths(DateTime dateTime, int numberOfMonths) {
  int newYear = dateTime.year;
  int newMonth = dateTime.month + numberOfMonths;

  // Adjust the year and month values appropriately.
  while (newMonth > 12) {
    newYear++;
    newMonth -= 12;
  }

  while (newMonth < 1) {
    newYear--;
    newMonth += 12;
  }

  // Calculate the last day of the new month to avoid overflow into the next month
  int newDay = dateTime.day;
  int lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;
  if (newDay > lastDayOfNewMonth) {
    newDay = lastDayOfNewMonth;
  }

  return DateTime(newYear, newMonth, newDay, dateTime.hour, dateTime.minute,
      dateTime.second, dateTime.millisecond, dateTime.microsecond);
}
