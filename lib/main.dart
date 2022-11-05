import 'dart:convert';

import 'package:bus_schedule/entities/time.dart';
import 'package:bus_schedule/utils/weekday.dart';
import 'package:bus_schedule/widgets/bus_schedule.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../entities/bus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Rush',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const TabViewPage(title: 'Bus Rush'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TabViewPage extends StatefulWidget {
  const TabViewPage({super.key, required this.title});

  final String title;

  @override
  State<TabViewPage> createState() => _TabViewPageState();
}

class _TabViewPageState extends State<TabViewPage>
    with TickerProviderStateMixin {
  late Future<BusList?> busList = Future.value(null);
  late TabController tabController;
  late Time time;
  late int weekday;
  TextEditingController timeInput = TextEditingController();
  final Uri stopsLtUri = Uri.parse('https://www.stops.lt/vilnius/#plan/');

  @override
  void initState() {
    super.initState();
    syncData();
    setCurrentTime();
    var initialIndex = getInitialTabIndex();
    tabController =
        TabController(length: 3, vsync: this, initialIndex: initialIndex);
  }

  void syncData() {
    setState(() {
      setCurrentTime();
      busList = fetchSchedule();
    });
  }

  void setCurrentTime() {
    var date = DateTime.now();

    weekday = date.weekday;
    time = Time(currHour: date.hour, currMinute: date.minute);
    timeInput.text = '${date.hour}:${date.minute}';
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

  int getInitialTabIndex() {
    if (isWorkDay(weekday)) {
      return 0;
    } else if (isSaturday(weekday)) {
      return 1;
    } else if (isSunday(weekday)) {
      return 2;
    }

    throw 'Could not determine the day of the week';
  }

  void updateTime(TimeOfDay pickedTime) {
    timeInput.text = '${pickedTime.hour}:${pickedTime.minute}';
    time = Time(currHour: pickedTime.hour, currMinute: pickedTime.minute);
    busList = fetchSchedule();
  }

  Future<void> openUrl() async {
    if (!await launchUrl(stopsLtUri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $stopsLtUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            padding: const EdgeInsets.only(right: 16.0),
            icon: const Icon(
              Icons.link,
            ),
            onPressed: openUrl,
          )
        ],
        bottom: TabBar(
          controller: tabController,
          tabs: const <Widget>[
            Tab(
              text: 'Workday',
            ),
            Tab(
              text: 'Saturday',
            ),
            Tab(
              text: 'Sunday',
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FutureBuilder<BusList?>(
            future: busList,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasData) {
                final busList = snapshot.data!.busList;

                return TabBarView(
                  controller: tabController,
                  children: <Widget>[
                    BusSchedule(busList: busList, time: time, weekday: 1),
                    BusSchedule(busList: busList, time: time, weekday: 6),
                    BusSchedule(busList: busList, time: time, weekday: 7),
                  ],
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
              }

              return const Center(child: Text('Something went wrong'));
            }),
      ),
      bottomSheet: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              spreadRadius: 0,
              blurRadius: 3,
              offset: Offset(0, 0),
            ),
          ],
        ),
        padding: const EdgeInsets.only(right: 16.0, left: 16.0),
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Center(
                child: TextField(
                  controller: timeInput,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.timer),
                      hintText: "Enter Time"),
                  readOnly: true,
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      initialTime: TimeOfDay.now(),
                      context: context,
                    );

                    if (pickedTime != null) {
                      setState(() => updateTime(pickedTime));
                    }
                  },
                ),
              ),
            ),
            IconButton(
              color: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.sync),
              tooltip: 'Sync Data',
              onPressed: syncData,
            ),
          ],
        ),
      ),
    );
  }
}
