import 'package:bus_schedule/entities/time.dart';
import 'package:bus_schedule/utils/weekday.dart';
import 'package:flutter/material.dart';

import '../entities/bus.dart';

// ignore: must_be_immutable
class BusSchedule extends StatefulWidget {
  BusSchedule(
      {super.key,
      required this.busList,
      required this.time,
      required this.weekday});

  List<Bus> busList;
  int weekday;
  Time time;

  @override
  State<BusSchedule> createState() => _BusScheduleState();
}

class _BusScheduleState extends State<BusSchedule> {
  late Time time = widget.time;
  late int weekday = widget.weekday;

  late List<int> shownBuses = [];

  @override
  void initState() {
    super.initState();
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
    return SingleChildScrollView(
      child: ExpansionPanelList(
        expansionCallback: (int index, bool isExpanded) {
          setState(() {
            var busNumber = widget.busList[index].number;
            toggleShownBuses(busNumber);
          });
        },
        children: List.generate(widget.busList.length, (i) {
          var busNumber = widget.busList[i].number;

          return ExpansionPanel(
            canTapOnHeader: true,
            isExpanded: shownBuses.contains(widget.busList[i].number),
            headerBuilder: (context, isExpanded) {
              return ListTile(
                title: Text(
                  busNumber.toString(),
                  style: TextStyle(
                      color: isExpanded
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black,
                      fontWeight:
                          isExpanded ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 28),
                ),
              );
            },
            body: Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: ListView.builder(
                  physics: const ClampingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: widget.busList[i].stops.length,
                  itemBuilder: ((BuildContext context, int j) {
                    var stop = widget.busList[i].stops[j];

                    return Column(
                      children: [
                        SizedBox(
                          height: 25,
                          child: ListTile(
                            leading: Text(
                              '${stop.name} st.',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 12.0, bottom: 12.0),
                          child: ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: stop.routes.length,
                            itemBuilder: ((BuildContext context, int k) {
                              var route = stop.routes[k];

                              var earliestArrivalTimes =
                                  getEarliestBusArrivalTimes(route.schedule);

                              var timeTable =
                                  displayTimetable(earliestArrivalTimes);

                              return SizedBox(
                                height: 40,
                                child: ListTile(
                                  title: Text('${route.start} - ${route.end}'),
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
  }

  List<String> getEarliestBusArrivalTimes(Schedule schedule) {
    List<String> timeTable = getTimetable(schedule, weekday);

    for (var i = 0; i < timeTable.length; i++) {
      var hourMinute = splitDate(timeTable[i]);
      bool isLastItem = i == timeTable.length - 1;

      bool haveNoArrivalsThisHour = hourMinute['hour']! > time.currHour;

      bool isEarliestArrivalTime = hourMinute['hour'] == time.currHour &&
          hourMinute['minute']! > time.currMinute;

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
