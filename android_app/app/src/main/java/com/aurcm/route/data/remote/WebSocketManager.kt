package com.aurcm.route.data.remote

import android.util.Log
import com.aurcm.route.data.models.LocationUpdate
import com.aurcm.route.data.models.ServerResponse
import com.google.gson.Gson
import io.socket.client.IO
import io.socket.client.Socket
import org.json.JSONObject
import java.net.URISyntaxException

class WebSocketManager(private val onMessageReceived: (ServerResponse) -> Unit) {

    private var socket: Socket? = null
    private val gson = Gson()
    private var currentRouteId: String? = null

    fun connect(token: String) {
        try {
            val options = IO.Options()
            options.auth = mapOf("token" to token)
            
            socket = IO.socket(ApiClient.WS_URL, options)

            socket?.on(Socket.EVENT_CONNECT) {
                Log.d("SocketIO", "Connected")
            }

            socket?.on(Socket.EVENT_DISCONNECT) {
                Log.d("SocketIO", "Disconnected")
            }

            socket?.on("trip:started") { args ->
                // Acknowledgment that trip started
                val response = ServerResponse(type = "captain:ack")
                onMessageReceived(response)
            }

            socket?.on("connect_error") { args ->
                val error = if (args.isNotEmpty()) args[0].toString() else "Unknown Error"
                Log.e("SocketIO", "Connect error: $error")
                onMessageReceived(ServerResponse(type = "error", message = error))
            }

            socket?.connect()
        } catch (e: URISyntaxException) {
            Log.e("SocketIO", "URI error", e)
        }
    }

    fun sendLocation(location: LocationUpdate) {
        val json = JSONObject().apply {
            put("tripId", location.routeId ?: "") // Temporary usage of routeId as tripId placeholder
            put("busId", location.busId)
            put("routeId", currentRouteId)
            put("lat", location.lat)
            put("lng", location.lng)
            put("speed", location.speed)
            put("heading", location.heading)
            put("timestamp", location.timestamp)
        }
        socket?.emit("location:update", json)
    }

    fun startCaptain(busId: String, pin: String, routeId: String) {
        // Find route matching busId if possible? Actually the Kotlin app asks for busId and PIN.
        // We need the backend to emit `trip:start`.
        currentRouteId = routeId
        val tripId = "trip-${System.currentTimeMillis()}"
        
        val json = JSONObject().apply {
            put("tripId", tripId)
            put("busId", busId)
            put("routeId", routeId)
        }
        socket?.emit("trip:start", json)
    }

    fun stopCaptain() {
        val json = JSONObject().apply {
            put("type", "captain:stop")
        }
        socket?.emit("trip:end", json)
    }

    fun disconnect() {
        socket?.disconnect()
        socket = null
    }
}
