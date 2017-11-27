#!/bin/bash

docker run --name ubuntu -t -d --label label1=value1 ubuntu bash

CONTAINER=ubuntu CONTAINER_SHELL=bash KEYPATH=id_rsa PORT=2222 HTTP_PORT=8022 \
  AUTH_MECHANISM=simpleAuth \
  AUTH_USER=myuser \
  AUTH_PASSWORD=1234 \
  FILTERS={\"label\":[\"label1=value1\"]} \
  nodemon -e coffee server.coffee | bunyan

docker stop ubuntu && docker rm --force ubuntu
