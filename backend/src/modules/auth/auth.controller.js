/**
 * auth.controller.js
 *
 * Thin Express controller layer.
 * Responsibility: parse/validate request → call service → format response.
 * No business logic lives here — that's all in auth.service.js.
 */

"use strict";

const { validationResult } = require("express-validator");
const authService = require("./auth.service");

function handleError(res, err) {
  const status = err.statusCode || 500;
  const message = err.message || "Internal server error";
  res.status(status).json({ error: message });
}

// POST /api/auth/register
async function register(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  try {
    const { name, email, password, role } = req.body;
    const result = await authService.register({ name, email, password, role });
    res.status(201).json(result);
  } catch (err) {
    handleError(res, err);
  }
}

// POST /api/auth/login
async function login(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ errors: errors.array() });
  }

  try {
    const { email, password } = req.body;
    const result = await authService.login({ email, password });
    res.json(result);
  } catch (err) {
    handleError(res, err);
  }
}

// POST /api/auth/bus-login
async function busLogin(req, res) {
  try {
    const { busId, pin } = req.body;
    if (!busId || !pin) {
      return res.status(400).json({ error: "busId and pin required" });
    }
    const result = await authService.busLogin({ busId, pin });
    res.json(result);
  } catch (err) {
    handleError(res, err);
  }
}

// POST /api/auth/refresh
async function refresh(req, res) {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(400).json({ error: "refreshToken required" });

    const result = await authService.refresh({ refreshToken });
    res.json(result);
  } catch (err) {
    handleError(res, err);
  }
}

// POST /api/auth/logout
async function logout(req, res) {
  try {
    await authService.logout(req.user.id);
    res.json({ message: "Logged out successfully" });
  } catch (err) {
    handleError(res, err);
  }
}

// GET /api/auth/me
async function getMe(req, res) {
  try {
    const user = await authService.getMe(req.user.id);
    res.json({ user });
  } catch (err) {
    handleError(res, err);
  }
}

module.exports = { register, login, busLogin, refresh, logout, getMe };
