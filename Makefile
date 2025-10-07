.PHONY: help build up down logs clean dev prod backup \
        build-force restart-app restart-db status fresh \
        logs-app logs-db

# ----------------------------
# Docker compose configs
# ----------------------------
DEV_COMPOSE  = -f docker-compose.yml
PROD_COMPOSE = -f docker-compose.yml -f docker-compose.override.yml

# ----------------------------
# Env files
# ----------------------------
ENV_DEV_FILE   = .env.local
ENV_PROD_FILE  = .env

# ----------------------------
# Help
# ----------------------------
help:
	@echo '📦 LTI App Commands'
	@echo ''
	@echo 'Development:'
	@echo '  make dev         - Start dev environment'
	@echo '  make up          - Alias for dev'
	@echo '  make down        - Stop dev environment'
	@echo '  make build       - Build dev images'
	@echo '  make logs        - Tail logs (all services)'
	@echo ''
	@echo 'Production:'
	@echo '  make prod        - Start prod environment'
	@echo '  make prod-build  - Build prod images'
	@echo '  make prod-down   - Stop prod environment'
	@echo ''
	@echo 'Utilities:'
	@echo '  make clean       - Clean dev environment (volumes & orphans)'
	@echo '  make setup       - First-time setup for dev'
	@echo '  make fresh       - Clean & setup from scratch'
	@echo ''
	@echo 'Service-specific:'
	@echo '  make restart-app - Restart only Node.js app'
	@echo '  make restart-db  - Restart only MongoDB'
	@echo '  make logs-app    - Tail logs of Node.js app'
	@echo '  make logs-db     - Tail logs of MongoDB'
	@echo '  make status      - Show running containers'

# ----------------------------
# Development
# ----------------------------
dev:
	@if [ -f $(ENV_DEV_FILE) ]; then \
		echo "🚀 Starting dev with $(ENV_DEV_FILE)"; \
		docker-compose $(DEV_COMPOSE) --env-file $(ENV_DEV_FILE) up -d; \
	else \
		echo "❌ $(ENV_DEV_FILE) not found. Run 'make setup' first."; \
	fi

up: dev ## Alias for dev

build:
	@if [ -f $(ENV_DEV_FILE) ]; then \
		docker-compose $(DEV_COMPOSE) --env-file $(ENV_DEV_FILE) build; \
	else \
		echo "❌ $(ENV_DEV_FILE) not found."; \
	fi

down:
	@if [ -f $(ENV_DEV_FILE) ]; then \
		docker-compose $(DEV_COMPOSE) --env-file $(ENV_DEV_FILE) down; \
	else \
		echo "❌ $(ENV_DEV_FILE) not found."; \
	fi

logs:
	@if [ -f $(ENV_DEV_FILE) ]; then \
		docker-compose $(DEV_COMPOSE) --env-file $(ENV_DEV_FILE) logs -f; \
	else \
		echo "❌ $(ENV_DEV_FILE) not found."; \
	fi

clean: ## Clean dev
	@if [ -f $(ENV_DEV_FILE) ]; then \
		docker-compose $(DEV_COMPOSE) --env-file $(ENV_DEV_FILE) down -v --remove-orphans; \
	fi
	docker system prune -f

setup: ## Initial dev setup
	@echo "🛠️ Setting up LTI App..."
	@if [ ! -f $(ENV_DEV_FILE) ]; then \
		if [ -f .env.example ]; then \
			echo "Creating $(ENV_DEV_FILE) from .env.example..."; \
			cp .env.example $(ENV_DEV_FILE); \
		else \
			echo "❌ .env.example not found!"; \
			exit 1; \
		fi; \
	else \
		echo "✅ $(ENV_DEV_FILE) already exists"; \
	fi
	@echo "📦 Building containers..."
	docker-compose $(DEV_COMPOSE) --env-file $(ENV_DEV_FILE) build
	@echo "🚀 Starting services..."
	docker-compose $(DEV_COMPOSE) --env-file $(ENV_DEV_FILE) up -d
	@echo "✅ Setup complete!"
	@echo "Backend:   http://localhost:$$(grep APP_PORT $(ENV_DEV_FILE) | cut -d '=' -f2)"
	@echo "Traefik:   http://localhost:$$(grep TRAEFIK_DASHBOARD_PORT $(ENV_DEV_FILE) | cut -d '=' -f2)"

build-force:
	docker-compose $(DEV_COMPOSE) --env-file $(ENV_DEV_FILE) build --no-cache

# ----------------------------
# Production
# ----------------------------
prod:
	@if [ -f $(ENV_PROD_FILE) ]; then \
		echo "🚀 Starting prod with $(ENV_PROD_FILE)"; \
		docker-compose $(PROD_COMPOSE) --env-file $(ENV_PROD_FILE) up -d; \
	else \
		echo "❌ $(ENV_PROD_FILE) not found."; \
	fi

prod-build:
	@if [ -f $(ENV_PROD_FILE) ]; then \
		docker-compose $(PROD_COMPOSE) --env-file $(ENV_PROD_FILE) build; \
	else \
		echo "❌ $(ENV_PROD_FILE) not found."; \
	fi

prod-down:
	@if [ -f $(ENV_PROD_FILE) ]; then \
		docker-compose $(PROD_COMPOSE) --env-file $(ENV_PROD_FILE) down; \
	else \
		echo "❌ $(ENV_PROD_FILE) not found."; \
	fi

# ----------------------------
# Service-specific
# ----------------------------
restart-app:
	docker-compose $(DEV_COMPOSE) --env-file $(ENV_DEV_FILE) restart app

restart-db:
	docker-compose $(DEV_COMPOSE) --env-file $(ENV_DEV_FILE) restart mongo

status:
	docker-compose $(DEV_COMPOSE) --env-file $(ENV_DEV_FILE) ps

fresh: clean setup

logs-app:
	docker-compose $(DEV_COMPOSE) --env-file $(ENV_DEV_FILE) logs -f app

logs-db:
	docker-compose $(DEV_COMPOSE) --env-file $(ENV_DEV_FILE) logs -f mongo
