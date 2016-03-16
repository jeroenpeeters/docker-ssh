#!/bin/bash

# first build the test container
docker build -t docker-ssh-tests .

# then execute it to run the tests
printf '\n\n   Tests:\n\n'
docker run -t docker-ssh-tests
