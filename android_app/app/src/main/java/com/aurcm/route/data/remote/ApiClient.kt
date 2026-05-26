package com.aurcm.route.data.remote

import android.util.Log
import com.aurcm.route.data.models.RoutesResponse
import com.aurcm.route.data.models.Route
import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request

object ApiClient {
    // Using localtunnel to expose the local server to the public internet for long-distance testing over 4G/5G
    const val BASE_URL = "https://aurcm-backend.onrender.com"
    const val WS_URL = "wss://aurcm-backend.onrender.com"

    private val client = OkHttpClient()
    private val gson = Gson()

    suspend fun getRoutes(): List<Route> = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url("$BASE_URL/api/routes")
                .header("Bypass-Tunnel-Reminder", "true")
                .build()

            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) throw Exception("Unexpected code $response")

                val bodyStr = response.body?.string() ?: return@use emptyList<Route>()
                val result = gson.fromJson(bodyStr, RoutesResponse::class.java)
                result.routes
            }
        } catch (e: Exception) {
            Log.e("ApiClient", "Error fetching routes", e)
            emptyList()
        }
    }

    suspend fun getRouteDetail(routeId: String): Route? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url("$BASE_URL/api/routes/$routeId")
                .header("Bypass-Tunnel-Reminder", "true")
                .build()

            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) return@use null
                
                val bodyStr = response.body?.string() ?: return@use null
                gson.fromJson(bodyStr, Route::class.java)
            }
        } catch (e: Exception) {
            Log.e("ApiClient", "Error fetching route detail", e)
            null
        }
    }

    suspend fun getThingSpeakLocation(channelId: String): com.aurcm.route.data.models.ThingSpeakResponse? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                // Append the Read API Key to access the private channel
                .url("https://api.thingspeak.com/channels/$channelId/feeds/last.json?api_key=C5IT5RBI786MNFFG")
                .build()

            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) return@use null
                
                val bodyStr = response.body?.string() ?: return@use null
                gson.fromJson(bodyStr, com.aurcm.route.data.models.ThingSpeakResponse::class.java)
            }
        } catch (e: Exception) {
            Log.e("ApiClient", "Error fetching ThingSpeak data", e)
            null
        }
    }
}
