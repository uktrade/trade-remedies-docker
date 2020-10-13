APPLICATION_NAME="Trade Remedies Dev Env"

GITHUB_USER_NAME='rossmiller'
SERVICE_REPO_LIST=trade-remedies-api trade-remedies-caseworker trade-remedies-public
BRANCH='develop'
BASE_PATH='.'

# Colour coding for output
COLOUR_NONE=\033[0m
COLOUR_GREEN=\033[32;01m
COLOUR_YELLOW=\033[33;01m

.PHONY: help test
help:
	@echo -e "$(COLOUR_GREEN)|--- $(APPLICATION_NAME) [$(APPLICATION_VERSION)] ---|$(COLOUR_NONE)"
	@echo -e "$(COLOUR_YELLOW)Service names are 'api', 'caseworker' and 'public'$(COLOUR_NONE)"
	@echo -e "$(COLOUR_YELLOW)make clone-repos$(COLOUR_NONE) : Clone all service repositories"
	@echo -e "$(COLOUR_YELLOW)make test$(COLOUR_NONE) : Run Django tests (accepts a 'service' and 'test' variable)"
	@echo -e "$(COLOUR_YELLOW)make black$(COLOUR_NONE) : Run black formatter (accepts a 'service' variable)"
	@echo -e "$(COLOUR_YELLOW)make flake8$(COLOUR_NONE) : Run flake8 checks (accepts a 'service' variable)"
	@echo -e "$(COLOUR_YELLOW)make bash$(COLOUR_NONE) : Start a bash session on a container (requires a 'service' variable)"
	@echo -e "$(COLOUR_YELLOW)make build$(COLOUR_NONE) : Run docker-compose build"
	@echo -e "$(COLOUR_YELLOW)make up$(COLOUR_NONE) : Run docker-compose up"
	@echo -e "$(COLOUR_YELLOW)make makemigrations$(COLOUR_NONE) : Run Django makemigrations (accepts the 'service' variable)"
	@echo -e "$(COLOUR_YELLOW)make migrate$(COLOUR_NONE) : Run Django migrate (accepts the 'service' variable)"

clone-repos:
	@echo -e "$(COLOUR_YELLOW)Fetching and installing repositories...$(COLOUR_NONE)"
	@for repo_name in $(SERVICE_REPO_LIST); do \
			if [ -a $(BASE_PATH)/../$$repo_name ]; then \
					echo -e "$(COLOUR_YELLOW)Repo exists, updating: $$repo_name$(COLOUR_NONE)" ; \
					cd $(BASE_PATH)/../$$repo_name && pwd && git fetch && git checkout $(BRANCH) && git branch && git pull ; \
			else \
					echo -e "$(COLOUR_YELLOW)cloning: $$repo_name$(COLOUR_NONE)" ; \
					git clone https://github.com/uktrade/$$repo_name $(BASE_PATH)/../$$repo_name; \
					cd $(BASE_PATH)/../$$repo_name; \
					git checkout $(BRANCH); \
					cp local.env.example local.env; \
			fi; \
	done

build:
	docker-compose build

up:
	docker-compose up

down:
	docker-compose down

start:
	docker-compose start

stop:
	docker-compose stop

first-use:
	docker-compose down
	docker-compose build
	docker-compose run --rm api python manage.py migrate --noinput
	docker-compose run --rm public python manage.py migrate --noinput
	docker-compose run --rm caseworker python manage.py migrate --noinput
	docker-compose run --rm api python manage.py resetsecurity
	docker-compose run --rm api sh fixtures.sh
	docker-compose run --rm api python manage.py load_sysparams
	docker-compose run --rm api python manage.py adminuser
	docker-compose run --rm api python manage.py s3credentials
	docker-compose run --rm api python manage.py collectstatic --noinput
	docker-compose run --rm public python manage.py collectstatic --noinput
	docker-compose run --rm caseworker python manage.py collectstatic --noinput
	docker-compose --rm up

api-front-end:
	npm run postinstall --prefix trade-remedies-public
	docker-compose run --rm public python manage.py collectstatic

caseworker-front-end-style:
	npm i && npx prettier --check "../trade-remedies-caseworker/trade_remedies_caseworker/templates/{static,sass}/**/*.{scss,js}"

logs:
ifdef service
	docker-compose logs -f -t $(service)
else
	docker-compose logs -f -t
endif

bash:
ifdef service
	docker-compose run --rm $(service) bash
else
	echo "$(COLOUR_YELLOW)Please supply a service name with the service argument$(COLOUR_NONE)";
endif

test:
ifdef service
	docker-compose run --rm $(service) test $(test)
else
	docker-compose run --rm api test $(test)
	docker-compose run --rm public test $(test)
	docker-compose run --rm caseworker test $(test)
endif

pytest:
ifdef service
	docker-compose run --rm $(service) pytest --ignore=staticfiles -n 4
else
	docker-compose run --rm api pytest --ignore=staticfiles -n 4
	docker-compose run --rm public pytest --ignore=staticfiles -n 4
	docker-compose run --rm caseworker pytest --ignore=staticfiles -n 4
endif

black:
ifdef service
	docker-compose run --rm $(service) black .
else
	docker-compose run --rm api black .
	docker-compose run --rm public black .
	docker-compose run --rm caseworker black .
endif

flake8:
ifdef service
	docker-compose run --rm $(service) flake8
else
	docker-compose run --rm api flake8
	docker-compose run --rm public flake8
	docker-compose run --rm caseworker flake8
endif

migrations:
ifdef service
	docker-compose run --rm $(service) python manage.py makemigrations --noinput
else
	docker-compose run --rm api python manage.py makemigrations --noinput
	docker-compose run --rm public python manage.py makemigrations --noinput
	docker-compose run --rm caseworker python manage.py makemigrations --noinput
endif

migrate:
ifdef service
	docker-compose run --rm $(service) python manage.py migrate --noinput
else
	docker-compose run --rm api python manage.py migrate --noinput
	docker-compose run --rm public python manage.py migrate --noinput
	docker-compose run --rm caseworker python manage.py migrate --noinput
endif
