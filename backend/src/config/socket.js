const { Server } = require("socket.io");
const { verifyAccessToken } = require("../shared/jwt.util");
const trackingService = require("../modules/tracking/tracking.service");

let io;

function initSocket(httpServer) {
  io = new Server(httpServer, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"]
    }
  });

  // Middleware: Authenticate Socket connection
  io.use((socket, next) => {
    // Some clients (like students viewing map anonymously) might not have a token.
    // If anonymous access is allowed, we can let them connect but restrict emissions.
    // Let's parse token if available
    const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization;
    if (token) {
      try {
        const cleanToken = token.replace("Bearer ", "");
        const decoded = verifyAccessToken(cleanToken);
        socket.user = decoded;
      } catch (err) {
        // Just leave socket.user undefined if invalid token
      }
    }
    next();
  });

  io.on("connection", (socket) => {
    console.log(`[Socket] Client connected: ${socket.id} (User: ${socket.user?.email || 'Anonymous'})`);

    // ── Student: Subscribe to a Route Room ──────────────────────────────────
    socket.on("student:subscribe", async ({ routeId }) => {
      const roomName = `route:${routeId}`;
      socket.join(roomName);
      console.log(`[Socket] Client ${socket.id} joined room: ${roomName}`);
      
      // Fetch latest known location and emit immediately
      const activeBusesMap = await trackingService.getAllActiveBuses();
      for (const [busId, busData] of activeBusesMap) {
        if (busData.routeId === routeId) {
          socket.emit("bus:location", {
            busId: busData.busId,
            lat: busData.lat,
            lng: busData.lng,
            speed: busData.speed,
            heading: busData.heading,
            timestamp: busData.timestamp
          });
          break;
        }
      }
    });

    socket.on("student:unsubscribe", ({ routeId }) => {
      socket.leave(`route:${routeId}`);
    });

    // ── Driver: Tracking Events ─────────────────────────────────────────────
    socket.on("trip:start", async (data) => {
      if (socket.user?.role !== "driver") return;

      const { tripId, busId, routeId } = data;
      const roomName = `route:${routeId}`;
      
      // Initialize in memory/redis tracking
      await trackingService.activateBus(busId, routeId, tripId);

      socket.join(roomName);
      console.log(`[Socket] Trip ${tripId} started on bus ${busId} (Route ${routeId})`);
      
      io.to(roomName).emit("trip:started", { tripId, busId, routeId });
    });

    socket.on("location:update", async (data) => {
      if (socket.user?.role !== "driver") return;

      const { tripId, busId, routeId, lat, lng, speed, heading, accuracy, timestamp } = data;
      const roomName = `route:${routeId}`;

      // Update in redis state
      await trackingService.updateBusLocation(busId, lat, lng, speed, heading, timestamp);

      io.to(roomName).emit("bus:location", {
        busId, lat, lng, speed, heading, timestamp
      });

      // 2. Persist to DB asynchronously
      try {
        const db = require("../../data/database");
        await db.addLocation(tripId, lat, lng, speed, heading, timestamp);
      } catch (err) {
        console.error("[Socket] Failed to save location:", err.message);
      }
    });

    socket.on("trip:end", async (data) => {
      if (socket.user?.role !== "driver") return;

      const { tripId, busId, routeId } = data;
      const roomName = `route:${routeId}`;

      await trackingService.deactivateBus(busId);

      io.to(roomName).emit("trip:ended", { tripId, busId });
      socket.leave(roomName);
      console.log(`[Socket] Trip ${tripId} ended`);
    });

    socket.on("disconnect", () => {
      console.log(`[Socket] Client disconnected: ${socket.id}`);
    });
  });

  console.log("[Socket] Socket.IO initialized");
  return io;
}

function getIo() {
  if (!io) {
    throw new Error("Socket.IO has not been initialized. Call initSocket first.");
  }
  return io;
}

module.exports = {
  initSocket,
  getIo
};
