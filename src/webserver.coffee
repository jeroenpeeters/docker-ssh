express     = require 'express'
bodyParser  = require('body-parser')
uuid        = require 'uuid'
app         = express()

module.exports =

  start: (port, sessionHandler) ->

    app.use express.static 'src/public'
    #app.use bodyParser.json()
    app.use bodyParser.urlencoded extended: false

    inputHandlers = []

    webSession = (res, connectionId) -> ->
      channel = ->
        eventHandlers = []
        write: (data) ->
          res.write "event: data\n"
          res.write "data: #{JSON.stringify data}\n\n"
        on: (event, cb) ->
          switch event
            when 'data' then inputHandlers[connectionId] = cb
            else console.log 'WebChannel does not support event', event

      once: (cmd, cb) ->
      on: (event, cb) ->
        switch event
          when 'shell' then cb channel
          else console.log 'WebSession does not support event', event


    app.get '/api/v1/terminal/stream/', (req, res) ->
      res.setHeader('Connection', 'Transfer-Encoding');
      res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
      res.setHeader('Transfer-Encoding', 'chunked');
      connectionId = uuid.v4()
      res.write "event: connectionId\n"
      res.write "data: #{connectionId}\n\n"
      sessionHandler.handler webSession res, connectionId

    app.post '/api/v1/terminal/send/:terminalId', (req, res) ->
      terminalId = req.params.terminalId
      data = req.body.data
      if inputHandlers[terminalId]
        inputHandlers[terminalId] data
      else
        console.log "No input handler for terminal #{terminalId}"
      res.end()

    server = app.listen port, ->
      host = server.address().address
      port = server.address().port

      console.log 'Web listening on http://%s:%s', host, port
