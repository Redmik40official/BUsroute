"use strict";

const Redis = require("ioredis");
const logger = console; // Basic logging for now

const REDIS_URL = process.env.REDIS_URL || "redis://127.0.0.1:6379";

let redisClient = null;
let isRedisAvailable = false;

// Fallback in-memory cache if Redis is down
const fallbackCache = new Map();

/**
 * Initializes the Redis connection
 */
function initRedis() {
  redisClient = new Redis(REDIS_URL, {
    maxRetriesPerRequest: 1, // Fail fast if Redis isn't running
    retryStrategy(times) {
      if (times > 3) {
        logger.warn("[Redis] Maximum retries reached. Switching to In-Memory fallback.");
        return null; // Stop retrying
      }
      return Math.min(times * 50, 2000);
    },
  });

  redisClient.on("connect", () => {
    isRedisAvailable = true;
    logger.info(`[Redis] Connected successfully to ${REDIS_URL}`);
  });

  redisClient.on("error", (err) => {
    if (isRedisAvailable) {
      logger.warn(`[Redis] Connection error: ${err.message}`);
    }
    isRedisAvailable = false;
  });

  return redisClient;
}

/**
 * Gets a value from cache
 * @param {string} key 
 */
async function cacheGet(key) {
  if (isRedisAvailable && redisClient) {
    try {
      const val = await redisClient.get(key);
      return val ? JSON.parse(val) : null;
    } catch (e) {
      return fallbackCache.get(key);
    }
  }
  return fallbackCache.get(key);
}

/**
 * Sets a value in cache with optional TTL
 * @param {string} key 
 * @param {any} value 
 * @param {number} ttlSeconds 
 */
async function cacheSet(key, value, ttlSeconds = 300) {
  if (isRedisAvailable && redisClient) {
    try {
      await redisClient.setex(key, ttlSeconds, JSON.stringify(value));
      return;
    } catch (e) {
      // Fall through to fallback
    }
  }
  
  fallbackCache.set(key, value);
  // Manual TTL for fallback cache
  setTimeout(() => {
    if (fallbackCache.get(key) === value) {
      fallbackCache.delete(key);
    }
  }, ttlSeconds * 1000);
}

/**
 * Hash Set (hset)
 */
async function cacheHSet(hash, key, value) {
  if (isRedisAvailable && redisClient) {
    try {
      await redisClient.hset(hash, key, JSON.stringify(value));
      return;
    } catch (e) {}
  }
  
  if (!fallbackCache.has(hash)) fallbackCache.set(hash, new Map());
  fallbackCache.get(hash).set(key, value);
}

/**
 * Hash Get All (hgetall)
 */
async function cacheHGetAll(hash) {
  if (isRedisAvailable && redisClient) {
    try {
      const data = await redisClient.hgetall(hash);
      const parsed = {};
      for (const [k, v] of Object.entries(data)) {
        parsed[k] = JSON.parse(v);
      }
      return parsed;
    } catch (e) {}
  }
  
  const map = fallbackCache.get(hash) || new Map();
  return Object.fromEntries(map);
}

/**
 * Hash Get (hget)
 */
async function cacheHGet(hash, key) {
  if (isRedisAvailable && redisClient) {
    try {
      const val = await redisClient.hget(hash, key);
      return val ? JSON.parse(val) : null;
    } catch (e) {}
  }
  
  const map = fallbackCache.get(hash);
  return map ? map.get(key) : null;
}

/**
 * Hash Delete (hdel)
 */
async function cacheHDel(hash, key) {
  if (isRedisAvailable && redisClient) {
    try {
      await redisClient.hdel(hash, key);
      return;
    } catch (e) {}
  }
  
  if (fallbackCache.has(hash)) {
    fallbackCache.get(hash).delete(key);
  }
}

/**
 * Delete key (del)
 */
async function cacheDel(key) {
  if (isRedisAvailable && redisClient) {
    try {
      await redisClient.del(key);
      return;
    } catch (e) {}
  }
  fallbackCache.delete(key);
}


module.exports = {
  initRedis,
  cacheGet,
  cacheSet,
  cacheDel,
  cacheHSet,
  cacheHGet,
  cacheHGetAll,
  cacheHDel,
};
