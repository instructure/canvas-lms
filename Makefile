SHELL := /bin/bash

DOCKER ?= docker
COMPOSE ?= $(DOCKER) compose
STACK_FILE := .canvas-stack
STACK_HISTORY_FILE := .canvas-stack.last
STACK_ORIGIN_INPUT := $(origin STACK)
RAILS_ENV ?= development
LOCAL_SKIP_SERVICE_CHECK ?= 0
TF_K8S_DIR := infra/terraform/k8s
HELM_CHART_DIR := kube/helm/canvas
HELM_RELEASE ?= canvas
HELM_NAMESPACE ?= canvas-dev
HELM_VALUES ?=
TF_APPLY_ARGS ?=
TF_DESTROY_ARGS ?=
K8S_PORT ?= 3000
K8S_IMAGE_REPO ?= canvas-lms
K8S_IMAGE_TAG ?=
K8S_DOCKERFILE ?= Dockerfile.alpine

ifeq ($(STACK_ORIGIN_INPUT),default)
STACK := $(if $(wildcard $(STACK_FILE)),$(shell cat $(STACK_FILE)),default)
STACK := $(if $(filter default,$(STACK)),$(if $(wildcard $(STACK_HISTORY_FILE)),$(shell cat $(STACK_HISTORY_FILE)),default),$(STACK))
else
STACK := $(strip $(STACK))
endif

STACK := $(strip $(STACK))
ifeq ($(STACK),)
STACK := default
endif
STACK_NORMALIZED := $(shell printf '%s' "$(STACK)" | tr '[:upper:]' '[:lower:]')

ifneq ($(filter $(STACK_NORMALIZED),default arch alpine),$(STACK_NORMALIZED))
$(error Unknown STACK '$(STACK)'. Supported values: default, arch, alpine)
endif

STACK_USER_OVERRIDE := $(if $(filter undefined default,$(STACK_ORIGIN_INPUT)),0,1)

SERVICE ?=

define DEFAULT_ADMIN_PASSWORD
CanvasAdmin#2025
endef
PASSWORD ?= $(strip $(DEFAULT_ADMIN_PASSWORD))

.PHONY: help dev dev-setup dev-build dev-up dev-up-detached dev-stop dev-down dev-restart dev-logs dev-shell dev-migrate dev-admin dev-helper
.PHONY: local-env-check local-setup local-server local-webpack local-jobs local-services
.PHONY: k8s-init k8s-apply k8s-destroy k8s-build-helm-install k8s-helm-install k8s-helm-upgrade k8s-helm-uninstall k8s-port-forward
.PHONY: set-stack dev-setup-legacy

define SELECT_STACK
STACK_PROMPT="$1"; \
if [ "$(STACK_USER_OVERRIDE)" = "1" ]; then \
  STACK_CHOICE="$(STACK)"; \
else \
  STACK_CHOICE=$$(STACK_PERSISTED_PATH="$(STACK_FILE)" STACK_HISTORY_PATH="$(STACK_HISTORY_FILE)" STACK_SOURCE_VALUE="$(STACK)" ./script/stack_manager.sh --prompt "$$STACK_PROMPT" --default "$(STACK)"); \
fi; \
echo "$$STACK_CHOICE" > "$(STACK_HISTORY_FILE)"; \
case "$$STACK_CHOICE" in \
  arch) COMPOSE_ARGS="-f docker-compose.arch.yml" ;; \
  alpine) COMPOSE_ARGS="-f docker-compose.alpine.yml" ;; \
  *) COMPOSE_ARGS="" ;; \
esac; \
STACK_DESC="$$STACK_CHOICE";
endef

