package com.laxyny.navigoon

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class TrainWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val views = RemoteViews(context.packageName, R.layout.widget_train)

        // Charger les données sauvegardées via HomeWidget
        val sharedPreferences = HomeWidgetPlugin.getData(context) // Récupère les SharedPreferences

        val destination = sharedPreferences.getString("destination", "Inconnu") ?: "Inconnu"
        val expectedTime = sharedPreferences.getString("expectedTime", "Inconnu") ?: "Inconnu"

        // Mettre à jour l'interface utilisateur du widget
        views.setTextViewText(R.id.destinationText, "Destination : $destination")
        views.setTextViewText(R.id.expectedTimeText, "Heure : $expectedTime")

        appWidgetManager.updateAppWidget(appWidgetIds, views)
    }
}
