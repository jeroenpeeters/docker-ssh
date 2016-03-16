FROM dduportal/bats:0.4.0

RUN apt-get install -y ssh

ENV SERVER_IP=172.17.0.1

ADD /*.bats /app/bats-tests
CMD ["/app/bats-tests/"]
