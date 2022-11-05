class BusList {
  final List<Bus> busList;

  const BusList({required this.busList});

  factory BusList.fromJson(Map<String, dynamic> json) {
    String id = json.keys.first;

    var list = json[id] as List;
    List<Bus> busList = list.map((i) => Bus.fromJson(i)).toList();

    return BusList(busList: busList);
  }
}

class Bus {
  final int number;
  final List<Stop> stops;

  const Bus({required this.number, required this.stops});

  factory Bus.fromJson(Map<String, dynamic> json) {
    var list = json['stops'] as List;
    List<Stop> stops = list.map((i) => Stop.fromJson(i)).toList();

    return Bus(number: json['number'], stops: stops);
  }
}

class Stop {
  final String name;
  final List<Route> routes;

  const Stop({required this.name, required this.routes});

  factory Stop.fromJson(Map<String, dynamic> json) {
    var list = json['routes'] as List;
    List<Route> routes = list.map((i) => Route.fromJson(i)).toList();

    return Stop(name: json['name'], routes: routes);
  }
}

class Route {
  final String start;
  final String end;
  final Schedule schedule;

  const Route({required this.start, required this.end, required this.schedule});

  factory Route.fromJson(Map<String, dynamic> json) {
    Schedule schedule = Schedule.fromJson(json['schedule']);

    return Route(start: json['start'], end: json['end'], schedule: schedule);
  }
}

class Schedule {
  final List<String> workday;
  final List<String> saturday;
  final List<String> sunday;

  const Schedule(
      {required this.workday, required this.saturday, required this.sunday});

  factory Schedule.fromJson(Map<String, dynamic> json) {
    List<String> workday = List<String>.from(json['workday']);
    List<String> saturday = List<String>.from(json['saturday']);
    List<String> sunday = List<String>.from(json['sunday']);

    return Schedule(workday: workday, saturday: saturday, sunday: sunday);
  }
}
