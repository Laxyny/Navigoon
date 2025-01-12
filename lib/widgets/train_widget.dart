import 'package:home_widget/home_widget.dart';
import 'dart:async';

class TrainWidgetManager {
  // Met à jour les données du widget d'accueil avec les informations du prochain train
  static Future<void> updateTrainWidget(String destination, String expectedTime) async {
    await HomeWidget.saveWidgetData<String>('destination', destination);
    await HomeWidget.saveWidgetData<String>('expectedTime', expectedTime);
    await HomeWidget.updateWidget(
      name: 'TrainWidgetProvider',
      iOSName: 'TrainWidget',
    );
  }
}
