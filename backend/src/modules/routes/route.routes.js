"use strict";

const express = require("express");
const routeController = require("./route.controller");

const router = express.Router();

router.get("/", routeController.getAllRoutes);
router.get("/buses", routeController.getActiveBuses);
router.get("/:id", routeController.getRouteById);

module.exports = router;