help:
	@echo ""
	@echo "Canvas LMS development helpers"
	@echo "--------------------------------"
	@echo "Recommended entry points:"
	@echo "  make dev-setup        # Guided Docker setup (TUI) with start/stop options"
	@echo "  make dev              # Canvas Dev Toolbox TUI for day-to-day tasks"
	@echo ""
	@echo "Docker utilities (advanced):"
	@echo "  make dev-build        # Build/rebuild the selected compose services"
	@echo "  make dev-up           # Start services in the foreground"
	@echo "  make dev-up-detached  # Start services in the background"
	@echo "  make dev-stop         # Stop running containers"
	@echo "  make dev-down         # Stop containers and remove compose-managed networks"
	@echo "  make dev-restart      # Restart web/jobs/webpack services"
	@echo "  make dev-logs [SERVICE=web]   # Tail logs for all services or a specific one"
	@echo "  make dev-shell [SERVICE=web]  # Open a bash shell in the given service container"
	@echo "  make dev-migrate      # Run Rails database migrations"
	@echo "  make dev-admin EMAIL=you@example.com [PASSWORD=...]  # Create or update an admin user"
	@echo "  make set-stack        # Persist the preferred docker stack (interactive)"
	@echo "  make dev-setup-legacy # Run the original shell-based docker setup"
	@echo "  make k8s-build-helm-install # Build a Docker image and helm upgrade --install it"
	@echo "  make k8s-helm-install # helm upgrade --install the bundled chart"
	@echo "  make k8s-helm-uninstall # helm uninstall the release"
	@echo "  make k8s-port-forward # Port-forward the web service to localhost"
	@echo "  make k8s-apply        # Deploy the Helm chart via Terraform"
	@echo "  make k8s-destroy      # Remove the Helm release via Terraform"
	@echo ""
	@echo "Local (non-docker) helpers:"
	@echo "  make local-env-check  # Verify required binaries exist for local development"
	@echo "  make local-setup      # Copy configs, install deps, and prepare databases locally"
	@echo "  make local-services   # Run Rails + webpack concurrently (requires foreman or overmind)"
	@echo "  make local-server     # Start only the Rails server"
	@echo "  make local-webpack    # Start only the frontend watcher"
	@echo "  make local-jobs       # Start delayed_job workers"
	@echo ""

set-stack:
	@$(call SELECT_STACK,Select default docker stack) \
	  echo "$$STACK_CHOICE" > "$(STACK_FILE)"; \
	  echo "Default docker stack saved to $(STACK_FILE): $$STACK_CHOICE"

dev-setup:
	@if command -v go >/dev/null 2>&1; then \
	  echo "Launching Canvas Docker setup (TUI)..."; \
	  GOCACHE="$(PWD)/.gocache" GOMODCACHE="$(PWD)/.gomodcache" go run ./script/docker-dev-setup; \
	else \
	  echo "Go not found in PATH. Falling back to legacy shell script."; \
	  ./script/docker_dev_setup.sh; \
	fi

dev-setup-legacy:
	./script/docker_dev_setup.sh

dev-build:
	@$(call SELECT_STACK,Select docker stack for dev-build) \
	  echo "Building services with $$STACK_DESC stack..."; \
	  $(COMPOSE) $$COMPOSE_ARGS build

dev-up:
	@$(call SELECT_STACK,Select docker stack for dev-up) \
	  echo "Starting services with $$STACK_DESC stack..."; \
	  $(COMPOSE) $$COMPOSE_ARGS up

dev-up-detached:
	@$(call SELECT_STACK,Select docker stack for dev-up-detached) \
	  echo "Starting services (detached) with $$STACK_DESC stack..."; \
	  $(COMPOSE) $$COMPOSE_ARGS up -d

dev-stop:
	@$(call SELECT_STACK,Select docker stack for dev-stop) \
	  echo "Stopping services for $$STACK_DESC stack..."; \
	  $(COMPOSE) $$COMPOSE_ARGS stop

dev-down:
	@$(call SELECT_STACK,Select docker stack for dev-down) \
	  echo "Stopping and cleaning up services for $$STACK_DESC stack..."; \
	  $(COMPOSE) $$COMPOSE_ARGS down

dev-restart:
	@$(call SELECT_STACK,Select docker stack for dev-restart) \
	  echo "Restarting web, jobs, and webpack services for $$STACK_DESC stack..."; \
	  $(COMPOSE) $$COMPOSE_ARGS restart web jobs webpack

dev-logs:
	@$(call SELECT_STACK,Select docker stack for dev-logs) \
	  echo "Tailing logs for $$STACK_DESC stack$(if $(SERVICE), service $(SERVICE),)..."; \
	  $(COMPOSE) $$COMPOSE_ARGS logs -f $(SERVICE)

dev-shell:
	@$(call SELECT_STACK,Select docker stack for dev-shell) \
	  if [ -z "$(SERVICE)" ]; then service=web; else service="$(SERVICE)"; fi; \
	  echo "Opening shell in $$service (stack: $$STACK_DESC)..."; \
	  $(COMPOSE) $$COMPOSE_ARGS run --rm "$$service" bash

dev-migrate:
	@$(call SELECT_STACK,Select docker stack for dev-migrate) \
	  echo "Running database migrations via web service (stack: $$STACK_DESC)..."; \
	  $(COMPOSE) $$COMPOSE_ARGS run --rm web bundle exec rake db:migrate

dev-helper:
	@./script/dev_toolbox.sh

dev: dev-helper

