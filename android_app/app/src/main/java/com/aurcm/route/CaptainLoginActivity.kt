package com.aurcm.route

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.EditText
import android.widget.ProgressBar
import android.widget.Spinner
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.aurcm.route.data.models.Route
import com.aurcm.route.data.remote.ApiClient
import com.aurcm.route.data.remote.WebSocketManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class CaptainLoginActivity : AppCompatActivity() {

    private lateinit var spinner: Spinner
    private lateinit var etBusId: EditText
    private lateinit var etPin: EditText
    private lateinit var btnStart: Button
    private lateinit var tvError: TextView
    private lateinit var progressBar: ProgressBar

    private var routes = listOf<Route>()
    private var ws: WebSocketManager? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_captain_login)

        findViewById<View>(R.id.btnBack).setOnClickListener { finish() }

        etBusId = findViewById(R.id.etBusId)
        etPin = findViewById(R.id.etPin)
        btnStart = findViewById(R.id.btnStart)
        tvError = findViewById(R.id.tvError)
        progressBar = findViewById(R.id.progressBar)

        btnStart.setOnClickListener {
            val username = etBusId.text.toString().trim()
            val pin = etPin.text.toString().trim()

            if (username.isEmpty() || pin.isEmpty()) {
                showError("Username and PIN are required")
                return@setOnClickListener
            }

            attemptStart(username, pin)
        }
    }

    private fun showError(msg: String) {
        tvError.text = msg
        tvError.visibility = View.VISIBLE
        progressBar.visibility = View.GONE
        btnStart.isEnabled = true
    }

    private fun attemptStart(busId: String, pin: String) {
        tvError.visibility = View.GONE
        progressBar.visibility = View.VISIBLE
        btnStart.isEnabled = false

        CoroutineScope(Dispatchers.Main).launch {
            val response = ApiClient.busLogin(busId, pin)
            if (response == null) {
                showError("Invalid Bus ID or PIN, or Network Error")
                return@launch
            }

            // We have a token! Connect WebSocket
            ws = WebSocketManager { wsResponse ->
                runOnUiThread {
                    if (wsResponse.type == "error") {
                        showError(wsResponse.message ?: "Authentication failed")
                        ws?.disconnect()
                    } else if (wsResponse.type == "captain:ack") {
                        ws?.disconnect()
                        // Success! Move to active trip screen
                        val intent = Intent(this@CaptainLoginActivity, ActiveTripActivity::class.java)
                        intent.putExtra("busId", busId)
                        intent.putExtra("pin", pin)
                        intent.putExtra("token", response.accessToken)
                        startActivity(intent)
                        finish()
                    }
                }
            }
            ws?.connect(response.accessToken)
            
            // Wait briefly for connection before emitting trip:start
            window.decorView.postDelayed({
                // The old system didn't know routeId here, but the backend requires it.
                // We'll pass busId as routeId for now, or the backend will ignore it.
                // Actually, let's fetch route details to get the routeId!
                CoroutineScope(Dispatchers.IO).launch {
                    val routes = ApiClient.getRoutes()
                    val myRoute = routes.find { it.busId == busId }
                    val routeId = myRoute?.id ?: busId
                    withContext(Dispatchers.Main) {
                        ws?.startCaptain(busId, pin, routeId)
                    }
                }
            }, 1000)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        ws?.disconnect()
    }
}
