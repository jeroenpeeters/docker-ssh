pty = require 'pty'

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

  session = null
  channel = null
  term = null
  isClosing = false

  closeChannel = ->
    console.log 'Closing channel'
    isClosing = true
    channel.end() if channel
  stopTerm = ->
    console.log 'Stop Term'
    term.kill 'SIGKILL' if term

  close: -> stopTerm()
  handler: (accept, reject) ->
    session = accept()

    session.once 'exec', (accept, reject, info) ->
      console.log 'Client wants to execute: ' + info.command
      stream = accept()
      stream.stderr.write 'Oh no, the dreaded errors!\n'
      stream.write 'Just kidding about the errors!\n'
      stream.exit 0
      stream.end()

    session.on 'err', (err) ->
      console.log 'session err', err

    session.on 'shell', (accept, reject) ->
      channel = accept()
      channel.write "#{header container}"

      term = pty.spawn 'docker', ['exec', '-ti', container, shell], {

      }
      term.write 'export TERM=linux;\n'
      term.write 'export PS1="\\w $ ";\n\n'

      term.on 'exit', ->
        console.log 'Term exit'
        closeChannel()

      term.on 'error', (err) ->
        console.log 'term error', "#{err}"
        #channel.write "Docker SSH encountered an error: #{err}\r\n" unless isClosing
        closeChannel()

      forwardData = false
      setTimeout (-> forwardData = true; term.write '\n'), 500
      term.on 'data', (data) ->
        if forwardData
          channel.write data

      channel.on 'data', (data) ->
        term.write data

      channel.on 'error', (e) ->
        console.log 'channel error', e

      channel.on 'exit', ->
        console.log 'channel exit'
        stopTerm()

    session.on 'pty', (accept, reject, info) ->
      x = accept()

    session.on 'window-change', (accept, reject, info) ->
      console.log 'window-change', info
      if term
        term.resize info.cols, info.rows
