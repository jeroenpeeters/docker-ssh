
module.exports = (ctx) ->
  if ctx.method == 'password'
    #if ctx.username == 'test' and ctx.password == '1234'
    ctx.accept()
    return
  ctx.reject()
