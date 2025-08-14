

# Visual Search LTI App

This is a Node.js/ltijs-based LTI 1.3 tool with Dockerized MongoDB and environment-driven configuration.

## Quick Start

1. **Clone the repo**
2. **Configure environment variables**
  - Copy `.env.example` to `.env` and set all required values (MongoDB, LTI, tool provider, etc.)
3. **Start MongoDB (Docker)**
  - `docker compose up -d`
4. **Install dependencies**
  - `npm install`
5. **Run the app**
  - `npm start` or `node index.js`

## Environment Variables
All secrets and config are managed via `.env`, `.env.dev`, `.env.prod`.
See `.env.example` for all available options.

## Docker
MongoDB is managed via Docker Compose. All credentials are set via environment variables.

## LTI Platform Registration
Platforms are registered automatically on startup. See `index.js` for details.

## Frontend
The React frontend is served from the `public` directory. No secrets are hardcoded in frontend files.