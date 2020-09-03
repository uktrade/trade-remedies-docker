SHELL := /bin/bash
APPLICATION_NAME="Trade Remedies Dev Env"
APPLICATION_VERSION=1.0

# Github variables
GITHUB_USER_NAME='uktrade'
SERVICE_REPO_LIST=$(shell cat repositories.txt)
BASE_PATH=$(shell pwd)
BRANCH='develop'

# Colour coding for output
COLOUR_NONE=\033[0m
COLOUR_GREEN=\033[32;01m
COLOUR_YELLOW=\033[33;01m


.PHONY: help install update restart
help:
	@echo -e "$(COLOUR_GREEN)|--- $(APPLICATION_NAME) [$(APPLICATION_VERSION)] ---|$(COLOUR_NONE)"
	@echo -e "$(COLOUR_YELLOW)make install$(COLOUR_NONE) : Install or update all services"
	@echo -e "$(COLOUR_YELLOW)make start$(COLOUR_NONE) : Start all docker containers"
	@echo -e "$(COLOUR_YELLOW)make install BRANCH=branch_name$(COLOUR_NONE) : Update services using specific branch"
	@echo -e "$(COLOUR_YELLOW)make restart$(COLOUR_NONE) : Stop, remove and relaunch all docker containers"
	@echo -e "$(COLOUR_YELLOW)make build$(COLOUR_NONE) : Stop, (re)build and restart all docker containers"
	@echo -e "$(COLOUR_YELLOW)make logs$(COLOUR_NONE) : Attach to logs for all running container"

install:
	@echo -e "$(COLOUR_YELLOW)Fetching and installing repositories...$(COLOUR_NONE)"
	@for repo_name in $(SERVICE_REPO_LIST); do \
			if [ -a $(BASE_PATH)/../$$repo_name ]; then \
					echo -e "$(COLOUR_YELLOW)Repo exists, updating: $$repo_name$(COLOUR_NONE)" ; \
					cd $(BASE_PATH)/../$$repo_name && pwd && git fetch && git checkout $(BRANCH) && git branch && git pull ; \
			else \
					echo -e "$(COLOUR_YELLOW)cloning: $$repo_name$(COLOUR_NONE)" ; \
					git clone git@github.com:$(GITHUB_USER_NAME)/$$repo_name.git $(BASE_PATH)/../$$repo_name; \
			fi; \
	done

restart:
		@echo -e "$(COLOUR_YELLOW)Restarting containers...$(COLOUR_NONE)"
		@docker-compose down
		@docker-compose up -d

start:
		@docker-compose up -d

logs:
		@docker-compose logs --tail=0 --follow

stop:
		@docker-compose down

build:
		@docker-compose stop ${service}
		@docker-compose build ${service}
		@docker-compose up --no-deps ${service}
