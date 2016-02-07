# Makefile to ease the docker image build and publish process.
# Achim Sperling <achim.sperling@gmail.com>
#
# Usage:
# * `make all` builds and squashs the image,
# * `make push` publishs the image
# * `make clean-all` cleans up all local temporary files and images
# DO NOT FORGET TO SET THE FOLLOWING PARAMS, ESPECIALLY `DOCKER_REGISTRY`.

# Set either to your username on docker.io or to your private registry
DOCKER_REGISTRY			= jeroenpeeters
IMAGE_TEMP_NAME			= build-docker-ssh
IMAGE_FINAL_NAME		= docker-ssh

# You shouldn't need to change anything of the following.
DATE_TAG				= $(shell date +"%m_%d_%Y")
DOCKER_SQUASH_URL		= https://github.com/jwilder/docker-squash/releases/download/v0.2.0/docker-squash-linux-amd64-v0.2.0.tar.gz
DOCKER_SQUASH_PATH		= $(CURDIR)/bin
DOCKER_SQUASH_BIN		:= $(shell command -v docker-squash || echo $(DOCKER_SQUASH_PATH)/docker-squash)


.PHONY: all prepare build squash clean clean-all

all: prepare build squash

prepare:
	@if ! [ -f $(DOCKER_SQUASH_BIN) ] ; then \
		echo "Missing 'docker-squash' - Downloading it now... " ; \
		mkdir $(DOCKER_SQUASH_PATH) 2> /dev/null ; \
		if ! wget -qO- $(DOCKER_SQUASH_URL) | tar xz -C $(DOCKER_SQUASH_PATH) 2> /dev/null ; then \
			echo "ERROR: Could not download '$(DOCKER_SQUASH_URL)'!" ; \
		fi; \
	fi ;

build: prepare
	docker build --no-cache --force-rm -t ${IMAGE_TEMP_NAME}:${DATE_TAG} -f Dockerfile .

squash: build
	docker save ${IMAGE_TEMP_NAME}:${DATE_TAG} | sudo $(DOCKER_SQUASH_BIN) -t ${IMAGE_TEMP_NAME}:squashed | docker load
	docker rmi ${IMAGE_TEMP_NAME}:${DATE_TAG}

push:
	@docker tag -f ${IMAGE_TEMP_NAME}:squashed ${DOCKER_REGISTRY}/${IMAGE_FINAL_NAME}
	docker login
	@docker push ${DOCKER_REGISTRY}/${IMAGE_FINAL_NAME}

clean:
	@-rm -rf $(CURDIR)/bin
	@-docker rmi ${IMAGE_TEMP_NAME}:squashed 2> /dev/null
	@-docker rmi ${IMAGE_TEMP_NAME}:${DATE_TAG} 2> /dev/null

clean-all: clean
	@-docker rmi ${DOCKER_REGISTRY}/${IMAGE_FINAL_NAME}
