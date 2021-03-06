Player = require '../../models/server/player'
Collection = require '../../models/collection'
_ = require 'underscore'

PLAYER_ENTITY_PREFIX = 1 << 28

module.exports = (config) ->
  @players = new Collection [], indexes: ['username']

  getPlayer = (fn) =>
    return (id) =>
      player = @players.get id
      args = Array::slice.call arguments, 1
      args.splice 0, 0, player
      fn.apply @, args if player?

  @on 'peer.connector', (e, connector, connection) =>
    connection.on 'join', (player, state) =>
      player.connector = connector
      player = new Player player

      if @players.get('username', player.username)?
        player.kick "Someone named '#{player.username}' is already connected."
        return

      @players.insert player
      @emit 'join', player, state

      player.on 'leave:after', (e) =>
        @players.remove player

    connection.on 'quit', getPlayer (player) =>
      player.emit 'leave'
      player.emit 'quit' if not player.kicked

    connection.on 'data', getPlayer (player, id, data) =>
      player.emit 'data', id, data
      player.emit id, data

  @on 'join:before', (e, player, options) =>
    if not options.handoff?.transparent
      @info "#{player.username} joined (connector:#{player.connector.id})"
    else
      @debug "#{player.username} joined (handoff) (connector:#{player.connector.id})"

    if not player.entityId?
      player.entityId = PLAYER_ENTITY_PREFIX | Math.floor Math.random() * 0xfffffff

    ready = ->
      player.emit 'ready'
    onReady = ->
      player.off 0xa, onReady
      player.off 0xb, onReady
      player.off 0xc, onReady
      player.off 0xd, onReady
      setTimeout ready, config.readyDelay or 250
    player.on 0xa, onReady
    player.on 0xb, onReady
    player.on 0xc, onReady
    player.on 0xd, onReady

  @on 'join:after', (e, player, options) =>
    worldMeta =
      levelType: 'flat'
      gameMode: 1
      dimension: 0
      difficulty: 0
      maxPlayers: 64
      worldHeight: 256
    _.extend worldMeta, player.region.world.meta if player.region.world.meta?

    # player just joined
    if not options.handoff
      worldMeta.entityId = player.entityId
      player.send 0x1, worldMeta

    # player was handed off
    else
      # transparent handoff
      if options.handoff.transparent
        # TODO: do server handoff stuff

      # hard handoff
      else
        # change dimension, then go back in order to make sure client unloads everything
        fakeWorldMeta = _.clone worldMeta
        fakeWorldMeta.dimension++
        fakeWorldMeta.dimension = 0 if fakeWorldMeta.dimension > 1
        player.send 0x9, fakeWorldMeta
        player.send 0x9, worldMeta

      player.on 'ready:after', =>
        player.message "§aNow connected to server:#{@id}"

  @on 'update:before', (e, data) =>
    data.players = @players.length
