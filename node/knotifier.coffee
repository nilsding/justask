#!/usr/bin/env coffee
http     = require 'http'
redis    = require 'redis'

KNOTIFIER_DEFAULT_PORT = 34569

server = require('http').createServer()
io = require('socket.io').listen(server)

server.listen process.env.KNOTIFIER_PORT || KNOTIFIER_DEFAULT_PORT, ->
  console.log "Listening on #{process.env.KNOTIFIER_PORT || KNOTIFIER_DEFAULT_PORT}"

io.sockets.on 'connection', (socket) ->
  console.log 'an user connected'

  # subscribe to Redis
  client = redis.createClient()
  client.subscribe 'notifications.create'
  
  # relay Redis messages to connected socket
  client.on 'message', (channel, message) ->
    console.log 'rails -> user:', channel, message
    socket.emit 'message', message
  
  # unsubscribe from redis if session disconnects
  socket.on 'disconnect', ->
    console.log 'an user disconnected'
    client.quit()