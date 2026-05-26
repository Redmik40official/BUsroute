"use strict";

const db = require("../../../data/database");
const trackingService = require("../tracking/tracking.service");
const redis = require("../../config/redis");

const ROUTES_CACHE_KEY = "api:routes:all";

/**
 * Get all routes (with stops)
 */
async function getAllRoutes(req, res) {
  try {
    // 1. Try to get cached response
    const cachedRoutes = await redis.cacheGet(ROUTES_CACHE_KEY);
    if (cachedRoutes) {
      // Still need to compute live tracking status dynamically, so we can't cache isActive in Redis directly
      // unless we invalidate on every location tick (too expensive).
      // We will cache the DB response and attach `isActive` dynamically.
    }

    let routes = cachedRoutes;
    if (!routes) {
      routes = await db.getAllRoutes();
      // Cache the DB result for 5 minutes
      await redis.cacheSet(ROUTES_CACHE_KEY, routes, 300);
    }

    const activeBuses = await trackingService.getAllActiveBuses();
    const sanitised = routes.map((r) => ({
      id: r.id,
      name: r.name,
      shortName: r.shortName,
      description: r.description,
      busId: r.busId,
      color: r.color,
      stops: r.stops,
      isActive: activeBuses.has(r.busId),
    }));
    res.json({ routes: sanitised });
  } catch (err) {
    res.status(500).json({ error: "Database error fetching routes" });
  }
}

/**
 * Get a specific route by ID (with trail and live bus data)
 */
async function getRouteById(req, res) {
  try {
    const route = await db.getRouteById(req.params.id);
    if (!route) {
      return res.status(404).json({ error: "Route not found" });
    }

    const bus = await trackingService.getActiveBus(route.busId);
    let trail = bus ? bus.history : [];

    const detail = {
      id: route.id,
      name: route.name,
      shortName: route.shortName,
      description: route.description,
      busId: route.busId,
      color: route.color,
      stops: route.stops,
      isActive: !!bus,
      lastPosition: bus
        ? {
            lat: bus.lat,
            lng: bus.lng,
            speed: bus.speed,
            heading: bus.heading,
            timestamp: bus.timestamp,
          }
        : null,
      trail: trail,
    };
    res.json(detail);
  } catch (err) {
    res.status(500).json({ error: "Database error fetching route details" });
  }
}

/**
 * Get all currently active buses
 */
async function getActiveBuses(req, res) {
  try {
    const buses = [];
    const activeBuses = await trackingService.getAllActiveBuses();
    
    for (const [busId, bus] of activeBuses) {
      const route = await db.getRouteById(bus.routeId);
      buses.push({
        busId,
        routeId: bus.routeId,
        routeName: route ? route.name : "Unknown",
        color: route ? route.color : "#666",
        lat: bus.lat,
        lng: bus.lng,
        speed: bus.speed,
        heading: bus.heading,
        timestamp: bus.timestamp,
        trailLength: bus.history.length,
      });
    }
    res.json({ buses });
  } catch (err) {
    res.status(500).json({ error: "Database error fetching active buses" });
  }
}

module.exports = {
  getAllRoutes,
  getRouteById,
  getActiveBuses,
};
