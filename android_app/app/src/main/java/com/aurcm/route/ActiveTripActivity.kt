package com.aurcm.route

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Looper
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import com.aurcm.route.data.models.LocationUpdate
import com.aurcm.route.data.remote.WebSocketManager
import com.google.android.gms.location.*

class ActiveTripActivity : AppCompatActivity() {

    private lateinit var ws: WebSocketManager
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback

    private lateinit var tvLat: TextView
    private lateinit var tvLng: TextView
    private lateinit var tvSpeed: TextView
    private lateinit var tvUpdateCount: TextView
    
    private var updateCount = 0
    private var busId = ""
    private var routeId = ""
    private var pin = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Keep screen awake while broadcasting to prevent Android from killing GPS updates
        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        setContentView(R.layout.activity_active_trip)

        busId = intent.getStringExtra("busId") ?: ""
        routeId = intent.getStringExtra("routeId") ?: ""
        pin = intent.getStringExtra("pin") ?: ""

        tvLat = findViewById(R.id.tvLat)
        tvLng = findViewById(R.id.tvLng)
        tvSpeed = findViewById(R.id.tvSpeed)
        tvUpdateCount = findViewById(R.id.tvUpdateCount)
        
        findViewById<TextView>(R.id.tvRouteInfo).text = "Bus $busId | Route $routeId"

        findViewById<Button>(R.id.btnStop).setOnClickListener {
            stopBroadcast()
        }

        val token = intent.getStringExtra("token") ?: ""

        ws = WebSocketManager { } // we don't care about incoming messages here
        ws.connect(token)
        
        // Let the backend know we are starting the trip on this socket connection
        window.decorView.postDelayed({
            ws.startCaptain(busId, pin, routeId)
        }, 500)

        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        startLocationUpdates()
    }

    private fun startLocationUpdates() {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED ||
            ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            
            ActivityCompat.requestPermissions(
                this, 
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION), 
                100
            )
            return
        }

        // Use PRIORITY_BALANCED_POWER_ACCURACY so it works indoors using Wi-Fi and Cell towers for testing
        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_BALANCED_POWER_ACCURACY, 2000).build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                for (loc in locationResult.locations) {
                    val speedKmH = loc.speed * 3.6
                    
                    tvLat.text = String.format("%.6f", loc.latitude)
                    tvLng.text = String.format("%.6f", loc.longitude)
                    tvSpeed.text = speedKmH.toInt().toString()
                    
                    updateCount++
                    tvUpdateCount.text = "$updateCount updates sent"

                    ws.sendLocation(
                        LocationUpdate(
                            type = "captain:location",
                            busId = busId,
                            routeId = routeId,
                            lat = loc.latitude,
                            lng = loc.longitude,
                            speed = speedKmH,
                            heading = loc.bearing.toDouble()
                        )
                    )
                }
            }
        }

        fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper())
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 100 && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            startLocationUpdates()
        } else {
            Toast.makeText(this, "Location permission required to broadcast", Toast.LENGTH_LONG).show()
            finish()
        }
    }

    private fun stopBroadcast() {
        ws.stopCaptain()
        fusedLocationClient.removeLocationUpdates(locationCallback)
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        fusedLocationClient.removeLocationUpdates(locationCallback)
        ws.disconnect()
    }
}
