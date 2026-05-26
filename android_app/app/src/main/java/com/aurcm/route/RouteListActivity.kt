package com.aurcm.route

import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.aurcm.route.data.models.Route
import com.aurcm.route.data.remote.ApiClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class RouteListActivity : AppCompatActivity() {
    private lateinit var adapter: RouteAdapter
    private var allRoutes = listOf<Route>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_route_list)

        findViewById<View>(R.id.btnBack).setOnClickListener { finish() }

        val rv = findViewById<RecyclerView>(R.id.rvRoutes)
        rv.layoutManager = LinearLayoutManager(this)
        adapter = RouteAdapter { route ->
            val intent = Intent(this, LiveMapActivity::class.java)
            intent.putExtra("routeId", route.id)
            intent.putExtra("routeName", route.name)
            intent.putExtra("routeColor", route.color)
            intent.putExtra("busId", route.busId)
            startActivity(intent)
        }
        rv.adapter = adapter

        val swipe = findViewById<SwipeRefreshLayout>(R.id.swipeRefresh)
        swipe.setOnRefreshListener { fetchRoutes() }

        findViewById<EditText>(R.id.etSearch).addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                val q = s.toString().lowercase()
                adapter.submitList(allRoutes.filter { 
                    it.name.lowercase().contains(q) || it.shortName.lowercase().contains(q)
                })
            }
            override fun afterTextChanged(s: Editable?) {}
        })

        fetchRoutes()
    }

    private fun fetchRoutes() {
        val swipe = findViewById<SwipeRefreshLayout>(R.id.swipeRefresh)
        swipe.isRefreshing = true
        CoroutineScope(Dispatchers.IO).launch {
            val routes = ApiClient.getRoutes()
            withContext(Dispatchers.Main) {
                // Sort active ones to top
                allRoutes = routes.sortedByDescending { it.isActive }
                adapter.submitList(allRoutes)
                swipe.isRefreshing = false
            }
        }
    }
}

class RouteAdapter(private val onClick: (Route) -> Unit) : RecyclerView.Adapter<RouteAdapter.VH>() {
    private var items = listOf<Route>()

    fun submitList(newItems: List<Route>) {
        items = newItems
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_route, parent, false)
        return VH(view)
    }

    override fun onBindViewHolder(holder: VH, position: Int) {
        val r = items[position]
        holder.tvName.text = r.name
        holder.tvInfo.text = "Bus ${r.busId} • ${r.stops.size} Stops"
        holder.tvLive.visibility = if (r.isActive) View.VISIBLE else View.GONE
        
        try {
            holder.badge.setBackgroundColor(Color.parseColor(r.color))
        } catch (e: Exception) {
            holder.badge.setBackgroundColor(Color.GRAY)
        }

        holder.itemView.setOnClickListener { onClick(r) }
    }

    override fun getItemCount() = items.size

    class VH(v: View) : RecyclerView.ViewHolder(v) {
        val tvName: TextView = v.findViewById(R.id.tvRouteName)
        val tvInfo: TextView = v.findViewById(R.id.tvRouteInfo)
        val tvLive: TextView = v.findViewById(R.id.tvLive)
        val badge: FrameLayout = v.findViewById(R.id.iconBadge)
    }
}
