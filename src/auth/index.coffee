module.exports = (authType) ->
  switch authType
    when 'noAuth' then require './noAuthHandler'
    when 'simpleAuth' then require './simpleAuth'
    else null
