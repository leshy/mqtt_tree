require! {
  mqtt, os, path
  bluebird: p
  lodash: { each, reduce, head, tail, mapValues }
  'backbone4000': Backbone
  abstractman: { GraphNode }
}


export Node = GraphNode.extend4000 do
  plugs:
    children: { singular: 'child' }
    
  idAttribute: "name"
  
  inspect: -> "Node(#{@name})"

  initialize: (...args) ->

    each args, (arg) ~>
        @ <<< switch arg?@@
          | String => { name: arg }
          | Object => arg
          | _ => { parent: arg }

    @children.on 'all', (event, child, data, pth) ~>
      if not pth or pth@@ is Object then pth = [ child.name ]
      if @parent then pth = [ @name, ...pth ]
      @trigger event, child, data, pth
  
  val: (val) ->
    if val then @set val: val
    else @get 'val'
    
  child: (name, extend, cls) ->
    Cls = cls or @childClass or @constructor
    if extend then Cls = Cls.extend4000 extend
    child = new Cls { name: name, parent: @ }
    @addChild(child)



export PubSubNode = Node.extend4000 do
  subNode: (name, extend) ->
    @child(name, extend, SubNode)
    
  pubNode: (name, extend) ->
    @child(name, extend, PubNode)
    
  command_delegate: (command, pth, value) ->
    [ target, ...pthtail ] = pth
    if targetChild = head @getChild(target)
      targetChild.command_receive(command, pthtail.join('/'), value)
    else
      @command_receive(command, pth, value)

export SubNode = PubSubNode.extend4000 do
  initialize: ->
    if @remote then @remote = each @remote, (value, name) ~>
      @[ name ] = (...args) ~>
        @trigger 'call', @, args, [ @name, name ]
    
  command_receive: (command, pth, value) ->
    switch command
      | 'status' =>
        @set { "#{pth}":  value }


export PubNode = PubSubNode.extend4000 do
  command_receive: (command, pth, value) ->
    switch command
      | 'command' =>
        targetFunction = @expose?[pth]
        if not targetFunction then return #console.log "warning, no function named '#{ pth }' at #{ @inspect() }"
        if targetFunction is true then targetFunction = @[ pth ]
        targetFunction.apply @, value

      | 'set' =>
        if @get(pth) isnt value
          @set set = { "#{pth}":  value }


export MqttNode = PubSubNode.extend4000 do
  childClass: PubSubNode
  
  initialize: ->
    if not @matt = @options?mqtt
      @mqtt = mqtt.connect @{ host, port }

    @on 'change', (child, data, pth) ~>
      each child.changedAttributes(), (val, key) ~> 
        @publish path.join(@name, 'status', ...pth, key), JSON.stringify(val), retain: true

    @on 'call', (child, data, pth) ~>
      @publish path.join(@name, 'command', ...pth), JSON.stringify(data)
      
    @subscribe path.join(@name, '#')
    
    @mqtt.on 'message', (pth, message) ~>
      pth = pth.split('/')
      [ self, command, ...pthtail ] = pth
      @command_delegate command, pthtail, JSON.parse(message)

  publish: (pth, data) ->
    if pth@@ isnt String then pth = pth.join('/')
    console.log @name, 'PUB', pth, data
    @mqtt.publish pth, data
    
  subscribe: (pth) ->
    if pth@@ isnt String then pth = pth.join('/')
    console.log @name, 'SUB', pth
    @mqtt.subscribe pth
    
  call: (pth, ...value) ->
    true


# export lego = Node.extend4000 do
#   requires: [ 'logger' ]
  
#   settings: do
#     name: os.hostname() + "/" + path.basename(path.dirname(require.main.filename))
#     port: 1883

#   init: (callback) ->
#     @settings.name = @settings.name
#     @settings.path = path.join(@settings.name)
    
#     @logger = @env.l.child({tags: {+mqtt}})
#     @log = @logger.log.bind(@logger)
    
#     @log 'connecting to mqtt://' + @settings.host + ":" + @settings.port, {}, 'offline'
#     @client = mqtt.connect @settings{ host, port }
#     #<<<
#     #  will: { topic: @settings.path + '/status', payload: JSON.stringify({ status: -1 }) }
      
#     @client.on 'connect', ~> 
# #      @client.publish @settings.path + '/status', JSON.stringify({ status: 1 })
      
#       @client.subscribe [ 'who' ]
      
#       @client.on 'message', (topic, msg) ~> 
#         if topic != 'who' then return
#         @client.publish msg, @settings.path
        
#       @log 'connected', {  }, 'init', 'ok'
#       callback()

#   who: -> new p (resolve,reject) ~> 
#     who = "who" + new Date().getTime()
#     @client.subscribe who, ~>
#       clients = {  }
#       @client.on 'message', (topic, msg) -> if topic != who then return else clients[String msg] = true
#       @client.publish 'who', who
#       setTimeout((~> @client.unsubscribe who, -> resolve clients), 500)

#   on: (...args) -> @client.on.apply(@client, args)
  
#   subscribe: (...args) -> @client.subscribe.apply(@client, args)
  
#   publish: (...args) -> @client.publish.apply(@client, args)
  
#   unsubscribe: (...args) -> @client.unsubscribe.apply(@client, args)

#   Device: (name) -> new export Device(@, name)
  
#   Sensor: (name) -> new export Node(@, path.join('sensors', name))
    
#   end: -> @client.end()
