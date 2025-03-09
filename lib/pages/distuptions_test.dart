import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:navigoon/services/notification_service.dart';

Future<void> fetchAndNotifyDisruptions() async {
  final notificationService = NotificationService();

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

      for (var disruption in disruptions) {
        await notificationService.showNotification(
          disruption['title'] ?? 'Perturbation',
          disruption['message'] ?? '',
        );
      }
    } else {
      print('Failed to load disruptions: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
