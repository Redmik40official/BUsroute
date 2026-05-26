module.exports = {
  apps: [
    {
      name: "aurcm-route-backend",
      script: "./server.js",
      instances: "max", // Scale across all available CPU cores
      exec_mode: "cluster", // Enable PM2 load balancing
      env: {
        NODE_ENV: "development",
      },
      env_production: {
        NODE_ENV: "production",
        PORT: 3000,
      },
      // Logs
      out_file: "./logs/out.log",
      error_file: "./logs/error.log",
      merge_logs: true,
      time: true,
    },
  ],
};
