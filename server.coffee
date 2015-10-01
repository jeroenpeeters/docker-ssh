fs    = require 'fs'
ssh2  = require 'ssh2'

authenticationHandler = require './src/authenticationHandler'
sessionHandler        = require './src/sessionHandler'

port      = process.env.PORT or 22
ip        = process.env.IP or '127.0.0.1'
keypath   = process.env.KEYPATH or '~/.ssh/id_rsa'
container = process.env.CONTAINER

unless container
  console.error 'No CONTAINER specified'
  process.exit(1)

options =
  privateKey: fs.readFileSync keypath

sshServer = new ssh2.Server options, (client) ->

  sessHandler = sessionHandler container

  client.on 'authentication', authenticationHandler
  client.on 'ready', -> client.on('session', sessHandler.handler)
  client.on 'end', ->
    console.log 'Client disconnected'
    sessHandler.close()

sshServer.listen port, ip, ->
  console.log "Docker SSH listening on #{@address().address}:#{@address().port}"
