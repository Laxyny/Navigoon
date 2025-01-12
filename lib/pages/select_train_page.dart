import 'package:flutter/material.dart';

class SelectTrainPage extends StatefulWidget {
  @override
  _SelectTrainPageState createState() => _SelectTrainPageState();
}

class _SelectTrainPageState extends State<SelectTrainPage> {
  String selectedLine = "Auber";
  String selectedDestination = "Saint-Germain-en-Laye";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Modifier le train"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: selectedLine,
              items: ["Auber", "Châtelet", "La Défense", "Cergy le Haut"]
                  .map((line) => DropdownMenuItem(
                        value: line,
                        child: Text(line),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedLine = value!;
                });
              },
            ),
            DropdownButton<String>(
              value: selectedDestination,
              items: ["Saint-Germain-en-Laye", "Poissy", "Cergy le Haut"]
                  .map((dest) => DropdownMenuItem(
                        value: dest,
                        child: Text(dest),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedDestination = value!;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Sauvegarder la ligne et la destination et mettre à jour le widget
                Navigator.pop(context);
              },
              child: Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }
}
