spawn = require('child_process').spawn

spaces = (text, length) ->(' ' for i in [0..length-text.length]).join ''
header = (container) ->
  "\r\n" +
  " ###############################################################\r\n" +
  " ## Docker SSH ~ Because every container should be accessible ##\r\n" +
  " ###############################################################\r\n" +
  " ## container | #{container}#{spaces container, 45}##\r\n" +
  " ###############################################################\r\n" +
  "\r\n"

module.exports = (container) ->

  session = null
  channel = null
  child = null

  closeChannel = ->
    console.log 'Closing channel'
    channel.end() if channel
  stopChild = ->
    console.log 'Stop Child'
    child.kill 'SIGKILL' if child

  close: -> stopChild()
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

      child = spawn 'script', ['/dev/null', '-qfc', "docker exec -ti #{container} bash"], stdio: 'pipe'
      child.stdin.write 'export TERM=linux;\n'
      child.stdin.write 'export PS1="\\w $ ";\n\n'

      child.on 'exit', ->
        console.log 'Child exit'
        closeChannel()

      child.on 'error', (err) ->
        console.log 'script error', "#{err}"
        channel.write "Docker SSH encountered an error: #{err}"
        closeChannel()

      child.stderr.on 'data', (err) ->
        channel.write err

      #appender = ""
      forwardData = false
      setTimeout (-> forwardData = true; child.stdin.write '\n'), 500
      child.stdout.on 'data', (data) ->
        if forwardData
          channel.write data
        #else
        #  appender = "#{appender}#{data.toString()}"
          #if appender.match /# export PS1="\\w \$ ";/ and !forwardData
          #  forwardData = true
          #  child.stdin.write '\n'

      channel.on 'data', (data) ->
        child.stdin.write data

      channel.on 'error', (e) ->
        console.log 'channel error', e

      channel.on 'exit', ->
        console.log 'channel exit'
        stopChild()

    session.on 'pty', (accept, reject, info) ->
      x = accept()
