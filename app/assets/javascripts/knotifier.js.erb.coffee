socket = io.connect "//<%= APP_CONFIG['socketio_path'] %>"

socket.on 'message', (data) ->
  console.log(data)