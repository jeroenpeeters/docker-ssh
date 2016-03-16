bunyan  = require 'bunyan'
Docker  = require 'dockerode'
scp     = require 'scp-ssh2'
tar     = require 'tar-stream'
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

module.exports = (container, shell) ->
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
        if scp.isScp info
          handler = scp (transfer) ->
            transfer.on 'done', ->
              console.log 'scp exited'
            transfer.on 'write_file', (path, dir, name, data) ->
              _container = docker.getContainer container
              _container.exec {Cmd: ['/bin/echo', '\'', data.toString(), '\''], AttachStdin: true, AttachStdout: true, AttachStderr: true, Tty: false}, (err, exec) ->
                console.log 'err', err
                exec.start {stdin: true, Tty: false}, (err, _stream) ->
                  console.log 'err2', err
                  stream = _stream

                  stream.on 'data', (data) ->
                    console.log '!!!xx', data
                    #channel.write data.toString()
                  stream.on 'error', (err) ->
                    log.error {container: container}, 'Exec error', err
                    closeChannel()
                  stream.on 'end', ->
                    log.info {container: container}, 'Exec ended'
                    closeChannel()

              console.log 'impl::file', path, dir, name, data
            transfer.on 'read_file', (path, cb) ->
              cb "You requested: #{path}"
            transfer.on 'mkdir', (path, dir, name, mode) ->
              console.log 'impl::mkdir', path, dir, name, mode

          handler accept, reject, info
        else
          channel = accept()
          _container = docker.getContainer container
          _container.exec {Cmd: [shell, '-c', info.command], AttachStdin: true, AttachStdout: true, AttachStderr: true, Tty: false}, (err, exec) ->
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
        _container.exec {Cmd: [shell], AttachStdin: true, AttachStdout: true, Tty: true}, (err, exec) ->
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
