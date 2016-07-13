#!/bin/bash

docker run --name ubuntu -t -d ubuntu bash

CONTAINER=ubuntu CONTAINER_SHELL=bash KEYPATH=id_rsa PORT=2222 HTTP_PORT=8022 AUTH_MECHANISM=noAuth nodemon -e coffee server.coffee | bunyan

docker stop ubuntu && docker rm --force ubuntu
