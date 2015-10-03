fs    = require 'fs'
ssh2  = require 'ssh2'

sessionHandler        = require './src/sessionHandler'

port            = process.env.PORT or 22
ip              = process.env.IP or '0.0.0.0'
keypath         = process.env.KEYPATH
container       = process.env.CONTAINER
shell           = process.env.CONTAINER_SHELL
authMechanism   = process.env.AUTH_MECHANISM
authenticationHandler = require('./src/auth') authMechanism

exitOnConfigError = (errorMessage) ->
  console.error "Configuration error: #{errorMessage}"
  process.exit(1)

exitOnConfigError 'No CONTAINER specified'                    unless container
exitOnConfigError 'No KEYPATH specified'                      unless keypath
exitOnConfigError 'No CONTAINER_SHELL specified'              unless shell
exitOnConfigError 'No AUTH_MECHANISM specified'               unless authMechanism
exitOnConfigError "Unknown AUTH_MECHANISM: #{authMechanism}"  unless authenticationHandler

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
