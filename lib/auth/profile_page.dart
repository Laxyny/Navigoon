import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Aucun utilisateur connecté.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                            child: user.photoURL == null ? const Icon(Icons.person, size: 50) : null,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            user.email ?? "Google User",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildApiUsageCard(user.uid),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        await GoogleSignIn().signOut();
                        Navigator.pop(context);
                      },
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildApiUsageCard(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final usage = data['apiUsage'] ?? 0;
        final limit = data['apiLimit'] ?? 1000000;
        final percentage = (usage / limit).clamp(0.0, 1.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular progress indicator
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: percentage),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey[300],
                          color: Colors.deepPurple,
                        );
                      },
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Text(
                        '$usage / $limit',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const Text(
                        'Utilisé',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Consommation API hebdomadaire :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: (limit / 7).ceilToDouble(),
                  barGroups: _generateBarGroups(data),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text('${value.toInt()}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(days[value.toInt() % days.length], style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    drawHorizontalLine: true,
                    horizontalInterval: (limit / 28).ceilToDouble(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<BarChartGroupData> _generateBarGroups(Map<String, dynamic> data) {
    final dailyUsage = data['dailyUsage'] as Map<String, dynamic>? ?? {};
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(7, (index) {
      final day = days[index];
      final usage = dailyUsage[day] ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: usage.toDouble(),
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.withOpacity(0.7),
                Colors.deepPurple,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            width: 16,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      );
    });
  }
}
