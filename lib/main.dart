import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trains en temps réel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Trains en temps réel'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Fonctions de formatage
String formatTime(String time) {
  try {
    final dateTime = DateTime.parse(time).toLocal();
    return DateFormat('HH:mm').format(dateTime);
  } catch (e) {
    return "Inconnu";
  }
}

bool isFutureTrain(String time) {
  try {
    final trainTime = DateTime.parse(time).toLocal();
    final now = DateTime.now();
    return trainTime.isAfter(now);
  } catch (e) {
    return false;
  }
}

bool isTrainWithinRange(String time, Duration range) {
  try {
    final trainTime = DateTime.parse(time).toLocal();
    final now = DateTime.now();
    final limit = now.add(range);
    return trainTime.isAfter(now) && trainTime.isBefore(limit);
  } catch (e) {
    return false;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> _trains = [];
  bool _isLoading = false;
  Timer? _updateTimer;

  // Liste des stations et des lignes
  final List<String> stations = ["Auber", "Châtelet", "La Défense", "Cergy le Haut", "Poissy", "Saint-Germain-en-Laye"];
  String selectedDepartureStation = "Auber";
  String? selectedArrivalStation;
  final String selectedLine = "RER A";

  Future<void> fetchTrains() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://prim.iledefrance-mobilites.fr/marketplace/stop-monitoring?MonitoringRef=STIF%3AStopPoint%3AQ%3A473921%3A&LineRef=STIF%3ALine%3A%3AC01742%3A'),
        headers: {
          'Accept': 'application/json',
          'apiKey': 'PcleZY8onhLZfmcss1Z0nQqhlHhsym1W',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stopMonitoringDelivery = data['Siri']['ServiceDelivery']['StopMonitoringDelivery'];
        if (stopMonitoringDelivery != null && stopMonitoringDelivery.isNotEmpty) {
          final monitoredStopVisits = stopMonitoringDelivery[0]['MonitoredStopVisit'];
          if (monitoredStopVisits != null) {
            setState(() {
              _trains = monitoredStopVisits
                  .map<Map<String, dynamic>>((visit) {
                    final journey = visit['MonitoredVehicleJourney'];
                    if (journey != null) {
                      final destinationName = journey['DestinationName']?[0]?['value']?.toString() ?? 'Inconnu';
                      final expectedTime = journey['MonitoredCall']?['ExpectedDepartureTime']?.toString() ?? 'Inconnu';

                      return {
                        'destination': destinationName,
                        'expectedTime': expectedTime,
                      };
                    }
                    return {
                      'destination': 'Train inconnu',
                      'expectedTime': 'Inconnu',
                    };
                  })
                  .where((train) => isTrainWithinRange(train['expectedTime'] ?? '', const Duration(hours: 1, minutes: 30)))
                  .toList();
            });
          } else {
            print('No departures found');
          }
        } else {
          print('No StopMonitoringDelivery found');
        }
      } else {
        print('Failed to load trains: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTrains();
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchTrains();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: selectedDepartureStation,
                  items: stations.map((station) {
                    return DropdownMenuItem(
                      value: station,
                      child: Text(station),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDepartureStation = value!;
                      fetchTrains();
                    });
                  },
                ),
                DropdownButton<String>(
                  value: selectedArrivalStation,
                  hint: const Text("Choisir une station d'arrivée"),
                  items: stations.map((station) {
                    return DropdownMenuItem(
                      value: station,
                      child: Text(station),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedArrivalStation = value;
                      fetchTrains();
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Résultats: ${_trains.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _trains.isEmpty
                    ? const Center(child: Text('Aucun train disponible.'))
                    : ListView.builder(
                        itemCount: _trains.length,
                        itemBuilder: (context, index) {
                          final train = _trains[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                            child: ListTile(
                              leading: Icon(Icons.train, color: Colors.deepPurple),
                              title: Text(
                                'Destination : ${train['destination']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Heure : ${formatTime(train['expectedTime'])}',
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
