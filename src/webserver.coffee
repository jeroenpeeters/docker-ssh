express     = require 'express'
bodyParser  = require('body-parser')
uuid        = require 'uuid'
app         = express()

bunyan      = require 'bunyan'
webLog      = bunyan.createLogger name: 'webserver'

module.exports =

  start: (port, sessionFactory) ->

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
          webLog.info 'Websession end', connectionId: connectionId
          delete eventHandlers[connectionId]
          res.end()

      once: (cmd, cb) ->
      on: (event, cb) ->
        switch event
          when 'shell' then cb channel
          else addEventHandler connectionId, "session:#{event}", cb

    app.get '/api/v1/terminal/stream/', (req, res) ->
      terminalId = uuid.v4()
      webLog.info 'New terminal session', terminalId: terminalId
      res.setHeader 'Connection', 'Transfer-Encoding'
      res.setHeader 'Content-Type', 'text/event-stream; charset=utf-8'
      res.setHeader 'Transfer-Encoding', 'chunked'
      res.write 'event: connectionId\n'
      res.write "data: #{terminalId}\n\n"
      sessionFactory.instance().handler webSession res, terminalId

      res.on 'close', ->
        eventHandlers[terminalId]['channel:end']()

    app.post '/api/v1/terminal/send/:terminalId', (req, res) ->
      terminalId = req.params.terminalId
      data = req.body.data
      if eventHandlers[terminalId]['channel:data']
        eventHandlers[terminalId]['channel:data'] data
      else
        webLog.error 'No input handler for connection', connectionId: connectionId
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
      webLog.info {host: host, port: port}, 'Listening'
