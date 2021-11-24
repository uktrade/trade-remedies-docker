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

## Getting started
In a working directory run: 

    make clone-repos

This uses an SSH git clone by default. Run the following command if you want
to use https then run:

    make clone-repos clonetype=https

Next, create initial databases:

    make_database

This creates `trade_remedies` and `trade_remedies_api_test` databases. You can
also specify a custom database name but this would require configuration changes
in the trade-remedies-api project folder before running the api. Useful for
if you're going to import database data from the PaaS.

    make_database name=trade_remedies_uat

### Build and initialise services
You need to build and configure all the services for first use, simply run:

    make first-use

This will download/build all the required docker images and initialise the
database.

### Required manual configuration
The make `make clone-repos` command creates `trade-remedies-*/local.
env` files, but in order to operate each service locally it's important to
populate some values. See the inline comments in the files in the individual
repositories and reach out to colleagues for API keys etc.

### Run the services
You're now ready to run the services.

    make up

Wait until all the services are running, for the django services you should
see something like the following in the docker-compose logs:

    Starting development server at http://0.0.0.0:8000/

In a browser, navigate to the following endpoints to check all is running
correctly:

- API (Admin portal): http://localhost:8000/admin

  Login as user: `admin@mylocaltrade.com` password: `change-Me`

- Caseworker portal: http://localhost:8001

  Login as user: `admin@mylocaltrade.com` password: `change-Me`

- Public portal: http://localhost:8002

  Click `Create an account` on the landing page.

## Advanced configuration

### Setting up the API tokens
The `make first-use` operation creates the required tokens so
out-of-the-box there is nothing to do. It invokes `manage.py adminuser`,
which will set up a user and auth-token according to the
`HEALTH_CHECK_USER_EMAIL` and `HEALTH_CHECK_USER_TOKEN` values defined in
the `local.env` file in the trade_remedies_api project and will look
something like:

- name: `Health Check`
- email: `_healthcheckuser_@gov.uk` (Value of `HEALTH_CHECK_USER_EMAIL` env var)
- token: `AUTH-TOKEN-FOR-TRUSTED-USER` (Value of `HEALTH_CHECK_USER_TOKEN` env var)

> Note there is a Django setting used by the API Client (employed by both
public and caseworker portals) called `TRUSTED_USER_TOKEN` but this is
simply set from the `HEALTH_CHECK_TOKEN` environment variable.

However, if you import an existing Trade Remedies database, you'll need to
correctly set API tokens for the Public and Caseworker services, so they can
make authenticated calls to the trade_remedies_api service.  You can do this by
setting the `HEALTH_CHECK_TOKEN` value in the `local.env` file to a value
obtained from the imported database.

You can also find the token value in the Django Admin portal at
`http://localhost:8000/admin`. Log in using the values for `MASTER_ADMIN_EMAIL`
and `MASTER_ADMIN_PASSWORD` environment variables (e.g. `admin@mylocaltrade.
com/change-Me`). Navigate to `http://localhost:8000/admin/authtoken/token/`
and copy the token value for `HEALTH_CHECK_USER_EMAIL` user.

### Set up Notifications
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

# TR Release Process

[trade-remedies-api]: (https://github.com/uktrade/trade-remedies-api/)
[trade-remedies-caseworker]: (https://github.com/uktrade/trade-remedies-caseworker/)
[trade-remedies-public]: (https://github.com/uktrade/trade-remedies-public/)

1. Perform the following steps in a local copy of each TR repository:

  - [Trade Remedies API][trade-remedies-api]
  - [Trade Remedies Caseworker][trade-remedies-caseworker]
  - [Trade Remedies Public][trade-remedies-public]

2. Make sure your local `master` and `develop` branches are up-to-date, e.g.
   invoke `git fetch; git pull`. Next:


    git checkout master

4. Create a branch from `master` named after the next release. For example if
   the last release was 1.5.13 then:


    git branch -b release_1_5_14

5. Merge changes from `develop` into the release branch:


    git merge develop

7. Resolve any conflicts and commit the changes.

8. Bump the version number in `config/version.py` version file and commit.

9. Push the release branch to `origin` e.g:


     git push --set-upstream origin release_1_5_14

10. In `Jenkins`, deploy the branch to UAT and notify on Slack
    `#tr-stakeholder-comms` that the release is available for testing.

11. If there are issues, fix in release branch (we will merge back to
    develop later).
12. When stakeholders signal UAT is acceptable, create a PR in `github` and merge
    release branch into master (you won't need a review).

> Ensure you merge release branch into master (not develop)

14. Fetch the latest `master` from remote and tag the release with an annotated
    tag and push to origin:


    git tag -a 1.5.14 -m "trade-remedies-xxx release 1.5.14"
    git push origin 1.5.14

14. At the opportune moment, in `Jenkins`, deploy the `tag` to UAT for a
    sanity check. Then in `Jenkins`, deploy the `tag` to PROD.
15. Notify on Slack `#tr-stakeholder-comms` that `1.5.14` has been deployed to
    production.

16. We need to prepare a PR to merge release branch back into `develop`
    (this will normally just be the bumped version but could include fixes
    for issues discovered in the release cycle). Create a branch from
    develop (using the story created for the release task):


    git checkout develop
    git checkout -b merge/TRLST-XXX-release-into-develop

17. Resolve any conflicts and commit the changes. Raise a PR, get reviewed
    and merge.
