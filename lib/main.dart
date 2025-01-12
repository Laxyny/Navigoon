import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:navigoon/api/api_usage_service.dart';
import 'package:navigoon/auth/auth_page.dart';
import 'package:navigoon/auth/login_page.dart';
import 'package:navigoon/auth/profile_page.dart';
import 'package:navigoon/pages/disruptions_page.dart';
import 'package:navigoon/pages/select_train_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trains en temps réel',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF1D1D35),
      ),
      home: const MyHomePage(title: 'Trains en temps réel'),
      routes: {
        '/auth': (context) => const AuthPage(),
        '/login': (context) => const LoginPage(),
        '/profile': (context) => const ProfilePage(),
        '/selectTrain': (context) => SelectTrainPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> _trains = [];
  bool _isLoading = false;
  Timer? _updateTimer;
  User? _currentUser;

  final List<String> stations = ["Auber", "Châtelet", "La Défense", "Cergy le Haut", "Poissy", "Saint-Germain-en-Laye"];
  String selectedDepartureStation = "Auber";
  String? selectedArrivalStation;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _currentUser = user;
      });
    });
    fetchTrains();
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchTrains();
    });
    _checkCurrentUser();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> updateApiUsage(int requestsMade) async {
    if (_currentUser != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
      final userId = _currentUser!.uid;
      final apiService = ApiUsageService(userId);

      await apiService.updateDailyUsage(requestsMade);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);

        if (!snapshot.exists) {
          transaction.set(userDoc, {
            'apiUsage': 0,
            'apiLimit': 10000,
          });
        } else {
          final currentUsage = snapshot['apiUsage'] ?? 0;
          transaction.update(userDoc, {'apiUsage': currentUsage + requestsMade});
        }
      });
    }
  }

  Future<void> _checkCurrentUser() async {
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
    });
  }

  Future<void> updateHomeScreenWidget(String destination, String expectedTime) async {
    await HomeWidget.saveWidgetData<String>('destination', destination);
    await HomeWidget.saveWidgetData<String>('expectedTime', expectedTime);

    // Demandez au widget de se mettre à jour
    await HomeWidget.updateWidget(
      name: 'TrainWidgetProvider',
      iOSName: 'TrainWidget',
    );
  }

  Future<void> fetchTrains() async {
    if (_currentUser != null) {
      await updateApiUsage(1);
    }

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
            final List<Map<String, dynamic>> trains = monitoredStopVisits.map<Map<String, dynamic>>((visit) {
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
            }).toList();

            // Filtrer les trains pour ne garder que le prochain
            final now = DateTime.now();
            final nextTrain = trains.firstWhere(
              (train) {
                try {
                  final trainTime = DateTime.parse(train['expectedTime']).toLocal();
                  return trainTime.isAfter(now);
                } catch (e) {
                  return false;
                }
              },
              orElse: () => {'destination': 'Aucun train', 'expectedTime': 'Inconnu'},
            );

            // Sauvegarder le train le plus proche dans le widget
            updateHomeScreenWidget(nextTrain['destination'], formatTime(nextTrain['expectedTime']));

            setState(() {
              _trains = trains;
            });
          }
        }
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: _currentUser == null ? const Icon(Icons.login) : const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, _currentUser == null ? '/auth' : '/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh), // Bouton pour rafraîchir
            tooltip: 'Rafraîchir la liste des trains',
            onPressed: () {
              fetchTrains(); // Appelle la fonction pour rafraîchir manuellement
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _trains.length,
                    itemBuilder: (context, index) {
                      final train = _trains[index];
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        color: const Color(0xFF2E2C4D),
                        child: ListTile(
                          leading: const Icon(Icons.train, color: Colors.white),
                          title: Text(
                            'Destination : ${train['destination']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Heure : ${formatTime(train['expectedTime'])}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child:
            //Aficher une icone au centre
            Icon(Icons.warning_amber, color: Colors.white),
        onPressed: () {
          // Naviguer vers la page des disruptions
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DisruptionsPage()),
          );
        },
      ),
    );
  }
}

String formatTime(String time) {
  try {
    final dateTime = DateTime.parse(time).toLocal();
    return DateFormat('HH:mm').format(dateTime);
  } catch (e) {
    return "Inconnu";
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
