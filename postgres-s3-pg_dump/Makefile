DOCKER_USERNAME ?= liquiddragon
APPLICATION_NAME ?= postgresql-s3-pg_dump
GIT_HASH ?= $(shell git log --format="%h" -n 1)
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

_BUILD_ARGS_TAG ?= ${GIT_HASH}
_BUILD_ARGS_RELEASE_TAG ?= 16
_BUILD_ARGS_DOCKERFILE ?= Dockerfile
_BUILD_ENVIRONMENT ?= production

_builder:
	docker build --tag ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG} --build-arg ENVIRONMENT=${_BUILD_ENVIRONMENT} -f ../docker/${_BUILD_ARGS_DOCKERFILE} ..

_pusher:
	docker push ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG}

_releaser:
	docker pull ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG}
	docker tag  ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_TAG} ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_RELEASE_TAG}
	docker push ${DOCKER_USERNAME}/${APPLICATION_NAME}:${_BUILD_ARGS_RELEASE_TAG}

_debuger:
	docker run -it --rm --entrypoint="/bin/bash" \
		--env-file ${LOCAL_WORKSPACE_FOLDER}/.secrets/.env \
		--mount type=bind,source=${LOCAL_WORKSPACE_FOLDER}/.secrets/.pgpass,target=/backup/.pgpass,readonly \
		--mount type=bind,source=${LOCAL_WORKSPACE_FOLDER}/.secrets/encrypt.key,target=/backup/encrypt.key,readonly \
		--network postgres_default \
		${DOCKER_USERNAME}/${APPLICATION_NAME}:development

build_prod:
	$(MAKE) _builder \
		-e _BUILD_ENVIRONMENT="production"

build:
	$(MAKE) _builder \
		-e _BUILD_ENVIRONMENT="development"\
		-e _BUILD_ARGS_TAG="development"
debug:
	$(MAKE) build
	$(MAKE) _debuger

push:
	$(MAKE) _pusher

release:
	$(MAKE) _releaser

build_prod_%:
	$(MAKE) _builder \
		-e _BUILD_ARGS_TAG="$*-${GIT_HASH}" \
		-e _BUILD_ARGS_DOCKERFILE="Dockerfile.$*" \
		-e _DOCKER_BUILD_ARGS="production"

build_%:
	$(MAKE) _builder \
		-e _BUILD_ARGS_TAG="$*-${GIT_HASH}" \
		-e _BUILD_ARGS_DOCKERFILE="Dockerfile.$*" \
		-e _DOCKER_BUILD_ARGS="development"

push_%:
	$(MAKE) _pusher \
		-e _BUILD_ARGS_TAG="$*-${GIT_HASH}"

release_%:
	$(MAKE) _releaser \
		-e _BUILD_ARGS_TAG="$*-${GIT_HASH}" \
		-e _BUILD_ARGS_RELEASE_TAG="$*-latest"