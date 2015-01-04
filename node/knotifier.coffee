#!/usr/bin/env coffee
http     = require 'http'
redis    = require 'redis'

KNOTIFIER_DEFAULT_PORT = 34569
KNOTIFIER_DEFAULT_HOST = '127.0.0.1'

server = require('http').createServer()
io = require('socket.io')(server)

port = process.env.KNOTIFIER_PORT || KNOTIFIER_DEFAULT_PORT
hostname = process.env.KNOTIFIER_HOST || KNOTIFIER_DEFAULT_HOST

server.listen port, hostname, ->
  console.log "Listening on #{hostname}:#{port}"

io.on 'connection', (socket) ->
  console.log 'a user connected'

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
