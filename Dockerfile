FROM node:0.12-onbuild

# Docker needs libapparmor
RUN apt-get update
RUN apt-get -yf install libapparmor-dev

# make coffee executable
RUN chmod +x ./node_modules/coffee-script/bin/coffee

# Connect to container with name/id
ENV CONTAINER=

# Shell to use inside the container
ENV CONTAINER_SHELL=bash

# Server key
ENV KEYPATH=./id_rsa

# Server port
ENV PORT=22

EXPOSE 22
