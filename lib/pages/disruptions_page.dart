import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class DisruptionsPage extends StatefulWidget {
  const DisruptionsPage({super.key});

  @override
  State<DisruptionsPage> createState() => _DisruptionsPageState();
}

class _DisruptionsPageState extends State<DisruptionsPage> {
  List<Map<String, dynamic>> _disruptions = [];
  List<Map<String, dynamic>> _filteredDisruptions = [];
  bool _isLoading = false;

  DateTime? _startDate;
  DateTime? _endDate;

  String? _selectedTag;

  bool _isDescending = true; // Indique si le tri est descendant (plus récent > plus ancien)

  @override
  void initState() {
    super.initState();
    fetchDisruptions();
  }

  Future<void> fetchDisruptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://prim.iledefrance-mobilites.fr/marketplace/disruptions_bulk/disruptions/v2'),
        headers: {
          'Accept': 'application/json',
          'apiKey': 'PcleZY8onhLZfmcss1Z0nQqhlHhsym1W',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final disruptions = data['disruptions'] ?? [];
        setState(() {
          _disruptions = List<Map<String, dynamic>>.from(disruptions);
          _filteredDisruptions = _disruptions;
          if (_disruptions.isNotEmpty) {
            _initializeDateRange();
          }
        });
      } else {
        print('Failed to load disruptions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeDateRange() {
    final validDates = _disruptions
        .map((disruption) {
          try {
            return DateTime.parse(disruption['lastUpdate']);
          } catch (e) {
            return null;
          }
        })
        .where((date) => date != null)
        .cast<DateTime>()
        .toList();

    if (validDates.isEmpty) return;

    validDates.sort();
    setState(() {
      _startDate = validDates.first;
      _endDate = validDates.last;
    });
  }

  void _applyDateFilter() {
    setState(() {
      _filteredDisruptions = _disruptions.where((disruption) {
        try {
          final disruptionDate = DateTime.parse(disruption['lastUpdate']);
          return (_startDate == null || disruptionDate.isAfter(_startDate!)) && (_endDate == null || disruptionDate.isBefore(_endDate!));
        } catch (e) {
          return false;
        }
      }).toList();
    });
  }

  void _filterByTag(String tag) {
    setState(() {
      _selectedTag = tag;
      _filteredDisruptions = _disruptions.where((disruption) {
        final tags = disruption['tags'] as List<dynamic>? ?? [];
        return tags.contains(tag);
      }).toList();
    });
  }

  void _resetTagFilter() {
    setState(() {
      _selectedTag = null;
      _filteredDisruptions = _disruptions;
    });
  }

  void _sortDisruptionsByDate() {
    setState(() {
      _isDescending = !_isDescending; // Inverse l'état de tri

      // Trie la liste des perturbations filtrées
      _filteredDisruptions.sort((a, b) {
        final dateA = DateTime.tryParse(a['lastUpdate'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['lastUpdate'] ?? '') ?? DateTime.now();

        return _isDescending ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perturbations'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_startDate != null && _endDate != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _startDate!,
                              firstDate: _startDate!,
                              lastDate: _endDate!,
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _startDate = pickedDate;
                                _applyDateFilter();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                          child: Text(
                            'Début : ${formatDate(_startDate!)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _endDate!,
                              firstDate: _startDate!,
                              lastDate: _endDate!,
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _endDate = pickedDate;
                                _applyDateFilter();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                          child: Text(
                            'Fin : ${formatDate(_endDate!)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_selectedTag != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: _resetTagFilter,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text(
                        'Réinitialiser le filtre par tag',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                // Ajout du bouton de tri
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: _sortDisruptionsByDate,
                    icon: Icon(_isDescending ? Icons.arrow_downward : Icons.arrow_upward), // Icône selon l'ordre de tri
                    label: Text(_isDescending ? 'Plus récentes -> Plus anciennes' : 'Plus anciennes -> Plus récentes'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  ),
                ),
                Expanded(
                  child: _filteredDisruptions.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucune perturbation signalée pour cette période.',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredDisruptions.length,
                          padding: const EdgeInsets.all(8.0),
                          itemBuilder: (context, index) {
                            final disruption = _filteredDisruptions[index];
                            final periods = disruption['applicationPeriods'] as List<dynamic>?;

                            final periodTexts = periods != null
                                ? periods.map((period) {
                                    final begin = formatDateTime(period['begin']);
                                    final end = formatDateTime(period['end']);
                                    return 'Du $begin au $end';
                                  }).join('\n')
                                : 'Non spécifié';

                            final message = stripHtml(disruption['message'] ?? '');
                            final linkRegex = RegExp(r'href="([^"]+)"');
                            final linkMatch = linkRegex.firstMatch(disruption['message'] ?? '');
                            final link = linkMatch?.group(1);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              color: const Color(0xFF2E2C4D),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      disruption['title'] ?? 'Titre non disponible',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Description : $message',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Impact : ${disruption['severity'] ?? 'Non spécifié'}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Périodes :\n$periodTexts',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 8.0),
                                    if (disruption['tags'] != null)
                                      Wrap(
                                        spacing: 8.0,
                                        children: disruption['tags']
                                            .map<Widget>((tag) => GestureDetector(
                                                  onTap: () => _filterByTag(tag),
                                                  child: Chip(
                                                    label: Text(tag),
                                                    backgroundColor: Colors.blue,
                                                    labelStyle: const TextStyle(color: Colors.white),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    const SizedBox(height: 8.0),
                                    if (link != null)
                                      InkWell(
                                        onTap: () async {
                                          final uri = Uri.tryParse(link);
                                          if (uri != null) {
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                                            } else {
                                              print('Impossible d\'ouvrir le lien : $uri');
                                            }
                                          }
                                        },
                                        child: Text(
                                          'Lien : Plus d\'informations',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                  ],
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

  String stripHtml(String input) {
    final exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    final cleaned = input.replaceAll(exp, '').trim();
    return cleaned.replaceAll('&nbsp;', ' ').replaceAll('&amp;', ' ').replaceAll('&quot;', ' ').replaceAll('&lt;', ' ').replaceAll('&gt;', ' ');
  }

  String formatDateTime(String dateTime) {
    try {
      final parsed = DateTime.parse(dateTime.replaceFirst('T', ' '));
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Non spécifié';
    }
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}
