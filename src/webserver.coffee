express     = require 'express'
bodyParser  = require('body-parser')
uuid        = require 'uuid'
app         = express()

module.exports =

  start: (port, sessionHandler) ->

    app.use express.static 'src/public'
    app.use bodyParser.urlencoded extended: false

    eventHandlers = []
    addEventHandler = (connectionId, event, cb) ->
      eventHandlers[connectionId] = {} unless eventHandlers[connectionId]
      eventHandlers[connectionId][event] = cb

    webSession = (res, connectionId) -> ->
      channel = ->
        write: (data) ->
          res.write "event: data\n"
          res.write "data: #{JSON.stringify data}\n\n"
        on: (event, cb) ->
          addEventHandler connectionId, "channel:#{event}", cb
        end: ->
          console.log 'websession end'
          delete eventHandlers[connectionId]
          res.end()

      once: (cmd, cb) ->
      on: (event, cb) ->
        switch event
          when 'shell' then cb channel
          else addEventHandler connectionId, "session:#{event}", cb

    app.get '/api/v1/terminal/stream/', (req, res) ->
      res.setHeader('Connection', 'Transfer-Encoding');
      res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
      res.setHeader('Transfer-Encoding', 'chunked');
      terminalId = uuid.v4()
      res.write "event: connectionId\n"
      res.write "data: #{terminalId}\n\n"
      sessionHandler.handler webSession res, terminalId

      res.on 'close', ->
        console.log 'res close'
        eventHandlers[terminalId]['channel:close']()

    app.post '/api/v1/terminal/send/:terminalId', (req, res) ->
      terminalId = req.params.terminalId
      data = req.body.data
      if eventHandlers[terminalId]['channel:data']
        eventHandlers[terminalId]['channel:data'] data
      else
        console.error "No input handler for terminal #{terminalId}"
      res.end()

    app.post '/api/v1/terminal/resize-window/:terminalId', (req, res) ->
      terminalId = req.params.terminalId
      info =
        rows: parseInt req.body.rows
        cols: parseInt req.body.cols
      eventHandlers[terminalId]['session:window-change'] null, null, info
      res.json info
      res.end()

    server = app.listen port, ->
      host = server.address().address
      port = server.address().port
      console.log 'Web listening on http://%s:%s', host, port