dev-admin:
	@if [ -z "$(EMAIL)" ]; then \
	  echo "EMAIL is required. Usage: make dev-admin EMAIL=you@example.com [PASSWORD=...] [STACK=arch|alpine]"; \
	  exit 1; \
	fi
	@$(call SELECT_STACK,Select docker stack for dev-admin) \
	  echo "Ensuring admin user $(EMAIL) exists (stack: $$STACK_DESC)..."; \
	  $(COMPOSE) $$COMPOSE_ARGS run --rm \
	  -e CANVAS_LMS_ADMIN_EMAIL="$(EMAIL)" \
	  -e CANVAS_LMS_ADMIN_PASSWORD="$(PASSWORD)" \
	  web bundle exec rake db:configure_admin

local-env-check:
	@missing=0; \
	services=0; \
	for bin in pg_isready redis-cli bundle yarn node; do \
	  if ! command -v $$bin >/dev/null 2>&1; then \
	    echo "Missing required binary: $$bin"; \
	    missing=1; \
	  fi; \
	done; \
	if [ $$missing -ne 0 ]; then \
	  echo ""; \
	  echo "Install the missing dependencies (PostgreSQL client, Redis, Ruby/Bundler, Node, Yarn) and try again."; \
	  exit 1; \
	fi; \
	if [ "$(LOCAL_SKIP_SERVICE_CHECK)" != "1" ]; then \
	  if command -v pg_isready >/dev/null 2>&1; then \
	    if ! pg_isready >/dev/null 2>&1; then \
	      echo "PostgreSQL does not appear to be running (pg_isready failed). Start it or set LOCAL_SKIP_SERVICE_CHECK=1 to skip."; \
	      services=1; \
	    fi; \
	  fi; \
	  if command -v redis-cli >/dev/null 2>&1; then \
	    if ! redis-cli ping >/dev/null 2>&1; then \
	      echo "Redis is not responding to 'redis-cli ping'. Start it or set LOCAL_SKIP_SERVICE_CHECK=1 to skip."; \
	      services=1; \
	    fi; \
	  fi; \
	fi; \
	if [ $$services -ne 0 ]; then \
	  echo ""; \
	  echo "Local services appear to be offline. Ensure PostgreSQL/Redis are running, or export LOCAL_SKIP_SERVICE_CHECK=1 to bypass this check."; \
	  exit 1; \
	fi; \
	echo "Local environment prerequisites detected."

local-setup: local-env-check
	@echo "Copying default config templates (if missing)..."
	@bash -c 'set -euo pipefail; \
	  find config -type f \( -name "*.yml.example" -o -name "*.yml.sample" \) | while read -r template; do \
	    target="$${template%.example}"; \
	    target="$${target%.sample}"; \
	    if [ ! -f "$$target" ]; then \
	      mkdir -p "$$(dirname "$$target")"; \
	      cp "$$template" "$$target"; \
	      echo "  created $$target"; \
	    fi; \
	  done; \
	'
	@if [ -f config/database.yml ] && grep -q "your_password" config/database.yml; then \
	  echo "⚠  Update config/database.yml with your local PostgreSQL credentials."; \
	fi
	@echo "Installing Ruby gems..."
	@bundle check >/dev/null 2>&1 || bundle install
	@echo "Installing Node packages..."
	@YARN_ENABLE_IMMUTABLE_INSTALLS=0 yarn install
	@echo "Preparing development and test databases..."
	@bundle exec rails db:prepare || { \
	  echo ""; \
	  echo "Database preparation failed. Confirm PostgreSQL credentials in config/database.yml and that the role has privileges."; \
	  exit 1; \
	}
	@bundle exec rails db:initial_setup || { \
	  echo ""; \
	  echo "Initial setup failed. You may need to rerun manually after adjusting configuration."; \
	  exit 1; \
	}
	@echo ""
	@echo "Local setup complete. Launch services with 'make local-services' or run individual targets."

local-server: local-env-check
	@echo "Starting Rails server without Docker (CTRL+C to stop)..."
	RAILS_ENV=$(RAILS_ENV) bundle exec rails server -b 0.0.0.0 -p $${PORT:-3000}

local-webpack: local-env-check
	@echo "Starting frontend watcher (rspack) without Docker..."
	YARN_ENABLE_IMMUTABLE_INSTALLS=0 yarn webpack-development

local-jobs: local-env-check
	@echo "Starting delayed_job worker without Docker..."
	RAILS_ENV=$(RAILS_ENV) bundle exec script/delayed_job run

local-services: local-env-check
	@if command -v overmind >/dev/null 2>&1; then \
	  OVERMIND_NO_PORT=1 overmind start -f Procfile.local; \
	elif command -v foreman >/dev/null 2>&1; then \
	  foreman start -f Procfile.local; \
	else \
	  echo "Procfile runner (overmind or foreman) not found. Install one or run targets individually."; \
	  exit 1; \
	fi

