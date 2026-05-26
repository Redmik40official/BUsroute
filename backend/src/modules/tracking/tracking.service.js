"use strict";

const redis = require("../../config/redis");

const MAX_HISTORY = 100;
const ACTIVE_BUSES_HASH = "active_buses";

async function activateBus(busId, routeId, tripId) {
  const busData = {
    busId,
    routeId,
    tripId,
    lat: null, 
    lng: null, 
    speed: 0, 
    heading: 0, 
    timestamp: Date.now(),
    history: [],
  };
  await redis.cacheHSet(ACTIVE_BUSES_HASH, busId, busData);
}

async function updateBusLocation(busId, lat, lng, speed, heading, timestamp) {
  const bus = await redis.cacheHGet(ACTIVE_BUSES_HASH, busId);
  if (!bus) return null;

  bus.lat = lat;
  bus.lng = lng;
  bus.speed = speed;
  bus.heading = heading;
  bus.timestamp = timestamp;

  bus.history.push({ lat, lng, speed, heading, timestamp });
  if (bus.history.length > MAX_HISTORY) bus.history.shift();

  await redis.cacheHSet(ACTIVE_BUSES_HASH, busId, bus);
  return bus;
}

async function deactivateBus(busId) {
  await redis.cacheHDel(ACTIVE_BUSES_HASH, busId);
}

async function getActiveBus(busId) {
  return await redis.cacheHGet(ACTIVE_BUSES_HASH, busId);
}

async function getAllActiveBuses() {
  const allBusesMap = await redis.cacheHGetAll(ACTIVE_BUSES_HASH);
  // Return Map to maintain backward compatibility with iterating [busId, bus]
  return new Map(Object.entries(allBusesMap));
}

module.exports = {
  activateBus,
  updateBusLocation,
  deactivateBus,
  getActiveBus,
  getAllActiveBuses
};
