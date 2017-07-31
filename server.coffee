fs        = require 'fs'
ssh2      = require 'ssh2'
bunyan    = require 'bunyan'
log       = bunyan.createLogger name: 'sshServer'

webserver       = require './src/webserver'
handlerFactory  = require './src/session-handler-factory'

sshPort         = process.env.PORT or 22
httpPort        = process.env.HTTP_PORT or 80
httpEnabled     = process.env.HTTP_ENABLED or true
ip              = process.env.IP or '0.0.0.0'
keypath         = process.env.KEYPATH
container       = process.env.CONTAINER
shell           = process.env.CONTAINER_SHELL
shell_user      = process.env.SHELL_USER || 'root'
authMechanism   = process.env.AUTH_MECHANISM
authenticationHandler = require('./src/auth') authMechanism

httpEnabled = httpEnabled == 'true' || httpEnabled == true

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

sessionFactory = handlerFactory container, shell, shell_user

sshServer = new ssh2.Server options, (client, info) ->
  session = sessionFactory.instance()
  log.info clientIp: info.ip, 'Client connected'
  client.on 'authentication', authenticationHandler
  client.on 'ready', -> client.on('session', session.handler)
  client.on 'end', ->
    log.info clientIp: info.ip, 'Client disconnected'
    session.close()

sshServer.listen sshPort, ip, ->
  log.info 'Docker-SSH ~ Because every container should be accessible'
  log.info {host: @address().address, port: @address().port}, 'Listening'

webserver.start httpPort, sessionFactory if httpEnabled
