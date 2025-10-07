# Visual Search LTI App

Node.js / [ltijs](https://cvmcosta.me/ltijs) **LTI 1.3 tool**, with MongoDB and Traefik for reverse proxy + HTTPS.

---

## 🚀 Quick Start

```bash
# Clone and configure
git clone <repo-url>
cd visual-search-lti-app
cp .env.example .env.local   # for dev
```

**Development** (HTTP, ports exposed):

```bash
make dev
```

* App → [http://localhost:3000](http://localhost:3000)
* Dashboard → [http://localhost:8080/dashboard](http://localhost:8080/dashboard)

**Production** (HTTPS, Traefik + Let’s Encrypt):

```bash
cp .env.example .env   # update domain + secrets
make prod
```

* App → [https://yourdomain.com](https://yourdomain.com)
* Dashboard → [https://yourdomain.com/dashboard](https://yourdomain.com/dashboard)

---

## ⚙️ Config

* `.env.local` → Development (HTTP)
* `.env` → Production (HTTPS)
* `.env.example` → Template (copy & edit)

Key vars:

* `DB_USER`, `DB_PASS`, `DB_NAME` → MongoDB
* `APP_DOMAIN` → App domain (prod)
* `TRAEFIK_ACME_EMAIL` → SSL email
* `LTI_KEY` → JWT secret
* `TOOL_PROVIDER_*` → LTI metadata

---

## 🏗️ Stack

* **MongoDB** – LTI storage
* **Node.js (ltijs)** – LTI provider on port 3000
* **Traefik** – Proxy, HTTPS, dashboard with auth

---

## 📜 Logging

* Dev → console
* Prod → `logs/app.log`

```bash
tail -f logs/app.log
```

Set level with `LOG_LEVEL=debug`.

---

## 🛠️ Makefile Cheatsheet

**Development**

```bash
make dev        # Start dev env
make build      # Build dev images
make down       # Stop dev env
make logs       # Tail all logs
```

**Production**

```bash
make prod       # Start prod env
make prod-build # Build prod images
make prod-down  # Stop prod env
```

**Utilities**

```bash
make status     # Show running containers
make restart-app # Restart Node.js app
make restart-db # Restart MongoDB
make logs-app   # App logs only
make logs-db    # Mongo logs only
make fresh      # Clean & setup fresh dev env
```

