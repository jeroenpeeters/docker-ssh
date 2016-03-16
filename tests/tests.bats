#!/usr/bin/env bats
SSH="ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=quiet $SERVER_IP"

@test "run single remote command" {
  run $SSH whoami
  [ "$status" -eq 0 ]
  [ "$output" = "root" ]
}
