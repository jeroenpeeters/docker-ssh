bunyan  = require 'bunyan'
log     = bunyan.createLogger name: 'multiUserAuth'
env     = require '../env'

tuples = env.assert 'AUTH_TUPLES'

security = {}

for tuple in tuples.split ';'
  [user, password] = tuple.split ':'
  security[user] = password

module.exports = (ctx) ->
  if ctx.method is 'password'
    if security[ctx.username] is ctx.password
      log.info {user: ctx.username}, 'Authentication succeeded'
      return ctx.accept()
    else
      log.warn {user: ctx.username, password: ctx.password}, 'Authentication failed'
  ctx.reject(['password'])
