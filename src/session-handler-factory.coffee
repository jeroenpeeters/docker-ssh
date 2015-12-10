pty     = require 'pty'
bunyan  = require 'bunyan'
log     = bunyan.createLogger name: 'sessionHandler'

spaces = (text, length) ->(' ' for i in [0..length-text.length]).join ''
header = (container) ->
  "\r\n" +
  " ###############################################################\r\n" +
  " ## Docker SSH ~ Because every container should be accessible ##\r\n" +
  " ###############################################################\r\n" +
  " ## container | #{container}#{spaces container, 45}##\r\n" +
  " ###############################################################\r\n" +
  "\r\n"

module.exports = (container, shell) ->
  instance: ->
    session = null
    channel = null
    term = null
    isClosing = false

    closeChannel = ->
      log.info {container: container}, 'Closing channel'
      isClosing = true
      channel.end() if channel
    stopTerm = ->
      log.info {container: container}, 'Stop terminal'
      term.kill 'SIGKILL' if term

    close: -> stopTerm()
    handler: (accept, reject) ->
      session = accept()
      termInfo = null

      session.once 'exec', (accept, reject, info) ->
        log.warn {container: container, command: info.command}, 'Client tried to execute a single command with ssh-exec. This is not (yet) supported by Docker-SSH.'
        console.log 'Client wants to execute: ' + info.command
        stream = accept()
        stream.stderr.write "'#{info.command}' is not (yet) supported by Docker-SSH\n"
        stream.exit 0
        stream.end()

      session.on 'err', (err) ->
        log.error {container: container}, err

      session.on 'shell', (accept, reject) ->
        log.info {container: container}, 'Opening shell'
        channel = accept()
        channel.write "#{header container}"

        term = pty.spawn 'docker', ['exec', '-ti', container, shell], {}
        term.write 'export TERM=linux;\n'
        term.write 'export PS1="\\w $ ";\n\n'
        term.resize termInfo.cols, termInfo.rows if termInfo

        term.on 'exit', ->
          log.info {container: container}, 'Terminal exited'
          closeChannel()

        term.on 'error', (err) ->
          log.error {container: container}, 'Terminal error', err
          closeChannel()

        forwardData = false
        setTimeout (-> forwardData = true; term.write '\n'), 500
        term.on 'data', (data) ->
          if forwardData
            channel.write data

        channel.on 'data', (data) ->
          term.write data

        channel.on 'error', (e) ->
          log.error {container: container}, 'Channel error', e

        channel.on 'exit', ->
          log.info {container: container}, 'Channel exited'
          stopTerm()

      session.on 'pty', (accept, reject, info) ->
        x = accept()
        termInfo = info

      session.on 'window-change', (accept, reject, info) ->
        log.info {container: container}, 'window-change', info
        term.resize info.cols, info.rows if term
