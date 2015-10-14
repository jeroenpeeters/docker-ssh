bunyan  = require 'bunyan'
log     = bunyan.createLogger name: 'noAuthHandler'

module.exports = (ctx) ->
  log.error 'NoAuthentication handler is handling the authentication! This is INSECURE!'
  ctx.accept()
