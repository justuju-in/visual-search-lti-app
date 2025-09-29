# Base stage - shared dependencies
FROM node:18-alpine AS base
WORKDIR /app
COPY /package*.json ./

# Development stage
FROM base AS development
RUN npm install  # Install all dependencies (including devDependencies)
CMD ["npm", "run", "dev"]

# Production dependencies stage
FROM base AS prod-deps
RUN npm ci --only=production && npm cache clean --force

# Build stage
FROM base AS build
RUN npm install
COPY src/ ./
RUN npm run build  # Build your app (if you have a build step)

# Production stage
FROM node:18-alpine AS production
WORKDIR /app

# Create non-root user for security (do this early)
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy production dependencies and built app
COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package*.json ./

USER nodejs

EXPOSE 3001
CMD ["npm", "start"]