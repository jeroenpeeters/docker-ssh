bunyan  = require 'bunyan'
Docker  = require 'dockerode'
log     = bunyan.createLogger name: 'sessionHandler'

docker  = new Docker socketPath: '/var/run/docker.sock'

spaces = (text, length) ->(' ' for i in [0..length-text.length]).join ''
header = (container) ->
  "\r\n" +
  " ###############################################################\r\n" +
  " ## Docker SSH ~ Because every container should be accessible ##\r\n" +
  " ###############################################################\r\n" +
  " ## container | #{container}#{spaces container, 45}##\r\n" +
  " ###############################################################\r\n" +
  "\r\n"

module.exports = (container, shell, shell_user) ->
  instance: ->
    session = null
    channel = null
    stream = null
    resizeTerm = null
    session = null

    closeChannel = ->
      channel.exit(0) if channel
      channel.end() if channel
    stopTerm = ->
      stream.end() if stream

    close: -> stopTerm()
    handler: (accept, reject) ->
      session = accept()
      termInfo = null

      session.once 'exec', (accept, reject, info) ->
        log.info {container: container, command: info.command}, 'Exec'
        channel = accept()
        _container = docker.getContainer container
        _container.exec {User: shell_user, Cmd: [shell, '-c', info.command], AttachStdin: true, AttachStdout: true, AttachStderr: true, Tty: false}, (err, exec) ->
          if err
            log.error {container: container}, 'Exec error', err
            return closeChannel()
          exec.start {stdin: true, Tty: true}, (err, _stream) ->
            stream = _stream
            stream.on 'data', (data) ->
              channel.write data.toString()
            stream.on 'error', (err) ->
              log.error {container: container}, 'Exec error', err
              closeChannel()
            stream.on 'end', ->
              log.info {container: container}, 'Exec ended'
              closeChannel()
            channel.on 'data', (data) ->
              stream.write data
            channel.on 'error', (e) ->
              log.error {container: container}, 'Channel error', e
            channel.on 'end', ->
              log.info {container: container}, 'Channel exited'
              stopTerm()

      session.on 'err', (err) ->
        log.error {container: container}, err

      session.on 'shell', (accept, reject) ->
        log.info {container: container}, 'Opening shell'
        channel = accept()
        channel.write "#{header container}"

        _container = docker.getContainer container
        _container.exec {User: shell_user, Cmd: [shell], AttachStdin: true, AttachStdout: true, Tty: true}, (err, exec) ->
          if err
            log.error {container: container}, 'Exec error', err
            return closeChannel()
          exec.start {stdin: true, Tty: true}, (err, _stream) ->
            stream = _stream
            forwardData = false
            setTimeout (-> forwardData = true; stream.write '\n'), 500
            stream.on 'data', (data) ->
              if forwardData
                channel.write data.toString()
            stream.on 'error', (err) ->
              log.error {container: container}, 'Terminal error', err
              closeChannel()
            stream.on 'end', ->
              log.info {container: container}, 'Terminal exited'
              closeChannel()

            stream.write 'export TERM=linux;\n'
            stream.write 'export PS1="\\w $ ";\n\n'

            channel.on 'data', (data) ->
              stream.write data
            channel.on 'error', (e) ->
              log.error {container: container}, 'Channel error', e
            channel.on 'end', ->
              log.info {container: container}, 'Channel exited'
              stopTerm()

            resizeTerm = (termInfo) ->
              if termInfo then exec.resize {h: termInfo.rows, w: termInfo.cols}, -> undefined
            resizeTerm termInfo # initially set the current size of the terminal

      session.on 'pty', (accept, reject, info) ->
        x = accept()
        termInfo = info

      session.on 'window-change', (accept, reject, info) ->
        log.info {container: container}, 'window-change', info
        resizeTerm info
