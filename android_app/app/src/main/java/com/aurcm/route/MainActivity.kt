package com.aurcm.route

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.cardview.widget.CardView

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        findViewById<CardView>(R.id.cardStudent).setOnClickListener {
            startActivity(Intent(this, RouteListActivity::class.java))
        }

        findViewById<CardView>(R.id.cardCaptain).setOnClickListener {
            startActivity(Intent(this, CaptainLoginActivity::class.java))
        }
    }
}
