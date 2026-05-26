const io = require("socket.io-client");

const socket = io("https://aurcm-backend.onrender.com", { transports: ["websocket"] });

socket.on("connect", () => {
  console.log("Connected to server");
  socket.emit("student:subscribe", { routeId: "route-1" });
});

socket.on("bus:location", (data) => {
  console.log("RECEIVED BUS LOCATION:", data);
  process.exit(0);
});

setTimeout(() => {
  console.log("Timeout waiting for bus location");
  process.exit(1);
}, 5000);
