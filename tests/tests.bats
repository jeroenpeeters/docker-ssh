#!/usr/bin/env bats

SSH="ssh -p 2222 -tt -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=quiet $SERVER_IP"
SSH_NON_INTERACTIVE="ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=quiet $SERVER_IP"

@test "run single remote command" {
  run $SSH_NON_INTERACTIVE whoami
  [ "$status" -eq 0 ]
  [ "$output" = "root" ]
}

@test "run interactive shell" {
  run $SSH <<EOF
whoami;
sleep 2;
whoami;
EOF
  [ "$status" -eq 0 ]
}
