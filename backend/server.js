"use strict";

const http       = require("http");
const express    = require("express");
const cors       = require("cors");
const helmet     = require("helmet");
const rateLimit  = require("express-rate-limit");
const db         = require("./data/database");
const redis      = require("./src/config/redis");
const { initSocket } = require("./src/config/socket");

// ── Auth Module (Phase 3) ────────────────────────────────────────────────────
const authRoutes = require("./src/modules/auth/auth.routes");
const trackingService = require("./src/modules/tracking/tracking.service");

// ---------------------------------------------------------------------------
//  Configuration
// ---------------------------------------------------------------------------
const PORT = parseInt(process.env.PORT, 10) || 3000;
const HOST = process.env.HOST || "0.0.0.0";

const MAX_HISTORY = 100;

// ---------------------------------------------------------------------------
//  In-memory state for active buses
// ---------------------------------------------------------------------------
/**
 * activeBuses: Map<busId, {
 *   busId, routeId, tripId, ws,               // identity & socket
 *   lat, lng, speed, heading, timestamp,       // last-known position
 *   history: Array<{lat,lng,speed,heading,timestamp}>  // trail
 * }>
 */
const activeBuses = new Map();
const studentSubscribers = new Set();
const lastThingSpeakUpdate = new Map(); // busId -> timestamp

// ---------------------------------------------------------------------------
//  Express app (REST API)
// ---------------------------------------------------------------------------
const app = express();

app.use(cors({
  origin: "*",
  methods: ["GET", "OPTIONS"],
  allowedHeaders: ["Content-Type"],
}));

app.use(express.json());

// ── Security Middleware ──────────────────────────────────────────────────────
app.use(helmet());

// Auth Limiter: Restrict login/register endpoints to prevent brute force
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // limit each IP to 20 auth requests per windowMs
  message: { error: "Too many login attempts from this IP, please try again after 15 minutes" },
  standardHeaders: true, 
  legacyHeaders: false,
});

// General API Limiter: Restrict general API hits to prevent DDoS
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100, // limit each IP to 100 requests per minute
  message: { error: "Too many requests from this IP, please try again after a minute" },
  standardHeaders: true,
  legacyHeaders: false,
});

// Apply general limiter to all /api routes
app.use("/api/", apiLimiter);

// ── Auth Routes (Phase 3) ────────────────────────────────────────────────────
app.use("/api/auth", authLimiter, authRoutes);

// ---------- Health check ----------------------------------------------------
app.get("/api/health", async (_req, res) => {
  const activeBusesMap = await trackingService.getAllActiveBuses();
  res.json({
    status: "ok",
    uptime: process.uptime(),
    activeBuses: activeBusesMap.size,
    timestamp: Date.now(),
  });
});

const routeRoutes = require("./src/modules/routes/route.routes");
app.use("/api/routes", routeRoutes);

app.use("/api", (_req, res) => res.status(404).json({ error: "Endpoint not found" }));

// ---------------------------------------------------------------------------
//  HTTP + Socket.IO server
// ---------------------------------------------------------------------------
const server = http.createServer(app);
initSocket(server); // Initialize Socket.IO with Express server

function gracefulShutdown(signal) {
  console.log(`\n[SHUTDOWN] Received ${signal}. Closing server…`);
  // Optionally terminate active buses/trips if kept in memory
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(1), 5000);
}

process.on("SIGINT",  () => gracefulShutdown("SIGINT"));
process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));

// ---------------------------------------------------------------------------
//  Start listening (after DB init)
// ---------------------------------------------------------------------------
async function startServer() {
  console.log("[BOOT] Starting server initialization...");
  
  try {
    console.log("[BOOT] Initializing Redis...");
    redis.initRedis(); // Initializes connection or fallback
    
    console.log("[BOOT] Initializing Database...");
    await db.initDB();
    console.log("[BOOT] Database initialized successfully.");
  } catch (err) {
    console.error("[BOOT] FATAL ERROR DURING INIT:", err);
    process.exit(1);
  }

  console.log(`[BOOT] Attempting to listen on ${HOST}:${PORT}...`);
  server.listen(PORT, HOST, async () => {
    const routes = await db.getAllRoutes();
    console.log("═══════════════════════════════════════════════════════════");
    console.log("  🚌  AURCM Route — Database Server Started");
    console.log(`  🔗  Host      : ${HOST}:${PORT}`);
    console.log(`  🗄️  Database  : SQLite (aurcm.db)`);
    console.log(`  🗺️  Routes    : ${routes.length}`);
    console.log("═══════════════════════════════════════════════════════════");
  });
}

startServer();
