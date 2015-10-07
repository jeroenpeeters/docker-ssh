express = require 'express'
app     = express()

module.exports =

  start: (port) ->

    app.get '/', (req, res) ->
      res.send 'hello world'

    server = app.listen port, ->
      host = server.address().address
      port = server.address().port

      console.log 'Web listening on http://%s:%s', host, port
