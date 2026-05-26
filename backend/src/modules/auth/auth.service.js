/**
 * auth.service.js
 *
 * Business logic for authentication.
 * Separated from the controller (Express layer) so it can be tested in isolation
 * and reused without depending on req/res objects.
 *
 * Design decisions:
 * - bcryptjs rounds=12: ~300ms hash time — good balance of security vs speed
 * - Access token expires in 15m, refresh token in 7d
 * - Refresh tokens stored in DB to support revocation on logout
 * - UUIDs as user IDs to prevent enumeration attacks
 */

"use strict";

const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const uuidv4 = () => crypto.randomUUID();
const db = require("../../../data/database");
const { signAccessToken, signRefreshToken, verifyRefreshToken } = require("../../shared/jwt.util");

const BCRYPT_ROUNDS = 12;

// ─────────────────────────────────────────────────────────────────────────────
// Register
// ─────────────────────────────────────────────────────────────────────────────
async function register({ name, email, password, role }) {
  // Check for existing user
  const existing = await db.getUserByEmail(email);
  if (existing) {
    throw Object.assign(new Error("Email already registered"), { statusCode: 409 });
  }

  // Hash password
  const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);
  const id = uuidv4();

  // Persist user
  await db.createUser({ id, name, email, passwordHash, role });

  // Issue tokens
  const user = { id, name, email, role };
  const accessToken  = signAccessToken(user);
  const refreshToken = signRefreshToken(user);

  // Store refresh token
  await db.saveRefreshToken(id, refreshToken);

  return { user, accessToken, refreshToken };
}

// ─────────────────────────────────────────────────────────────────────────────
// Login
// ─────────────────────────────────────────────────────────────────────────────
async function login({ email, password }) {
  const userRow = await db.getUserByEmail(email);
  if (!userRow) {
    throw Object.assign(new Error("Invalid email or password"), { statusCode: 401 });
  }

  const isMatch = await bcrypt.compare(password, userRow.password_hash);
  if (!isMatch) {
    throw Object.assign(new Error("Invalid email or password"), { statusCode: 401 });
  }

  const user = { id: userRow.id, name: userRow.name, email: userRow.email, role: userRow.role };
  const accessToken  = signAccessToken(user);
  const refreshToken = signRefreshToken(user);

  // Rotate refresh token: delete old, save new
  await db.deleteRefreshTokenByUserId(userRow.id);
  await db.saveRefreshToken(userRow.id, refreshToken);

  return { user, accessToken, refreshToken };
}

// ─────────────────────────────────────────────────────────────────────────────
// Bus/Driver Login
// ─────────────────────────────────────────────────────────────────────────────
async function busLogin({ busId, pin }) {
  // Find the route associated with this busId and check the PIN
  const route = await db.getRouteByBusId(busId);
  
  if (!route) {
    throw Object.assign(new Error("Invalid bus ID or PIN"), { statusCode: 401 });
  }

  // Assuming plaintext PIN for simplicity in this prototype. 
  // If it was hashed, use bcrypt.compare
  if (route.pin !== pin) {
    throw Object.assign(new Error("Invalid bus ID or PIN"), { statusCode: 401 });
  }

  // Generate a mock driver user profile for the JWT
  const user = {
    id: `driver-${busId}`,
    name: `Driver for ${busId}`,
    email: `${busId}@aurcm.edu`,
    role: "driver"
  };

  const accessToken  = signAccessToken(user);
  
  // We don't issue a refresh token for bus/pin login to keep it simple, 
  // or we can just issue an access token with a longer life, or issue a refresh token.
  // We'll issue a refresh token so the app logic remains identical.
  const refreshToken = signRefreshToken(user);
  
  // Create a placeholder user in DB if necessary to store refresh token?
  // Because refresh tokens have a foreign key to User.
  // Wait, if the user doesn't exist in the Users table, saving a refresh token will crash SQLite!
  // Let's create a user row for the bus if it doesn't exist.
  let userRow = await db.getUserByEmail(user.email);
  if (!userRow) {
    const passwordHash = await bcrypt.hash(pin, 10);
    await db.createUser({
      id: user.id,
      name: user.name,
      email: user.email,
      passwordHash: passwordHash,
      role: "driver"
    });
    userRow = await db.getUserByEmail(user.email);
  }

  // Rotate refresh token
  await db.deleteRefreshTokenByUserId(userRow.id);
  await db.saveRefreshToken(userRow.id, refreshToken);

  return { user, accessToken, refreshToken };
}

// ─────────────────────────────────────────────────────────────────────────────
// Refresh Access Token
// ─────────────────────────────────────────────────────────────────────────────
async function refresh({ refreshToken }) {
  // Verify signature + expiry
  let payload;
  try {
    payload = verifyRefreshToken(refreshToken);
  } catch {
    throw Object.assign(new Error("Invalid or expired refresh token"), { statusCode: 401 });
  }

  // Verify token is in DB (not revoked)
  const stored = await db.getRefreshToken(payload.id, refreshToken);
  if (!stored) {
    throw Object.assign(new Error("Refresh token revoked"), { statusCode: 401 });
  }

  const user = { id: payload.id, name: payload.name, email: payload.email, role: payload.role };
  const newAccessToken = signAccessToken(user);

  return { accessToken: newAccessToken };
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout — Revoke refresh token
// ─────────────────────────────────────────────────────────────────────────────
async function logout(userId) {
  await db.deleteRefreshTokenByUserId(userId);
}

// ─────────────────────────────────────────────────────────────────────────────
// Get current user profile
// ─────────────────────────────────────────────────────────────────────────────
async function getMe(userId) {
  const userRow = await db.getUserById(userId);
  if (!userRow) {
    throw Object.assign(new Error("User not found"), { statusCode: 404 });
  }
  return {
    id:    userRow.id,
    name:  userRow.name,
    email: userRow.email,
    role:  userRow.role,
  };
}

module.exports = { register, login, busLogin, refresh, logout, getMe };
