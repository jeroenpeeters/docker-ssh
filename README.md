# Docker-SSH
SSH Server for Docker containers  ~ Because every container should be accessible

- [Preamble](#preamble)
- [Add SSH capabilities to any container!](#add-ssh--capabilities-to-any-container)
- [User Authentication](#user-authentication)
- [Server Identity and Security](#server-identity-and-security)
- [Arguments](#arguments)
- [Container Requirements](#container-requirements)

# Preamble
Many reasons exist to SSH to a process running inside a container. As containers **SHOULD** be limited to run 
one main/init process there is often no clean way to get access. One could of course SSH to a Docker host and 
access the container with *docker exec*. Another way is to start an SSH server as a second process. Not only does
this defeat the idea of one process per container, it is also a cumbersome approach when using images from the Docker Hub since they often don't (and shouldn't) contain an SSH server. 

Docker-SSH adds SSH capabilities to any container in a compositional way. It implements an SSH server that transparently
bridges the SSH session with docker exec. Currently the only requirement is that the container contains *bash*.

# Add SSH capabilities to any container!
Let's assume you have a running container with name 'web-server1'. Run the following command to start Docker-SSH:

    docker run -ti --name sshd-web-server1 -e CONTAINER=web-server1 -p 2222:22 \
    -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker \
    jeroenpeeters/docker-ssh
    
The SSH server in this example is now running in its own container named 'sshd-web-server1' and exposes the SSH 
service on port 2222.

# User Authentication
Currently, no authentication is implemented. Authenticate to the SSH server with any user and password.

# Server Identity and Security
The SSH server needs an RSA/EC private key in order to secure the connection and identify itself to clients.
The Docker-SSH container comes with a default RSA key that will be used. If you want, you can provide your own
key. Simply provide a key file as a volume to the container and set the *KEYPATH* argument of the container.
Example: -v /path/to/my/key:/my_key -e KEYPATH=/my_key

# Arguments
Arguments to Docker-SSH are passed as Docker environment variables. Docker-SSH needs at least the *CONTAINER* 
argument in order to know for which container to provide SSH. Mounting the Docker socket and Docker command into
the SSH container is also mandatory since Docker-SSH internally uses *docker exec* to create a *bash* session.

Argument  | Default  | Description
----------|----------|------------------------------------------------------
CONTAINER | None     | *name* or *id* of a running container
KEYPATH   | ./id_rsa | path to a private key to use as server identity
PORT      | 22       | server listens on this port

# Container Requirements
In order for Docker-SSH to function, the container for which to provide SSH needs to have *bash* installed and available on the path.
