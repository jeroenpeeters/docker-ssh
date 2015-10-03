module.exports = (authType) ->
  switch authType
    when 'noAuth' then require './noAuthHandler'
    else null
