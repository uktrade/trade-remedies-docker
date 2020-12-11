# trade-remedies-docker
Master repo for building trade remedies system for local development.

This repository provides a dockerised environment that can fetch, build and start all of the Trade Remedies applications and support systems. 

**This approach MUST be used for all local development.** If you have issues getting set up, please speak to a colleague on the Live Services Team.

## Makefile

The provided Makefile provides an interface to manage this environment. The following commands are available:

Run `make help` to see a list of available commands

## First run

Run `make clone-repos`

This uses a SSH git clone by default. Run the following command if you want to use https:

Run `make clone-repos clonetype=https`

Populate the project's local.env files with any missing values.

Run `make first-use`

## BDD testing

Behavioural testing is provided by Behave Django - https://github.com/behave/behave-django and can be triggered by:

`make bdd`

This make command creates a test database (that is used by the 'apitest' container), runs migrations and then initialises BDD tests.

When running from within a BDD test, if the public or caseworker sites access the API, they access an endpoint on the 'apitest' container (rather than the 'api' container, as is usually the case).

This means that BDD tests are completely siloed from local development infrastructure and can be run in parallel.

The 'apitest' container is configured to allow access to test object creation endpoints that are excluded from other configurations.

For this reason, the 'api_test' app in the API project should never be added to non test Django configurations.

### Required manual configuration

You *must* update values to your `local.env` files to operate the websites locally. See the inline comments in the individual repositories.

Run `make collect-notify-templates`

## Sites

| Address | Site |
| ------------- | ------------- |
| `http://localhost:8000` | API |
| `http://localhost:8001` | Caseworker site |
| `http://localhost:8002` | Public site |

## Known issues

If, when first accessing the caseworker site, you receive a forbidden message, you need to clear your session and cookies.

