# trade-remedies-docker
Master repo for building trade remedies system for local development.

This repository provides a dockerised environment that can fetch, build and start all of the Trade Remedies applications and support systems. 

**This approach MUST be used for all local development.** If you have issues getting set up, please speak to a colleague on the Live Services Team.

## Makefile

The provided Makefile provides an interface to manage this environment. The following commands are available:

Run `make help` to see a list of available commands

## First run

Run `make first-use`

## Sites

| Address | Site |
| ------------- | ------------- |
| `http://localhost:8000` | API |
| `http://localhost:8001` | Caseworker site |
| `http://localhost:8002` | Public site |

## Known issues

If, when first accessing the caseworker site, you receive a forbidden message, you need clear your session and cookies.

