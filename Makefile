SHELL := /bin/bash
APPLICATION_NAME="Trade Remedies Dev Env"

SERVICE_REPO_LIST=trade-remedies-api trade-remedies-caseworker trade-remedies-public
BRANCH='develop'
BASE_PATH='.'
CIRCLECI=t

# Colour coding for output
COLOUR_NONE=\033[0m
COLOUR_GREEN=\033[32;01m
COLOUR_YELLOW=\033[33;01m
COLOUR_RED='\033[0;31m'

.PHONY: help test
help:
	@echo -e "$(COLOUR_GREEN)|--- $(APPLICATION_NAME) [$(APPLICATION_VERSION)] ---|$(COLOUR_NONE)"
	@echo -e "$(COLOUR_YELLOW)Service names are 'api', 'caseworker' and 'public'$(COLOUR_NONE)"
	@echo -e "$(COLOUR_YELLOW)make clone-repos$(COLOUR_NONE) : Clone all service repositories (accepts a 'clonetype' argument which should be set to 'https')"
	@echo -e "$(COLOUR_YELLOW)make build$(COLOUR_NONE) : Run docker-compose build"
	@echo -e "$(COLOUR_YELLOW)make up$(COLOUR_NONE) : Run docker-compose up"
	@echo -e "$(COLOUR_YELLOW)make down$(COLOUR_NONE) : Run docker-compose down"
	@echo -e "$(COLOUR_YELLOW)make start$(COLOUR_NONE) : Run docker-compose start"
	@echo -e "$(COLOUR_YELLOW)make stop$(COLOUR_NONE) : Run docker-compose stop"
	@echo -e "$(COLOUR_YELLOW)make createdb$(COLOUR_NONE) : Create postgres database(s) for the API, API-Testand UAT servers (accepts optional 'db' argument)"
	@echo -e "$(COLOUR_YELLOW)make dropdb$(COLOUR_NONE) : Removes postgres database(s) for the API, API-Testand UAT servers (accepts optional 'db' argument)"
	@echo -e "$(COLOUR_YELLOW)make first-use$(COLOUR_NONE) : Create development environments set up with test data and admin user"
	@echo -e "$(COLOUR_YELLOW)make reseed-api-data$(COLOUR_NONE) : Reseed API development data"
	@echo -e "$(COLOUR_YELLOW)make api-front-end$(COLOUR_NONE) : Run API front end"
	@echo -e "$(COLOUR_YELLOW)make caseworker-front-end-style$(COLOUR_NONE) : Run code quality checks on caseworker front end"
	@echo -e "$(COLOUR_YELLOW)make all-requirements$(COLOUR_NONE) : Generate requirement files for all projects"
	@echo -e "$(COLOUR_YELLOW)make logs$(COLOUR_NONE) : View container logs (accepts a 'service' argument)"
	@echo -e "$(COLOUR_YELLOW)make bash$(COLOUR_NONE) : Start a bash session on a container (requires a 'service' argument)"
	@echo -e "$(COLOUR_YELLOW)make test$(COLOUR_NONE) : Run Django tests (accepts a 'service' and 'test' variable)"
	@echo -e "$(COLOUR_YELLOW)make black$(COLOUR_NONE) : Run black formatter (accepts a 'service' argument)"
	@echo -e "$(COLOUR_YELLOW)make flake8$(COLOUR_NONE) : Run flake8 checks (accepts a 'service' argument)"
	@echo -e "$(COLOUR_YELLOW)make shell$(COLOUR_NONE) : Run a Django shell (accepts a 'service' argument)"
	@echo -e "$(COLOUR_YELLOW)make makemigrations$(COLOUR_NONE) : Run Django makemigrations (accepts the 'service' argument)"
	@echo -e "$(COLOUR_YELLOW)make migrate$(COLOUR_NONE) : Run Django migrate (accepts the 'service' argument)"
	@echo -e "$(COLOUR_YELLOW)make bdd$(COLOUR_NONE) : Run Behave Django BDD tests (requires the 'service' argument)"
	@echo -e "$(COLOUR_YELLOW)make collect-notify-templates$(COLOUR_NONE) : Populates SYS_PARAMS with template names from govuk notify"

clone-repos:
ifdef clonetype
	if [ "$(clonetype)" != "https" ]; then \
		echo -e "$(COLOUR_RED)Please supply 'https' as clonetype value or omit argument to use SSH$(COLOUR_NONE)" ; \
		exit 1; \
	fi;
endif
	@echo -e "$(COLOUR_YELLOW)Fetching and installing repositories...$(COLOUR_NONE)"
	@for repo_name in $(SERVICE_REPO_LIST); do \
			if [ -a $(BASE_PATH)/../$$repo_name ]; then \
					echo -e "$(COLOUR_YELLOW)Repo exists, updating: $$repo_name$(COLOUR_NONE)" ; \
					cd $(BASE_PATH)/../$$repo_name && pwd && git fetch && git checkout $(BRANCH) && git branch && git pull ; \
			else \
					echo -e "$(COLOUR_YELLOW)cloning: $$repo_name$(COLOUR_NONE)" ; \
					if [ "$(clonetype)" ]; then \
						echo -e "$(COLOUR_YELLOW)cloning using https$(COLOUR_NONE)" ; \
						git clone https:uktrade/$$repo_name $(BASE_PATH)/../$$repo_name; \
					else \
						echo -e "$(COLOUR_YELLOW)cloning using SSH$(COLOUR_NONE)" ; \
						git clone git@github.com:uktrade/$$repo_name $(BASE_PATH)/../$$repo_name; \
					fi; \
					cd $(BASE_PATH)/../$$repo_name; \
					git checkout $(BRANCH); \
					cp local.env.example local.env; \
			fi; \
	done

build:
	make down
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

start:
	docker-compose start

stop:
	docker-compose stop

createdb:
ifdef db
	docker-compose exec postgres createdb -h localhost -U postgres -T template0 trade_remedies_$(db)
else
	docker-compose exec postgres createdb -h localhost -U postgres -T template0 trade_remedies_api_test
	docker-compose exec postgres createdb -h localhost -U postgres -T template0 trade_remedies_uat
endif

dropdb:
ifdef db
	docker-compose exec postgres dropdb -h localhost -U postgres trade_remedies_$(db)
else
	docker-compose exec postgres dropdb -h localhost -U postgres trade_remedies_api_test
	docker-compose exec postgres dropdb -h localhost -U postgres trade_remedies_uat
endif

first-use:
	docker-compose exec api python manage.py migrate --noinput
	docker-compose exec public python manage.py migrate --noinput
	docker-compose exec caseworker python manage.py migrate --noinput
	docker-compose exec api python manage.py resetsecurity
	docker-compose exec api sh fixtures.sh
	docker-compose exec api python manage.py load_sysparams
	docker-compose exec api python manage.py adminuser
	docker-compose exec api python manage.py s3credentials
	docker-compose exec api python manage.py collectstatic --noinput
	docker-compose exec public python manage.py collectstatic --noinput
	docker-compose exec caseworker python manage.py collectstatic --noinput



collect-notify-templates:
	docker-compose run --rm api python manage.py notify_env


reseed-api-data:
	docker-compose exec api python manage.py notify_env
	docker-compose exec api bash -c "python manage.py migrate --noinput && python manage.py resetsecurity && sh fixtures.sh && python manage.py load_sysparams && python manage.py adminuser && python manage.py s3credentials && python manage.py collectstatic --noinput"

api-front-end:
	npm run postinstall --prefix trade-remedies-public
	docker-compose run --rm public python manage.py collectstatic

caseworker-front-end-style:
	npm i && npx prettier --check "../trade-remedies-caseworker/trade_remedies_caseworker/templates/{static,sass}/**/*.{scss,js}"

all-requirements:
	cd ../trade-remedies-api && make all-requirements
	cd ../trade-remedies-caseworker && make all-requirements
	cd ../trade-remedies-public && make all-requirements

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
	@echo -e "$(COLOUR_YELLOW)Please supply a service name with the service argument$(COLOUR_NONE)";
endif

test:
ifdef service
	docker-compose run --rm $(service) python manage.py test --verbosity=2 $(test)
else
	docker-compose run --rm api python manage.py test --verbosity=2 $(test)
	docker-compose run --rm public python manage.py test $(test)
	docker-compose run --rm caseworker python manage.py test $(test)
endif

pytest:
ifdef service
	docker-compose run -e $(CIRCLECI) --rm $(service) pytest --ignore=staticfiles -n 4
else
	docker-compose run --rm api pytest --ignore=staticfiles -n 4
	docker-compose run --rm public pytest --ignore=staticfiles -n 4
	docker-compose run --rm caseworker pytest --ignore=staticfiles -n 4
endif

bdd:
ifdef service
	docker-compose exec postgres psql -U postgres -d postgres -c "UPDATE pg_database SET datallowconn = 'false' WHERE datname = 'trade_remedies_api_test';ALTER DATABASE trade_remedies_api_test CONNECTION LIMIT 1;SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'trade_remedies_api_test'" || echo "Database deletion failed"
	docker-compose exec postgres dropdb trade_remedies_api_test -U postgres --if-exists
	docker-compose exec postgres psql -U postgres -d postgres -c "CREATE DATABASE trade_remedies_api_test"
#	Create test state
	docker-compose run --rm apitest python manage.py migrate
	docker-compose exec apitest python manage.py resetsecurity
	docker-compose exec apitest sh fixtures.sh
	docker-compose exec apitest python manage.py load_sysparams
	docker-compose exec apitest python manage.py adminuser
#	backup database. It is restored after each bdd feature.
	docker-compose exec apitest python manage.py dumpdata --all --exclude contenttypes --output /var/backups/api_test.json
	docker-compose exec $(service) sh -c "python manage.py behave --settings=trade_remedies_$(service).settings.bdd --no-capture"
	docker-compose exec postgres psql -U postgres -d postgres -c "UPDATE pg_database SET datallowconn = 'false' WHERE datname = 'trade_remedies_api_test';ALTER DATABASE trade_remedies_api_test CONNECTION LIMIT 1;SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'trade_remedies_api_test'" || echo "Database deletion failed"
	docker-compose exec postgres dropdb trade_remedies_api_test -U postgres --if-exists
else
	echo "$(COLOUR_YELLOW)Please supply a service name with the service argument$(COLOUR_NONE)";
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

shell:
ifdef service
	docker-compose run --rm $(service) python manage.py shell
else
	echo "$(COLOUR_YELLOW)Please supply a service name with the service argument$(COLOUR_NONE)";
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

collectstatic:
ifdef service
	docker-compose run --rm $(service) python manage.py collectstatic --noinput
else
	docker-compose run --rm api python manage.py collectstatic --noinput
	docker-compose run --rm public python manage.py collectstatic --noinput
	docker-compose run --rm caseworker python manage.py collectstatic --noinput
endif
