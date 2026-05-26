/**
 * jwt.util.js
 *
 * Centralized JWT helpers.
 *
 * Why two separate secrets for access and refresh tokens?
 * If an attacker somehow leaks the access token secret, they cannot forge
 * refresh tokens (and vice versa). Defense in depth.
 *
 * Access token:  Short-lived (15m) — used on every API call
 * Refresh token: Long-lived (7d) — used ONLY to get a new access token
 */

"use strict";

const jwt = require("jsonwebtoken");

const ACCESS_SECRET  = process.env.JWT_ACCESS_SECRET  || "aurcm_access_secret_change_in_production";
const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || "aurcm_refresh_secret_change_in_production";

const ACCESS_EXPIRES  = process.env.JWT_ACCESS_EXPIRES  || "15m";
const REFRESH_EXPIRES = process.env.JWT_REFRESH_EXPIRES || "7d";

/**
 * Sign a short-lived access token.
 * @param {{ id, name, email, role }} payload
 */
function signAccessToken(payload) {
  return jwt.sign(
    { id: payload.id, name: payload.name, email: payload.email, role: payload.role },
    ACCESS_SECRET,
    { expiresIn: ACCESS_EXPIRES }
  );
}

/**
 * Sign a long-lived refresh token (includes only id + role for minimal exposure).
 */
function signRefreshToken(payload) {
  return jwt.sign(
    { id: payload.id, name: payload.name, email: payload.email, role: payload.role },
    REFRESH_SECRET,
    { expiresIn: REFRESH_EXPIRES }
  );
}

/**
 * Verify and decode an access token. Throws if invalid or expired.
 */
function verifyAccessToken(token) {
  return jwt.verify(token, ACCESS_SECRET);
}

/**
 * Verify and decode a refresh token. Throws if invalid or expired.
 */
function verifyRefreshToken(token) {
  return jwt.verify(token, REFRESH_SECRET);
}

module.exports = { signAccessToken, signRefreshToken, verifyAccessToken, verifyRefreshToken };
