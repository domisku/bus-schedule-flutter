import 'package:bus_schedule/utils/weekday.dart';
import 'package:bus_schedule/widgets/bus_schedule.dart';
import 'package:flutter/material.dart';

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
  late TabController tabController;
  late DateTime date;
  late int currHour;
  late int currMinute;
  late int weekday;

  @override
  void initState() {
    super.initState();
    setCurrentTime();
    var initialIndex = getInitialTabIndex();
    tabController =
        TabController(length: 3, vsync: this, initialIndex: initialIndex);
  }

  void setCurrentTime() {
    date = DateTime.now();
    currHour = date.hour;
    currMinute = date.minute;
    weekday = date.weekday;
  }

  int getInitialTabIndex() {
    if (isWorkDay(weekday)) {
      return 0;
    } else if (isSaturday(weekday)) {
      return 1;
    } else if (isSunday(weekday)) {
      return 2;
    }

    throw 'Could not find schedule for this day of the week';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
      body: TabBarView(
        controller: tabController,
        children: const <Widget>[
          BusSchedule(),
          BusSchedule(),
          BusSchedule(),
        ],
      ),
    );
  }
}

//  floatingActionButton: FloatingActionButton(
//           onPressed: syncData, child: const Icon(Icons.sync)),
//     );
