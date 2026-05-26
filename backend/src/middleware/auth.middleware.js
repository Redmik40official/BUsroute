/**
 * auth.middleware.js
 *
 * JWT verification middleware.
 * Attached to any route that requires authentication.
 *
 * Extracts the Bearer token from Authorization header,
 * verifies signature and expiry, then attaches the decoded
 * user payload to req.user for downstream handlers.
 *
 * Role-based guard factory (requireRole) ensures only users
 * with the specified role(s) can reach a route.
 */

"use strict";

const { verifyAccessToken } = require("../shared/jwt.util");

/**
 * Require a valid JWT access token.
 * Attaches decoded payload to req.user.
 */
function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Authorization header missing or malformed" });
  }

  const token = authHeader.slice(7); // strip "Bearer "

  try {
    const payload = verifyAccessToken(token);
    req.user = payload; // { id, name, email, role, iat, exp }
    next();
  } catch (err) {
    const message = err.name === "TokenExpiredError"
      ? "Access token expired"
      : "Invalid access token";
    res.status(401).json({ error: message });
  }
}

/**
 * Role-based access control factory.
 * Usage: router.get('/admin', requireAuth, requireRole('admin'), handler)
 *
 * @param {...string} roles — allowed roles
 */
function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: "Not authenticated" });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        error: `Access denied. Required role: ${roles.join(" or ")}`,
      });
    }
    next();
  };
}

module.exports = { requireAuth, requireRole };
