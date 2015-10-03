fs    = require 'fs'
ssh2  = require 'ssh2'

authenticationHandler = require './src/authenticationHandler'
sessionHandler        = require './src/sessionHandler'

port      = process.env.PORT or 22
ip        = process.env.IP or '0.0.0.0'
keypath   = process.env.KEYPATH
container = process.env.CONTAINER
shell     = process.env.CONTAINER_SHELL

unless container
  console.error 'No CONTAINER specified'
  process.exit(1)
unless keypath
  console.error 'No KEYPATH specified'
  process.exit(1)
unless shell
  console.error 'No CONTAINER_SHELL specified'
  process.exit(1)

options =
  privateKey: fs.readFileSync keypath

sshServer = new ssh2.Server options, (client) ->

  sessHandler = sessionHandler container, shell

  client.on 'authentication', authenticationHandler
  client.on 'ready', -> client.on('session', sessHandler.handler)
  client.on 'end', ->
    console.log 'Client disconnected'
    sessHandler.close()

sshServer.listen port, ip, ->
  console.log "Docker SSH listening on #{@address().address}:#{@address().port}"
