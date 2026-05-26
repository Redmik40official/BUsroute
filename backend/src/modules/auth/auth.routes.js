/**
 * auth.routes.js
 *
 * Express router for all /api/auth/* endpoints.
 * Input validation is defined at the route level (express-validator)
 * and checked at the controller level.
 *
 * Rate limiting: login is rate-limited to 10 requests per minute per IP
 * to prevent brute-force attacks on the login endpoint.
 */

"use strict";

const { Router } = require("express");
const { body } = require("express-validator");
const rateLimit = require("express-rate-limit");
const controller = require("./auth.controller");
const { requireAuth } = require("../../middleware/auth.middleware");

const router = Router();

// ── Rate Limiter: 10 login attempts per minute per IP ─────────────────────────
const loginLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: { error: "Too many login attempts. Try again in 1 minute." },
  standardHeaders: true,
  legacyHeaders: false,
});

// ── Validation Rules ──────────────────────────────────────────────────────────
const registerRules = [
  body("name")
    .trim()
    .isLength({ min: 2, max: 80 })
    .withMessage("Name must be 2–80 characters"),
  body("email")
    .trim()
    .isEmail()
    .normalizeEmail()
    .withMessage("Valid email required"),
  body("password")
    .isLength({ min: 8 })
    .withMessage("Password must be at least 8 characters"),
  body("role")
    .isIn(["student", "driver", "admin"])
    .withMessage("Role must be student, driver, or admin"),
];

const loginRules = [
  body("email").trim().isEmail().normalizeEmail().withMessage("Valid email required"),
  body("password").notEmpty().withMessage("Password required"),
];

// ── Routes ───────────────────────────────────────────────────────────────────
router.post("/register", registerRules, controller.register);
router.post("/login",    loginLimiter, loginRules, controller.login);
router.post("/refresh",  controller.refresh);
router.post("/logout",   requireAuth, controller.logout);
router.get("/me",        requireAuth, controller.getMe);

module.exports = router;
