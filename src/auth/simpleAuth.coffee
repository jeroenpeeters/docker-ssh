env = require '../env'

username = env.assert 'AUTH_USER'
password = env.assert 'AUTH_PASSWORD'

module.exports = (ctx) ->
  if ctx.method is 'password' and ctx.username is username and ctx.password is password
    return ctx.accept()
  ctx.reject()
