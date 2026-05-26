package com.aurcm.route.data.models

data class Route(
    val id: String,
    val name: String,
    val shortName: String,
    val description: String,
    val busId: String,
    val color: String,
    val stops: List<Stop>,
    var isActive: Boolean = false,
    var lastPosition: LocationUpdate? = null,
    var trail: List<LocationUpdate> = emptyList()
)

data class Stop(
    val name: String,
    val lat: Double,
    val lng: Double,
    val estimatedTime: String? = null
)

data class LocationUpdate(
    val type: String = "bus:location",
    val busId: String,
    val routeId: String?,
    val lat: Double,
    val lng: Double,
    val speed: Double = 0.0,
    val heading: Double = 0.0,
    val timestamp: Long = System.currentTimeMillis()
)

data class ServerResponse(
    val type: String,
    val message: String? = null,
    val buses: List<LocationUpdate>? = null,
    val busId: String? = null,
    val routeId: String? = null,
    val lat: Double? = null,
    val lng: Double? = null,
    val speed: Double? = null
)

data class RoutesResponse(
    val routes: List<Route>
)

data class ThingSpeakResponse(
    val created_at: String?,
    val entry_id: Long?,
    val field1: String?,
    val field2: String?,
    val field3: String?
)
