# trade-remedies-docker
Master repo for building trade remedies system for local development.

## Update macOS - September 2020

Docker on macOS does not currently support host networking. A quick workaround is to run the services in containers and run the sites natively. To do this run 

`docker-compose -f docker-compose-macos.yml up`

If you want to run all the sites from containers you will need to modify their `local.env` files and remove references to localhost for any postgres, redis or elasticsearch service ... or you could install Linux ;)

---

This repository provides a dockerised environment that can fetch, build and start a complete end to end setup of all of Trade Remedies applications and support systems. This can be used for local development. It is possible to run the entire stack via docker or if needed drop one or more services to run locally outside of docker.


### Makefile

The provided Makefile provides an interface to manage this environment. The following commands are available:

| Command | Description |
| ------- | ----------- |
| `make help` | Prints a description of all available commands |
| `make install` | Fetch or update all repositories |
| `make build` | Build all the docker containers used |
| `make start` | Start up all the containers in background |
| `make stop` | Stop all containers |
| `make restart` | Restart all containers |
| `make logs` | Begin tailing the logs for all containers |

### Simple mode

If the trade-remedies-docker exists in the same directory as the other trade remedies repositories, their volumes will be mounted and used in the containers.
