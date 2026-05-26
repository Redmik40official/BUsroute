# Stage 1: Build
FROM node:18-alpine AS builder

# Install OpenSSL for Prisma
RUN apk add --update --no-cache openssl

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies (including devDependencies for Prisma)
# Using npm install instead of npm ci to prevent lockfile sync issues across OS
RUN npm install

# Generate Prisma Client
RUN npx prisma generate

# Create SQLite schema in the builder stage
ENV DATABASE_URL="file:///app/data/aurcm.db"
RUN mkdir -p /app/data && npx prisma db push --accept-data-loss

# Copy source code
COPY . .

# Stage 2: Production
FROM node:18-alpine

RUN apk add --update --no-cache openssl

WORKDIR /app

# Copy built node_modules and Prisma generated client
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/src ./src
COPY --from=builder /app/data ./data
COPY --from=builder /app/server.js ./

# Fix SQLite permissions for Render's non-root user
RUN chmod -R 777 /app/data

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV DATABASE_URL="file:///app/data/aurcm.db"

# Expose port
EXPOSE 3000

# Start server directly (schema is already baked into the SQLite file)
CMD ["node", "server.js"]
