# Docker-SSH [![Docker Stars](https://img.shields.io/docker/stars/jeroenpeeters/docker-ssh.svg?style=flat-square)](https://hub.docker.com/r/jeroenpeeters/docker-ssh/) [![Docker Stars](https://img.shields.io/docker/pulls/jeroenpeeters/docker-ssh.svg?style=flat-square)](https://hub.docker.com/r/jeroenpeeters/docker-ssh/)
SSH Server for Docker containers  ~ Because every container should be accessible.

Want to SSH into your container right away? Here you go:

    $ docker run -d -p 2222:22 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -e CONTAINER=my-container -e AUTH_MECHANISM=noAuth \
      jeroenpeeters/docker-ssh

    $ ssh -p 2222 localhost

## What is it?
Docker-SSH is an SSH server implementation that transparently bridges `docker exec`
with the SSH session. It implements a regular SSH server, a web terminal and a web API.

# Index

- [Features & Todo](#features--todo)
- [Add SSH capabilities to any container!](#add-ssh-capabilities-to-any-container)
- [Web Terminal](#web-terminal)
- [User Authentication](#user-authentication)
- [Server Identity and Security](#server-identity-and-security)
- [Arguments](#arguments)
- [Container Requirements](#container-requirements)
- [Troubleshooting](#troubleshooting)

# Preamble
Many reasons exist to SSH to a process running inside a container. As containers **SHOULD** be limited to run
one main/init process there is often no clean way to get access. One could of course SSH to a Docker host and
access the container with *docker exec*. Another way is to start an SSH server as a secondary process. Not only does
this defeat the idea of one process per container, it is also a cumbersome approach when using images from the Docker Hub since they often don't (and shouldn't) contain an SSH server.

Docker-SSH adds SSH capabilities to any container in a compositional way. It implements an SSH server that transparently
bridges the SSH session with docker exec. The requirements for this to function properly are:

- The container has a shell environment installed (e.g. `bash` or `sh`).
- The Docker socket is mapped into the container, this lets the container access the Docker Engine.

# Features & Todo
Below is a list of both implemented features and planned features. Send me a
message if you whish to contribute to this project.
- [x] Interactive shell
- [x] Execute single command
- [x] HTTP API
- [x] Web terminal
- [ ] Customize the MOTD
- [x] Simple user authentication; one user/password
- [x] Authenticate users by username and password
- [x] Authenticate users by username and public key
- [x] Run commands as specific user
- [ ] Secure copy implementation (SCP)
- [ ] Secure FTP implementation (SFTP)
- [ ] Access multiple containers

# Add SSH capabilities to any container!
Let's assume you have a running container with name 'web-server1'. Run the following command to start Docker-SSH:

    docker run -e CONTAINER=web-server1 -e AUTH_MECHANISM=noAuth \
      --name sshd-web-server1 -p 2222:22  --rm \
      -v /var/run/docker.sock:/var/run/docker.sock \
      jeroenpeeters/docker-ssh

The SSH server in this example is now running in its own container named 'sshd-web-server1' and exposes the SSH
service on port 2222.

Now you can access the container through SSH by using your favorite client. The output will look similar to

    ssh someuser@localhost -p 2222
    someuser@localhost's password: <PASSWORD>

    ###############################################################
    ## Docker SSH ~ Because every container should be accessible ##
    ###############################################################
    ## container | web-server1                                   ##
    ###############################################################

    /opt/nginx $

# Web terminal

Docker-SSH also implements a web terminal for convenience. The web terminal allows you to connect to your shell using a browser. Below is a screenshot of the web terminal in action.

![Docker-SSH Web Terminal](https://raw.githubusercontent.com/jeroenpeeters/docker-ssh/master/docker-web-terminal.png)

The web terminal is enabled by default, and exposed on port 8022. To disable the web terminal set `-e HTTP_ENABLED=false`.

# Web API
The web terminal uses the web API to communicate with the shell session. The API can be used by third party application as well.

## Starting a session
A new session can be obtained by calling the `/api/v1/terminal/stream` enpoint. This
call creates a new session and returns a stream of HTML5 Server-Sent Events.
There are two events: 1. connectionId, 2. data. The connectionId event contains a unique id for this session. This id must be used to send commands to the session. The data event contains serialized-string-escaped terminal data. When you close the stream, the session ends.

    curl http://localhost:8022/api/v1/terminal/stream

## Sending commands to a session
To send commands to a session you use the connectionId obtained when starting the
session. Use the endpoint `/api/v1/terminal/send/:sessionId` to send commands to the
terminal session. It must be a post request that does a form submit with a `data` parameter populated with the command you whish to execute. Don't forget to send an enter character, otherwise it would not execute. Remember, this is a terminal!

    curl -X POST http://localhost:8022/api/v1/terminal/send/122dbd35-d51d-4bc3-80c8-787d82370bee -d $'data=ls -al\n'

## Resizing a terminalId
The terminal can be resized by posting to endpoint `/api/v1/terminal/resize-window/:terminalId`. The endpoint accepts two parameters, rows and cols.

    curl -X POST http://localhost:8022/api/v1/terminal/resize-window/2aaff6d2-b0e9-4e42-99c3-a80474b1c32f -d 'rows=10&cols=20'

# User Authentication
Docker-SSH has support for multiple authentication mechanisms. The following
table lists the implemented and planned authentication mechanisms

AUTH_MECHANISM    | Implemented | Description
------------------|-------------|--------------
noAuth            | yes         | No authentication is performed, enter any user/password combination to logon
simpleAuth        | yes         | Authenticate a predefined user/password, supports one user
multiUser         | yes         | Authenticate a user according to a predefined lists of users and passwords
publicKey         | yes         | Public key authentication

## noAuth
No authentication is performed. Any user/password combination is accepted by the server.
Useful for testing, or in closed network environments such as corporate networks with separated VLAN's.
This mechanism is nevertheless **discouraged** and should be used with care! The use of this
authentication mechanism will create an error entry in the log.

## simpleAuth
Supports the authentication of a single user with password. Set `AUTH_MECHANISM=simpleAuth`
to enable this authentication mechanism. The username and password is configured
by setting `AUTH_USER` and `AUTH_PASSWORD`.

    $ docker run -d -p 2222:22 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -e CONTAINER=my-container -e AUTH_MECHANISM=simpleAuth \
      -e AUTH_USER=jeroen -e AUTH_PASSWORD=1234 \
      jeroenpeeters/docker-ssh

    $ ssh -p 2222 jeroen@localhost
    $ jeroen@localhost's password: ****

## multiUser
Supports the authentication of a user against a list of user:password tuples.
Set `AUTH_MECHANISM=multiUser` to enable this authentication mechanism.
The username:password tuples are configured by setting `AUTH_TUPLES`.
It is a single string with semicolon (;) separated user:password pairs.

    $ docker run -d -p 2222:22 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -e CONTAINER=my-container -e AUTH_MECHANISM=multiUser \
      -e AUTH_TUPLES="jeroen:thefather;luke:theforce" \
      jeroenpeeters/docker-ssh

    $ ssh -p 2222 luke@localhost
    $ luke@localhost's password: ****

## publicKey
Supports the authentication of a user against an authorized_keys file containing a list of public keys.
Set `AUTH_MECHANISM=publicKey` to enable this authentication mechanism.
The name of the authorized_keys file is configured by setting `AUTHORIZED_KEYS`.

    $ cat ~/.ssh/id_rsa.pub > authorized_keys
    $ docker run -d -p 2222:22 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v ./authorized_keys:/authorized_keys
      -e CONTAINER=my-container -e AUTH_MECHANISM=publicKey \
      -e AUTHORIZED_KEYS=/authorized_keys \
      jeroenpeeters/docker-ssh

    $ ssh -p 2222 luke@localhost

# Server Identity and Security
The SSH server needs an RSA/EC private key in order to secure the connection and identify itself to clients.
The Docker-SSH container comes with a default RSA key that will be used. If you want, you can provide your own
key. Simply provide a key file as a volume to the container and set the *KEYPATH* argument of the container.
Example: `-v /path/to/my/key:/my_key -e KEYPATH=/my_key`. It is also possible to overwrite the existing key file.
In that case you can omit the `KEYPATH` argument. Example: `-v /path/to/my/key:/usr/src/app/id_rsa.pub`

# Arguments
Arguments to Docker-SSH are passed as Docker environment variables. Docker-SSH needs at least the *CONTAINER*
argument in order to know for which container to provide SSH. Mounting the Docker socket into the SSH container is mandatory since Docker-SSH internally uses *docker exec* to create a shell session.

Argument       | Default  | Description
---------------|----------|------------------------------------------------------
CONTAINER      | None     | *name* or *id* of a running container
CONTAINER_SHELL| bash     | path to a shell.
AUTH_MECHANISM | None     | name of the authentication mechanism, see [User Authentication](#user-authentication)
KEYPATH        | ./id_rsa | path to a private key to use as server identity
PORT           | 22       | ssh server listens on this port
HTTP_ENABLED   | true     | enable/disable the web terminal
HTTP_PORT      | 8022     | web terminal listens on this port
SHELL_USER     | root     | Run commands as this user *(Note: independant from authentication user)*

# Credits
I couldn't have created Docker-SSH without the following great Node packages! Many thanks go to the authors of:

- [SSH2](https://github.com/mscdex/ssh2)
