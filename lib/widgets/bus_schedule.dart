import 'dart:convert';

import 'package:bus_schedule/utils/weekday.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../entities/bus.dart';

class BusSchedule extends StatefulWidget {
  const BusSchedule({super.key});

  @override
  State<BusSchedule> createState() => _BusScheduleState();
}

class _BusScheduleState extends State<BusSchedule> {
  late Future<BusList?> busList = Future.value(null);
  late DateTime date;
  late int currHour;
  late int currMinute;
  late int weekday;

  late List<int> shownBuses = [];

  @override
  void initState() {
    super.initState();
    syncData();
  }

  void toggleShownBuses(int busNumber) {
    if (shownBuses.contains(busNumber)) {
      setState(() => shownBuses.remove(busNumber));
    } else {
      setState(() => shownBuses.add(busNumber));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BusList?>(
      future: busList,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          final busList = snapshot.data!.busList;

          return SingleChildScrollView(
            child: ExpansionPanelList(
              expansionCallback: (int index, bool isExpanded) {
                setState(() {
                  var busNumber = busList[index].number;
                  toggleShownBuses(busNumber);
                });
              },
              children: List.generate(busList.length, (i) {
                var busNumber = busList[i].number;

                return ExpansionPanel(
                  isExpanded: shownBuses.contains(busList[i].number),
                  headerBuilder: (context, isExpanded) {
                    return ListTile(
                      title: Text(
                        busNumber.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 28),
                      ),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: busList[i].stops.length,
                        itemBuilder: ((BuildContext context, int j) {
                          var stop = busList[i].stops[j];

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${stop.name} st.',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 12.0, bottom: 12.0),
                                child: ListView.builder(
                                  physics: const ClampingScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: stop.routes.length,
                                  itemBuilder: ((BuildContext context, int k) {
                                    var route = stop.routes[k];

                                    var earliestArrivalTimes =
                                        getEarliestBusArrivalTimes(
                                            route.schedule);

                                    var timeTable =
                                        displayTimetable(earliestArrivalTimes);

                                    return Card(
                                      child: ListTile(
                                        title: Text(
                                            '${route.start} - ${route.end}'),
                                        trailing: timeTable.isEmpty
                                            ? const Icon(Icons.block,
                                                color: Colors.black)
                                            : Text(timeTable,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 16)),
                                      ),
                                    );
                                  }),
                                ),
                              )
                            ],
                          );
                        })),
                  ),
                );
              }),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }

        return const Center(child: Text('Something went wrong'));
      },
    );
  }

  void syncData() {
    setState(() {
      setCurrentTime();
      busList = fetchSchedule();
    });
  }

  void setCurrentTime() {
    date = DateTime.now();
    currHour = date.hour;
    currMinute = date.minute;
    weekday = date.weekday;
  }

  List<String> getEarliestBusArrivalTimes(Schedule schedule) {
    List<String> timeTable = getTimetable(schedule, weekday);

    for (var i = 0; i < timeTable.length; i++) {
      var time = splitDate(timeTable[i]);
      bool isLastItem = i == timeTable.length - 1;

      bool haveNoArrivalsThisHour = time['hour']! > currHour;

      bool isEarliestArrivalTime =
          time['hour'] == currHour && time['minute']! > currMinute;

      if (isEarliestArrivalTime || haveNoArrivalsThisHour) {
        return isLastItem ? [timeTable[i]] : [timeTable[i], timeTable[i + 1]];
      }
    }

    return [];
  }

  Map<String, int> splitDate(String date) {
    var split = date.split(':');

    return {'hour': int.parse(split[0]), 'minute': int.parse(split[1])};
  }

  Future<BusList> fetchSchedule() async {
    final response = await http.get(Uri.parse(
        'https://bus-schedule-367109-default-rtdb.europe-west1.firebasedatabase.app/buses.json'));

    if (response.statusCode == 200) {
      return BusList.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load bus schedule');
    }
  }
}

List<String> getTimetable(Schedule schedule, int weekday) {
  if (isWorkDay(weekday)) {
    return schedule.workday;
  } else if (isSaturday(weekday)) {
    return schedule.saturday;
  } else if (isSunday(weekday)) {
    return schedule.sunday;
  }

  throw 'Could not find schedule for this day of the week';
}

String displayTimetable(List<String> timeTable) {
  if (timeTable.isEmpty) {
    return '';
  }

  return timeTable.reduce((value, element) => '$value  $element');
}
