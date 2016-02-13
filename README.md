# Docker-SSH
SSH Server for Docker containers  ~ Because every container should be accessible.

Want to SSH into your container right away? Here you go:

    $ docker run -d -p 2222:22 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -e CONTAINER=my-container -e AUTH_MECHANISM=noAuth \
      jeroenpeeters/docker-ssh

    $ ssh -p 2222 localhost

# Index

- [Todo](#todo)
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

# Todo
Below is a list of items which are currently on the roadmap. If you wish to contribute
to this project, send me a message.
- Authenticate users by username and password
- Authenticate users by username and public key
- Secure copy implementation (SCP)
- Secure FTP implementation (SFTP)
- Customize the MOTD

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

# User Authentication
Docker-SSH has support for multiple authentication mechanisms. The following
table lists the implemented and planned authentication mechanisms

AUTH_MECHANISM    | Implemented | Description
------------------|-------------|--------------
noAuth            | yes         | No authentication is performed, enter any user/password combination to logon
simplePassword    | **no**      | Authenticate a predefined user/password, supports one user
extendedPassword  | **no**      | Authenticate a user according to a predefined lists of users and passwords
privateKey        | **no**      | Private key authentication

## noAuth
No authentication is performed. Any user/password combination is accepted by the server.
Useful for testing, or in closed network environments such as corporate networks with separated VLAN's.
This mechanism is nevertheless **discouraged** and should be used with care! The use of this
authentication mechanism will create an error entry in the log.

## simplePassword
No yet implemented.

## extendedPassword
No yet implemented.

## privateKey
No yet implemented.

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

# Credits
I couldn't have created Docker-SSH without the following great Node packages! Many thanks go to the authors of:

- [SSH2](https://github.com/mscdex/ssh2)
