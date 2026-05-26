package com.aurcm.route.data.remote

import android.util.Log
import com.aurcm.route.data.models.LocationUpdate
import com.aurcm.route.data.models.ServerResponse
import com.google.gson.Gson
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class WebSocketManager(private val onMessageReceived: (ServerResponse) -> Unit) {

    private var webSocket: WebSocket? = null
    private val gson = Gson()

    fun connect() {
        val client = OkHttpClient.Builder()
            .readTimeout(0, TimeUnit.MILLISECONDS)
            .build()

        val request = Request.Builder()
            .url(ApiClient.WS_URL)
            .header("Bypass-Tunnel-Reminder", "true")
            .build()

        webSocket = client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                Log.d("WebSocket", "Connected")
                // Tell server we are a student tracking app
                val msg = JSONObject().apply { put("type", "student:subscribe") }
                webSocket.send(msg.toString())
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                try {
                    val response = gson.fromJson(text, ServerResponse::class.java)
                    onMessageReceived(response)
                } catch (e: Exception) {
                    Log.e("WebSocket", "Error parsing message: $text", e)
                }
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                Log.d("WebSocket", "Closed: $reason")
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                Log.e("WebSocket", "Failure", t)
            }
        })
    }

    fun sendLocation(location: LocationUpdate) {
        webSocket?.send(gson.toJson(location))
    }

    fun startCaptain(busId: String, pin: String, routeId: String) {
        val msg = JSONObject().apply {
            put("type", "captain:start")
            put("busId", busId)
            put("pin", pin)
            put("routeId", routeId)
        }
        webSocket?.send(msg.toString())
    }

    fun stopCaptain() {
        val msg = JSONObject().apply { put("type", "captain:stop") }
        webSocket?.send(msg.toString())
    }

    fun disconnect() {
        webSocket?.close(1000, "User disconnected")
        webSocket = null
    }
}
