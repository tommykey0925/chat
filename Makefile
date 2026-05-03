.PHONY: help db db-docs db-docs-diff clean

-include .env
export

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── DB Docs ──

TBLS_VERSION := v1.94.5
TBLS := $(PWD)/bin/tbls
TBLS_OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
TBLS_ARCH := $(shell uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')

FLYWAY_VERSION := 12.5.0
FLYWAY_DIR := $(PWD)/bin/flyway-$(FLYWAY_VERSION)
FLYWAY := $(FLYWAY_DIR)/flyway
FLYWAY_OS := $(shell uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/macosx/')

PG_DSN := jdbc:postgresql://localhost:5432/chat
PG_USER := chat
PG_PASS := chat
PG_TBLS_DSN := postgres://chat:chat@localhost:5432/chat?sslmode=disable

$(TBLS):
	@mkdir -p $(PWD)/bin
	curl -sSL "https://github.com/k1LoW/tbls/releases/download/$(TBLS_VERSION)/tbls_$(TBLS_VERSION)_$(TBLS_OS)_$(TBLS_ARCH).tar.gz" \
		| tar -xz -C $(PWD)/bin tbls
	@chmod +x $(TBLS)

$(FLYWAY):
	@mkdir -p $(PWD)/bin
	curl -sSL "https://github.com/flyway/flyway/releases/download/flyway-$(FLYWAY_VERSION)/flyway-commandline-$(FLYWAY_VERSION)-$(FLYWAY_OS)-x64.tar.gz" \
		| tar -xz -C $(PWD)/bin
	@chmod +x $(FLYWAY)

# NOTE: 同じ Flyway migration 適用ロジックが以下にもある:
#   - .github/workflows/db-docs.yaml の Apply Flyway migrations ステップ
# いずれかを変更したら必ず両方を同期すること。
db: $(FLYWAY) ## Start Postgres + apply Flyway migrations (V1〜V7)
	docker compose -f docker-compose.yaml up -d postgres
	@for i in $$(seq 1 30); do \
		docker compose -f docker-compose.yaml exec -T postgres pg_isready -U $(PG_USER) > /dev/null 2>&1 && break; \
		sleep 1; \
	done
	$(FLYWAY) -url=$(PG_DSN) -user=$(PG_USER) -password=$(PG_PASS) \
		-locations=filesystem:$(PWD)/api/src/main/resources/db/migration \
		migrate

db-docs: db $(TBLS) ## Generate PostgreSQL schema docs (docs-db/schema/)
	@$(TBLS) doc "$(PG_TBLS_DSN)" --force

db-docs-diff: db $(TBLS) ## Show diff between docs-db/schema/ and live Postgres
	@$(TBLS) diff "$(PG_TBLS_DSN)"

# ── Cleanup ──

clean: ## Stop Postgres container (Redis / ES は残す)
	docker compose -f docker-compose.yaml stop postgres
