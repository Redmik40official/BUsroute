package com.aurcm.route

import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.aurcm.route.data.models.Route
import com.aurcm.route.data.remote.ApiClient
import com.aurcm.route.data.remote.WebSocketManager
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class LiveMapActivity : AppCompatActivity(), OnMapReadyCallback {

    private lateinit var ws: WebSocketManager
    private lateinit var routeId: String
    private var trackedBusId: String = ""
    private var currentRouteColor: Int = Color.BLUE

    private var googleMap: GoogleMap? = null
    private var busMarker: Marker? = null
    private var trailPolyline: Polyline? = null
    private var isFollowing = true
    private val trailPoints = mutableListOf<LatLng>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_live_map)

        routeId = intent.getStringExtra("routeId") ?: return finish()
        trackedBusId = intent.getStringExtra("busId") ?: ""
        val rName = intent.getStringExtra("routeName") ?: ""
        val rColor = intent.getStringExtra("routeColor") ?: "#3B82F6"
        currentRouteColor = try { Color.parseColor(rColor) } catch(e: Exception) { Color.BLUE }

        findViewById<TextView>(R.id.tvRouteName).text = rName
        findViewById<View>(R.id.btnBack).setOnClickListener { finish() }

        findViewById<View>(R.id.btnRecenter).setOnClickListener {
            isFollowing = true
            busMarker?.let {
                googleMap?.animateCamera(CameraUpdateFactory.newLatLngZoom(it.position, 16f))
            }
        }

        // Initialize Google Maps Fragment
        val mapFragment = supportFragmentManager.findFragmentById(R.id.mapFragment) as SupportMapFragment
        mapFragment.getMapAsync(this)
    }

    override fun onMapReady(map: GoogleMap) {
        googleMap = map
        
        // Setup Map style (Dark Mode)
        val styleJson = """
            [
              { "elementType": "geometry", "stylers": [{ "color": "#242f3e" }] },
              { "elementType": "labels.text.stroke", "stylers": [{ "color": "#242f3e" }] },
              { "elementType": "labels.text.fill", "stylers": [{ "color": "#746855" }] },
              {
                "featureType": "road",
                "elementType": "geometry",
                "stylers": [{ "color": "#38414e" }]
              },
              {
                "featureType": "road",
                "elementType": "geometry.stroke",
                "stylers": [{ "color": "#212a37" }]
              },
              {
                "featureType": "road.highway",
                "elementType": "geometry",
                "stylers": [{ "color": "#746855" }]
              },
              {
                "featureType": "road.highway",
                "elementType": "geometry.stroke",
                "stylers": [{ "color": "#1f2835" }]
              }
            ]
        """.trimIndent()
        map.setMapStyle(MapStyleOptions(styleJson))

        // Create empty trail polyline
        trailPolyline = map.addPolyline(PolylineOptions()
            .color(currentRouteColor)
            .width(12f)
            .geodesic(true))

        // Stop auto-follow on manual pan
        map.setOnCameraMoveStartedListener { reason ->
            if (reason == GoogleMap.OnCameraMoveStartedListener.REASON_GESTURE) {
                isFollowing = false
            }
        }

        // Now that map is ready, load data
        loadInitialData()
        startThingSpeakPolling()
    }

    private fun loadInitialData() {
        CoroutineScope(Dispatchers.IO).launch {
            val route = ApiClient.getRouteDetail(routeId)
            withContext(Dispatchers.Main) {
                if (route != null) {
                    if (trackedBusId.isEmpty()) {
                        trackedBusId = route.busId
                    }
                    drawStops(route)
                    if (route.isActive) {
                        if (route.lastPosition != null && route.lastPosition!!.lat != 0.0 && route.lastPosition!!.lng != 0.0) {
                            updateBusLocation(
                                route.lastPosition!!.lat,
                                route.lastPosition!!.lng,
                                route.lastPosition!!.speed,
                                route.busId
                            )
                        } else {
                            showWaitingForGps()
                        }
                    }
                }
            }
        }
    }

    private var isPolling = true

    private fun startThingSpeakPolling() {
        CoroutineScope(Dispatchers.IO).launch {
            while (isPolling) {
                // Wait 15 seconds between checks to respect ThingSpeak API limits
                kotlinx.coroutines.delay(15000)

                val response = ApiClient.getThingSpeakLocation("3393806")
                withContext(Dispatchers.Main) {
                    if (response != null && response.field1 != null && response.field2 != null) {
                        val lat = response.field1.toDoubleOrNull()
                        val lng = response.field2.toDoubleOrNull()
                        val speed = response.field3?.toDoubleOrNull() ?: 0.0

                        if (lat != null && lng != null) {
                            updateBusLocation(lat, lng, speed, trackedBusId.ifEmpty { "Active Bus" })
                        }
                    }
                }
            }
        }
    }

    private fun drawStops(route: Route) {
        if (route.stops.isEmpty()) return
        
        val map = googleMap ?: return
        val builder = LatLngBounds.Builder()

        // Draw dashed path between stops
        val stopLatLngs = route.stops.map { LatLng(it.lat, it.lng) }
        map.addPolyline(PolylineOptions()
            .addAll(stopLatLngs)
            .color(Color.argb(100, Color.red(currentRouteColor), Color.green(currentRouteColor), Color.blue(currentRouteColor)))
            .width(8f)
            .pattern(listOf(Dash(20f), Gap(10f)))
        )

        // Draw markers
        for (stop in route.stops) {
            val loc = LatLng(stop.lat, stop.lng)
            builder.include(loc)
            map.addMarker(MarkerOptions()
                .position(loc)
                .title(stop.name)
                // Default small dot using hue derived from route color
                .icon(BitmapDescriptorFactory.defaultMarker(getHueFromColor(currentRouteColor))))
        }

        // Center map to show all stops
        val bounds = builder.build()
        map.animateCamera(CameraUpdateFactory.newLatLngBounds(bounds, 100))
    }

    private fun getHueFromColor(color: Int): Float {
        val hsv = FloatArray(3)
        Color.colorToHSV(color, hsv)
        return hsv[0]
    }

    private fun updateBusLocation(lat: Double, lng: Double, speed: Double, busId: String) {
        // Ignore 0.0, 0.0 (Null Island/Africa) which happens before the GPS gets a lock
        if (lat == 0.0 && lng == 0.0) return

        val pt = LatLng(lat, lng)
        val map = googleMap ?: return

        if (busMarker == null) {
            busMarker = map.addMarker(MarkerOptions()
                .position(pt)
                .title("Bus $busId")
                .anchor(0.5f, 0.5f)
                // You can add a custom bitmap icon for the bus here later
                .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_RED))
                .zIndex(1.0f)
            )
        } else {
            busMarker?.position = pt
        }

        trailPoints.add(pt)
        trailPolyline?.points = trailPoints
        
        if (isFollowing) {
            map.animateCamera(CameraUpdateFactory.newLatLng(pt))
        }

        // Update UI
        findViewById<TextView>(R.id.tvStatus).apply {
            text = "LIVE NOW"
            setTextColor(ContextCompat.getColor(this@LiveMapActivity, R.color.success))
        }
        findViewById<TextView>(R.id.tvBusId).text = "Bus $busId"
        findViewById<TextView>(R.id.tvSpeed).apply {
            visibility = View.VISIBLE
            text = "${speed.toInt()} km/h"
        }
    }

    private fun showOffline() {
        findViewById<TextView>(R.id.tvStatus).apply {
            text = "Offline"
            setTextColor(ContextCompat.getColor(this@LiveMapActivity, R.color.text_secondary))
        }
        findViewById<View>(R.id.tvSpeed).visibility = View.GONE
        
        busMarker?.remove()
        busMarker = null
        
        trailPoints.clear()
        trailPolyline?.points = trailPoints
    }

    private fun showWaitingForGps() {
        findViewById<TextView>(R.id.tvStatus).apply {
            text = "Waiting for GPS..."
            setTextColor(ContextCompat.getColor(this@LiveMapActivity, R.color.warning)) // Assuming you have a warning color, or we can use #FB8C00
        }
        findViewById<View>(R.id.tvSpeed).visibility = View.GONE
    }

    override fun onDestroy() {
        super.onDestroy()
        isPolling = false
        // ws.disconnect() - No longer using WebSockets for tracking
    }
}
