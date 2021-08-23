COMPOSE_FILE := --file docker-compose.yml --file docker-compose.override.yml --file docker-compose/mailhog.override.yml
IS_RUNNING := $(shell docker inspect canvas_web 2>/dev/null | grep "Running" | xargs | sed "s/.$$//")
RUNNING = Running: true
$(if $(IS_RUNNING), $(info ### canvas_web container ${IS_RUNNING} ###), $(info ### canvas_lms container Running: false ###))

setup:
	bash ./script/docker_dev_setup.sh

update:
	bash ./script/docker_dev_update.sh

build:
	docker-compose $(COMPOSE_FILE) build --pull $(filter-out $@,$(MAKECMDGOALS))

up:
	docker-compose $(COMPOSE_FILE) up -d $(filter-out $@,$(MAKECMDGOALS))

recreate: # to recreate containers after any update
	docker-compose $(DEVLOPMENT_COMPOSE_FILE) up -d --force-recreate $(filter-out $@,$(MAKECMDGOALS))

logs:
	docker-compose $(COMPOSE_FILE) logs --follow $(filter-out $@,$(MAKECMDGOALS))

down:
	docker-compose $(COMPOSE_FILE) down $(filter-out $@,$(MAKECMDGOALS))

destroy:
	docker-compose $(COMPOSE_FILE) down -v

debug_web:
	docker-compose $(COMPOSE_FILE) exec web bin/byebug-remote

debug_jobs:
	docker-compose $(COMPOSE_FILE) exec jobs bin/byebug-remote

bash:
ifeq ($(IS_RUNNING), $(RUNNING))
	docker-compose $(COMPOSE_FILE) exec web bash $(filter-out $@,$(MAKECMDGOALS))
else
	docker-compose $(COMPOSE_FILE) run --rm web bash $(filter-out $@,$(MAKECMDGOALS))
endif

rails_generate:
ifeq ($(IS_RUNNING), $(RUNNING))
	docker-compose $(COMPOSE_FILE) exec web bundle exec rails generate $(filter-out $@,$(MAKECMDGOALS))
else
	docker-compose $(COMPOSE_FILE) run --rm web bundle exec rails generate $(filter-out $@,$(MAKECMDGOALS))
endif

migrate:
ifeq ($(IS_RUNNING), $(RUNNING))
	docker-compose $(COMPOSE_FILE) exec web bundle exec rake db:migrate $(filter-out $@,$(MAKECMDGOALS))
else
	docker-compose $(COMPOSE_FILE) run --rm web bundle exec rake db:migrate $(filter-out $@,$(MAKECMDGOALS))
endif

rspec:
ifeq ($(IS_RUNNING), $(RUNNING))
	docker-compose $(COMPOSE_FILE) exec web bundle exec rspec spec $(filter-out $@,$(MAKECMDGOALS))
else
	docker-compose $(COMPOSE_FILE) run --rm web bundle exec rspec spec $(filter-out $@,$(MAKECMDGOALS))
endif
