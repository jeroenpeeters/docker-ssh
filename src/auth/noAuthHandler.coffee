
module.exports = (ctx) ->
  console.warn 'NoAuthentication handler is handling the authentication! This is INSECURE!'
  ctx.accept()
