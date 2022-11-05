bool isWorkDay(int weekday) {
  return weekday >= 1 && weekday <= 5 ? true : false;
}

bool isSaturday(int weekday) {
  return weekday == 6 ? true : false;
}

bool isSunday(int weekday) {
  return weekday == 7 ? true : false;
}
