# trade-remedies-docker
Master repo for building trade remedies system for local development.

This repository provides a dockerised environment that can fetch, build and
start all the Trade Remedies applications and support systems. This includes
the Trade Remedies services `api`, `caseworker` and `public` and supporting
services for `postgres`, `redis`, `elasticsearch` and `celery`. To support BDD
testing the services `apitest`, `selenium-hub` and `chrome` are also spun up.

**This approach MUST be used for all local development.** If you have issues getting set up,
please speak to a colleague on the Live Services Team.

## Makefile
This project's `Makefile` provides an interface to manage this environment.
To see a list of available commands run:

    make help

The following sections describes the commands required to get up and running.

## First run
In a working directory run: 

    make clone-repos

This uses a SSH git clone by default. Run the following command if you want
to use https then run:

    make clone-repos clonetype=https

### Build and initialise services
You need to build and configure all the services for first use, simply run:

    make first-use

## Required manual configuration
In order to operate each service locally it's *very important* to populate each project's
`trade-remedies-*/local.env` file with suitable values. Copy the example
`trade-remedies-*/local.env.example` to get started.

See the inline comments in the files in the individual repositories and reach out to
colleagues for API keys etc.

### Set up the API tokens
You need to define an API token for the Public and Caseworker services, so
they can make authenticated calls to the trade_remedies_api service.  You can
do this by setting the `HEALTH_CHECK_TOKEN` value in the `local.env` file.

> There is a Django setting used by the API Client (employed by both
public and caseworker portals) called `TRUSTED_USER_TOKEN` but this is
simply set from the `HEALTH_CHECK_TOKEN` environment variable.

The `make first-use` operation invokes `manage.py adminuser`, which will set
up a user and auth-token according to the `HEALTH_CHECK_USER_EMAIL` and
`HEALTH_CHECK_USER_TOKEN` values defined in the `local.env` file in the
trade_remedies_api project. If you copied the example `local.env.example`
then it will be something like:

- name: `Health Check`
- email: `_healthcheckuser_@gov.uk` (Value of `HEALTH_CHECK_USER_EMAIL` env var)
- token: `AUTH-TOKEN-FOR-TRUSTED-USER` (Value of `HEALTH_CHECK_USER_TOKEN` env var)

You can also find the token value in the Django Admin portal at
`http://localhost:8000/admin`. Log in using the values for `MASTER_ADMIN_EMAIL`
and `MASTER_ADMIN_PASSWORD` environment variables (e.g. `admin@mylocaltrade.
com/change-Me`). Navigate to `http://localhost:8000/admin/authtoken/token/`
and copy the token value for `HEALTH_CHECK_USER_EMAIL` user.

Use the token value from the trade_remedies_api project to set
`HEALTH_CHECK_TOKEN` in the trade_remedies_public and trade_remedies_caseworker
`local.env` file.

### Update notification template IDs
Hopefully you've defined the `GOV_NOTIFY_API_KEY` in the `trade-remedies-api/local.env` file.
If not, do it now, so that the API service can leverage the
[GOV.UK Notify](https://www.notifications.service.gov.uk) notification service.

To ensure your local system is configured to use the template IDs available in
the notification service environment targeted by your `GOV_NOTIFY_API_KEY`
you need to run the `notify_env` management command as follows:
   
    make collect-notify-templates

This will update the local database to match the template IDs available.
 
## Compiling requirements
We use [pip-compile](https://github.com/jazzband/pip-tools) to manage pip dependencies. If you add
any new dependencies you should add them to the relevant project's `requirements.in`, then
(in this project) run:

    make all-requirements

Make sure this is run from your host machine as it does not run in a container.

## BDD testing
Behavioural testing is provided by [Behave Django](https://github.com/behave/behave-django)
and can be triggered by running:

    make bdd

This creates a test database (that is used by the `apitest` container), runs migrations and then
initialises BDD tests.

When running from within a BDD test, if the public or caseworker sites access the API, they access
an endpoint on the `apitest` container (rather than the `api` container, as is usually the case).

This means that BDD tests are completely siloed from local development infrastructure and can be run
in parallel without affecting your local data.

The `apitest` container is configured to allow access to test object creation endpoints that are
excluded from other configurations.

For this reason, the `api_test` app in the API project should never be added to non-test Django
configurations.

> NB: For the BDD tests to execute, the all service containers need to be
> running, i.e. execute the `make up` command.

## Sites

| Address | Site |
| ------------- | ------------- |
| `http://localhost:8000` | API |
| `http://localhost:8001` | Caseworker site |
| `http://localhost:8002` | Public site |

## Known issues

If, when first accessing the caseworker site, you receive a forbidden message, you need to clear your
session and cookies.

## Branch names
We use gitflow naming conventions for branches:
[hotfix/feature]/trlst-storyid-story-description

For example:
hotfix/trlst-242-optimise-logging-in-api-project 

## Commit process
Always squash and merge and name your commit as per your branch in the following style:

[hotfix/feature]: TRLST [story #] - story description

For example:
hotfix: TRLST 242 - optimise logging in api project

