/**
 * database.js
 *
 * Prisma data access layer (Phase 4).
 * Replaces the old sqlite3 wrapper with Prisma Client.
 * All functions return Promises as before, so external API is preserved.
 */

"use strict";

require("dotenv").config();
const { PrismaClient } = require("@prisma/client");
const path = require("path");
const fs = require("fs");

const prisma = new PrismaClient();
const routesJsonPath = path.join(__dirname, "routes.json");

// ─────────────────────────────────────────────────────────────────────────────
//  Database Initialization
// ─────────────────────────────────────────────────────────────────────────────
async function initDB() {
  try {
    // ── Seed routes if empty ─────────────────────────────────────────────────
    const routesCount = await prisma.route.count();
    if (routesCount === 0) {
      console.log("[DB] Routes table empty. Seeding from routes.json...");

      if (fs.existsSync(routesJsonPath)) {
        const raw = fs.readFileSync(routesJsonPath, "utf-8");
        const data = JSON.parse(raw);

        for (const route of data.routes) {
          if (route.busId) {
            await prisma.bus.upsert({
              where: { id: route.busId },
              update: {},
              create: {
                id: route.busId,
                registrationNo: "TN-XX-XXXX",
                model: "College Bus",
                capacity: 50,
              },
            });
          }

          await prisma.route.create({
            data: {
              id: route.id,
              name: route.name,
              shortName: route.shortName,
              description: route.description,
              busId: route.busId,
              pin: route.pin,
              color: route.color,
              Stops: {
                create: route.stops.map((stop, index) => ({
                  name: stop.name,
                  lat: stop.lat,
                  lng: stop.lng,
                  stopOrder: index,
                  radiusMeters: 100,
                })),
              },
            },
          });
        }
        console.log(`[DB] Seeded ${data.routes.length} routes.`);
      }
    } else {
      console.log(`[DB] Routes exist (${routesCount}). Skipping seed.`);
    }
  } catch (err) {
    console.error("[DB] Initialization error:", err.message);
    throw err;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Route Data Access
// ─────────────────────────────────────────────────────────────────────────────
// We map Prisma nested objects back to the legacy format if needed,
// but Prisma's `include` works better. For now, keep the structure somewhat similar.
const formatRoute = (r) => {
  if (!r) return null;
  return {
    ...r,
    stops: r.Stops,
  };
};

async function getAllRoutes() {
  const routes = await prisma.route.findMany({ include: { Stops: { orderBy: { stopOrder: 'asc' } } } });
  return routes.map(formatRoute);
}

async function getRouteById(id) {
  const route = await prisma.route.findUnique({
    where: { id },
    include: { Stops: { orderBy: { stopOrder: 'asc' } } },
  });
  return formatRoute(route);
}

async function getRouteByBusId(busId) {
  const route = await prisma.route.findFirst({
    where: { busId },
    include: { Stops: { orderBy: { stopOrder: 'asc' } } },
  });
  return formatRoute(route);
}

async function getRouteByPin(pin) {
  const route = await prisma.route.findFirst({
    where: { pin: String(pin) },
    include: { Stops: { orderBy: { stopOrder: 'asc' } } },
  });
  return formatRoute(route);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Trip Data Access
// ─────────────────────────────────────────────────────────────────────────────
async function createTrip(routeId, busId, driverId = null) {
  const trip = await prisma.trip.create({
    data: {
      routeId,
      busId,
      driverId,
      status: "active",
      startedAt: new Date(),
    },
  });
  return trip.id;
}

async function endTrip(tripId) {
  await prisma.trip.update({
    where: { id: tripId },
    data: {
      status: "completed",
      endedAt: new Date(),
    },
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Location Data Access
// ─────────────────────────────────────────────────────────────────────────────
async function addLocation(tripId, lat, lng, speed, heading, timestamp) {
  await prisma.liveLocation.create({
    data: {
      tripId,
      lat,
      lng,
      speed,
      heading,
      recordedAt: new Date(timestamp),
    },
  });
}

async function getTripTrail(tripId, limit = 100) {
  const locations = await prisma.liveLocation.findMany({
    where: { tripId },
    orderBy: { recordedAt: 'desc' },
    take: limit,
  });
  return locations.map(loc => ({
    lat: loc.lat,
    lng: loc.lng,
    speed: loc.speed,
    heading: loc.heading,
    timestamp: loc.recordedAt.getTime(),
  }));
}

// ─────────────────────────────────────────────────────────────────────────────
//  User Data Access  (Phase 3)
// ─────────────────────────────────────────────────────────────────────────────
async function createUser({ id, name, email, passwordHash, role }) {
  await prisma.user.create({
    data: { id, name, email, passwordHash, role },
  });
}

async function getUserByEmail(email) {
  return prisma.user.findUnique({ where: { email } });
}

async function getUserById(id) {
  return prisma.user.findUnique({ where: { id } });
}

async function updateFcmToken(userId, fcmToken) {
  await prisma.user.update({
    where: { id: userId },
    data: { fcmToken },
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Refresh Token Data Access  (Phase 3)
// ─────────────────────────────────────────────────────────────────────────────
async function saveRefreshToken(userId, token) {
  await prisma.refreshToken.create({
    data: { userId, token },
  });
}

async function getRefreshToken(userId, token) {
  return prisma.refreshToken.findUnique({
    where: { token },
  });
}

async function deleteRefreshTokenByUserId(userId) {
  await prisma.refreshToken.deleteMany({
    where: { userId },
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Exports
// ─────────────────────────────────────────────────────────────────────────────
module.exports = {
  prisma, // Expose prisma client instead of old sqlite db
  initDB,
  // Routes
  getAllRoutes,
  getRouteById,
  getRouteByBusId,
  getRouteByPin,
  // Trips
  createTrip,
  endTrip,
  // Locations
  addLocation,
  getTripTrail,
  // Users (Phase 3)
  createUser,
  getUserByEmail,
  getUserById,
  updateFcmToken,
  // Refresh Tokens (Phase 3)
  saveRefreshToken,
  getRefreshToken,
  deleteRefreshTokenByUserId,
};