k8s-init:
	terraform -chdir=$(TF_K8S_DIR) init

k8s-apply: k8s-init
	terraform -chdir=$(TF_K8S_DIR) apply $(TF_APPLY_ARGS)

k8s-destroy: k8s-init
	terraform -chdir=$(TF_K8S_DIR) destroy $(TF_DESTROY_ARGS)

k8s-build-helm-install:
	@set -euo pipefail; \
	  image_repo="$(K8S_IMAGE_REPO)"; \
	  dockerfile="$(K8S_DOCKERFILE)"; \
	  if [ -z "$$dockerfile" ]; then dockerfile="Dockerfile.alpine"; fi; \
	  image_tag="$(K8S_IMAGE_TAG)"; \
	  if [ -z "$$image_tag" ]; then image_tag="dev-$$(date -u +%Y%m%d%H%M%S)"; fi; \
	  build_date=$$(date -u +%Y-%m-%dT%H:%M:%SZ); \
	  cache_bust=$$(date +%s); \
	  vcs_ref=$$(git rev-parse HEAD); \
	  needs_load=1; \
	  if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then \
	    echo "Building $$image_repo:$$image_tag using $$dockerfile inside the minikube Docker daemon..."; \
	    echo "+ eval \"$$(minikube docker-env --shell=bash)\" && $(DOCKER) build --build-arg CACHE_BUST=$$cache_bust --build-arg BUILD_DATE=$$build_date --build-arg VCS_REF=$$vcs_ref -t $$image_repo:$$image_tag -f $$dockerfile ."; \
	    eval "$$(minikube docker-env --shell=bash)"; \
	    $(DOCKER) build \
	      --build-arg CACHE_BUST=$$cache_bust \
	      --build-arg BUILD_DATE=$$build_date \
	      --build-arg VCS_REF=$$vcs_ref \
	      -t "$$image_repo:$$image_tag" \
	      -f "$$dockerfile" .; \
	    eval "$$(minikube docker-env --shell=bash -u)"; \
	    needs_load=0; \
	  else \
	    echo "Building $$image_repo:$$image_tag using $$dockerfile with docker..."; \
	    echo "+ $(DOCKER) build --build-arg CACHE_BUST=$$cache_bust --build-arg BUILD_DATE=$$build_date --build-arg VCS_REF=$$vcs_ref -t $$image_repo:$$image_tag -f $$dockerfile ."; \
	    $(DOCKER) build \
	      --build-arg CACHE_BUST=$$cache_bust \
	      --build-arg BUILD_DATE=$$build_date \
	      --build-arg VCS_REF=$$vcs_ref \
	      -t "$$image_repo:$$image_tag" \
	      -f "$$dockerfile" .; \
	  fi; \
	  if [ "$$needs_load" -eq 1 ] && command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then \
	    echo "Loading $$image_repo:$$image_tag into minikube image store..."; \
	    if ! minikube image load "$$image_repo:$$image_tag"; then \
	      echo "minikube image load failed; attempting docker save | minikube image load fallback..."; \
	      $(DOCKER) image save "$$image_repo:$$image_tag" | minikube image load - || echo "Warning: failed to load image into minikube (continuing)"; \
	    fi; \
	  fi; \
	  echo "Deploying Helm release $(HELM_RELEASE) (namespace $(HELM_NAMESPACE)) with image $$image_repo:$$image_tag..."; \
	  helm upgrade --install $(HELM_RELEASE) $(HELM_CHART_DIR) \
	    --namespace $(HELM_NAMESPACE) \
	    --create-namespace \
	    --set image.repository=$$image_repo \
	    --set image.tag=$$image_tag \
	    $(if $(HELM_VALUES),$(foreach file,$(HELM_VALUES),-f $(file)))

k8s-helm-install:
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART_DIR) \
	--namespace $(HELM_NAMESPACE) \
	--create-namespace \
	$(if $(HELM_VALUES),$(foreach file,$(HELM_VALUES),-f $(file)))

k8s-helm-upgrade:
	helm upgrade $(HELM_RELEASE) $(HELM_CHART_DIR) \
	--namespace $(HELM_NAMESPACE) \
	$(if $(HELM_VALUES),$(foreach file,$(HELM_VALUES),-f $(file)))

k8s-helm-uninstall:
	helm uninstall $(HELM_RELEASE) --namespace $(HELM_NAMESPACE)

k8s-port-forward:
	kubectl -n $(HELM_NAMESPACE) port-forward svc/$(HELM_RELEASE)-canvas-web $(K8S_PORT):3000
