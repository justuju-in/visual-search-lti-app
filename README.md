

# Visual Search LTI App

Node.js/ltijs-based LTI 1.3 tool with Dockerized deployment, Traefik reverse proxy, and environment-driven configuration.

## Quick Start (Development)

1. **Clone and configure**
   ```bash
   git clone <repo-url>
   cd visual-search-lti-app
   cp .env.dev .env  # Use development settings
   ```

2. **Start services**
   ```bash
   # For development (HTTP, local testing)
   docker compose -f docker-compose.dev.yml up --build
   
   # For production-like testing (HTTPS)
   docker compose up --build
   ```

3. **Access**
   - App: http://localhost:3000 (dev) or http://localhost (prod)
   - Traefik Dashboard: http://localhost/dashboard/ (admin/admin)

## Production Deployment

1. **Set production environment**
   ```bash
   cp .env.prod .env
   # Update APP_DOMAIN, TRAEFIK_ACME_EMAIL, and all credentials
   ```

2. **Deploy with HTTPS**
   ```bash
   docker compose up -d --build
   ```

3. **Access**
   - App: https://yourdomain.com
   - Dashboard: https://yourdomain.com/dashboard/

## Environment Variables

**Required:**
- `DB_USER`, `DB_PASS`, `DB_NAME` - MongoDB credentials
- `LTI_KEY` - JWT secret for LTI
- `APP_DOMAIN` - Your domain name
- `TRAEFIK_ACME_EMAIL` - Email for SSL certificates
- `TOOL_PROVIDER_*` - LTI tool configuration

**Config Files:**
- `.env.dev` - Development (HTTP, direct access)
- `.env.prod` - Production (HTTPS, domain-based)

## Architecture

- **MongoDB** - Database with authentication
- **Node.js App** - LTI 1.3 provider on port 3000
- **Traefik** - Reverse proxy with SSL termination

## Features

- LTI 1.3 dynamic registration
- Grade passback with comments
- Dockerized deployment
- HTTPS with Let's Encrypt
- Password-protected admin dashboard