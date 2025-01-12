package com.laxyny.navigoon

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class TrainWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val views = RemoteViews(context.packageName, R.layout.widget_train)

        // Charger les données sauvegardées
        val sharedPreferences = HomeWidgetPlugin.getData(context)
        val destination = sharedPreferences.getString("destination", "Inconnu") ?: "Inconnu"
        val expectedTime = sharedPreferences.getString("expectedTime", "Inconnu") ?: "Inconnu"

        views.setTextViewText(R.id.destinationText, "Destination : $destination")
        views.setTextViewText(R.id.expectedTimeText, "Heure : $expectedTime")

        // Intent pour ouvrir l'application
        val intent = Intent(context, MainActivity::class.java).apply {
            putExtra("route", "/selectTrain")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetIds, views)
    }
}
