bunyan  = require 'bunyan'
log     = bunyan.createLogger name: 'simpleAuth'
env     = require '../env'

username = env.assert 'AUTH_USER'
password = env.assert 'AUTH_PASSWORD'

module.exports = (ctx) ->
  if ctx.method is 'password'
    if ctx.username is username and ctx.password is password
      log.info {user: username}, 'Authentication succeeded'
      return ctx.accept()
    else
      log.warn {user: ctx.username, password: ctx.password}, 'Authentication failed'
  ctx.reject(['password'])
