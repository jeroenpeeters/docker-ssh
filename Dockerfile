FROM node:0.12

RUN apt-get update -qq \
    && apt-get upgrade -y \
    && apt-get install -y libapparmor-dev \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /app
WORKDIR /app

COPY id_rsa* *.json *.coffee ./
COPY src /app/src

RUN npm install

ENV CONTAINER= CONTAINER_SHELL=bash KEYPATH=./id_rsa PORT=22 HTTP_ENABLED=true HTTP_PORT=8022

EXPOSE 22 8022

CMD ["npm", "start"]
