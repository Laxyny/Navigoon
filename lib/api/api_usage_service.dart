import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ApiUsageService {
  final String userId;

  ApiUsageService(this.userId);

  Future<void> updateDailyUsage(int increment) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    final today = DateFormat('EEEE').format(DateTime.now()).substring(0, 3); // "Mon", "Tue", etc.

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);

      if (!snapshot.exists) {
        // Création initiale avec les données nécessaires
        transaction.set(userDoc, {
          'dailyUsage': {today: increment + 1},
          'apiUsage': increment,
          'apiLimit': 5000, // Default limit
        });
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;

      // Si le champ dailyUsage n'existe pas, l'initialiser à un objet vide
      final dailyUsage = Map<String, dynamic>.from(data['dailyUsage'] ?? {});
      final apiUsage = data['apiUsage'] ?? 0;

      // Mise à jour de la consommation quotidienne
      dailyUsage[today] = (dailyUsage[today] ?? 0) + increment;

      transaction.update(userDoc, {
        'dailyUsage': dailyUsage,
        'apiUsage': apiUsage,
      });
    });
  }

  static Stream<Map<String, dynamic>> getDailyUsage(String userId) {
    return FirebaseFirestore.instance.collection('users').doc(userId).snapshots().map((snapshot) => snapshot.data() as Map<String, dynamic>);
  }
}
