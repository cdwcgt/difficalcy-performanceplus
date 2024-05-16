COMPOSE_TOOLING_RUN = docker compose -f compose.tooling.yaml run --rm --build tooling
COMPOSE_E2E = docker compose -f compose.yaml -f compose.override.e2e.yaml
COMPOSE_E2E_RUN = $(COMPOSE_E2E) run --rm --build e2e-test-runner
COMPOSE_APP_DEV = docker compose -f compose.yaml -f compose.override.yaml
COMPOSE_RUN_DOCS = docker compose -f compose.yaml -f compose.override.yaml run docs
COMPOSE_PUBLISH = docker compose -f compose.yaml -f compose.override.publish.yaml

export OSU_COMMIT_HASH = $(shell git rev-parse HEAD:osu)

help:	## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

bash:	## Opens bash shell in tooling container
	$(COMPOSE_TOOLING_RUN) bash

test:	## Runs test suite
	$(COMPOSE_TOOLING_RUN) dotnet test

test-e2e:	## Runs E2E test suite
	$(COMPOSE_E2E_RUN)
	$(COMPOSE_E2E) down

build-dev:	## Builds development docker images
	$(COMPOSE_APP_DEV) build

start-dev: build-dev	## Starts development environment
	$(COMPOSE_APP_DEV) up -d

clean-dev:	## Cleans development environment
	$(COMPOSE_APP_DEV) down --remove-orphans

update-openapi-schemas:	## Updates OpenAPI schemas in docs site
	curl localhost:5004/swagger/v1/swagger.json -o docs/docs/difficalcy-performanceplus.json

build-docs:	## Builds documentation site
	$(COMPOSE_RUN_DOCS) build --strict --clean

# TODO: move gh into tooling container (requires env var considerations)
VERSION =
release:	## Pushes docker images to ghcr.io and create a github release
ifndef VERSION
	$(error VERSION is undefined)
endif
ifndef GITHUB_PAT
	$(error GITHUB_PAT env var is not set)
endif
ifndef GITHUB_USERNAME
	$(error GITHUB_USERNAME env var is not set)
endif
	echo $$GITHUB_PAT | docker login ghcr.io --username $$GITHUB_USERNAME --password-stdin
	VERSION=$(VERSION) $(COMPOSE_PUBLISH) build
	VERSION=$(VERSION) $(COMPOSE_PUBLISH) push difficalcy-performanceplus
	VERSION=latest $(COMPOSE_PUBLISH) build
	VERSION=latest $(COMPOSE_PUBLISH) push difficalcy-performanceplus
	gh release create "$(VERSION)" --generate-notes
