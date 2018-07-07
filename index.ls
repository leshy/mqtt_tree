require! {
  mqtt, os, path
  bluebird: p
  lodash: { each, reduce, head, tail, mapValues }
  'backbone4000': Backbone
  abstractman: { GraphNode }
  colors
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
    @addChild(child = new Cls name: name, parent: @ )
    if child.init then child.init()

    child


export PubSubNode = Node.extend4000 do
  subNode: (name, extend) ->
    @child(name, extend, SubNode)
    
  pubNode: (name, extend) ->
    @child(name, extend, PubNode)
    
  command_delegate: (command, pth, value) ->
    [ target, ...pthtail ] = pth
    if targetChild = head @getChild target
      targetChild.command_receive command, pthtail.join('/'), value
    else
      @command_receive(command, pth, value)

export SubNode = PubSubNode.extend4000 do
  initialize: ->
    if @remote then @remote = each @remote, (value, name) ~>
      @[ name ] = (...args) ~>
        @trigger 'call', @, args, [ @name, name ]

    @on 'change', ~>
      each @changedAttributes(), (value, key) ~>
        @trigger 'set', @, value, [ @name, key ]
    
  command_receive: (command, pth, value) ->
    switch command
      | 'status' =>
        @set set = { "#{pth}":  value }, silent: true
        @trigger "remotechange:#{pth}", @, value
        @trigger 'remotechange', @, set

export PubNode = PubSubNode.extend4000 do
  command_receive: (command, pth, value) ->
    switch command
      | 'command' =>
        targetFunction = @expose?[pth]
        if not targetFunction then return #console.log "warning, no function named '#{ pth }' at #{ @inspect() }"
        if targetFunction is true then targetFunction = @[ pth ]
        targetFunction.apply @, value

      | 'set' =>
        @set set = { "#{pth}":  value }
        @trigger "remotechange:#{pth}", @, value, pth
        @trigger 'remotechange', @, set, pth


# supports https://github.com/mqtt-smarthome/mqtt-smarthome/blob/master/Architecture.md
# specification
#
# implements COMMAND, SET and STATUS calls
export MqttNode = PubSubNode.extend4000 do
  childClass: PubSubNode
  
  initialize: ->
    if not @matt = @options?mqtt
      @mqtt = mqtt.connect @{ host, port }

    @on 'change', (child, data, pth) ~>
      each child.changedAttributes(), (val, key) ~> 
        @publish do
          path.join(@name, 'status', ...pth, key)
          JSON.stringify(val)
          retain: true

    @on 'call', (child, data, pth) ~>
      @publish path.join(@name, 'command', ...pth), JSON.stringify(data)

    @on 'set', (child, data, pth) ~>
      @publish path.join(@name, 'set', ...pth), JSON.stringify(data)
      
    @subscribe path.join(@name, '#')
    
    @mqtt.on 'message', (pth, message) ~>
      console.log colors.yellow(">>"), @vname, pth, String(message)
      pth = pth.split('/')
      [ self, command, ...pthtail ] = pth
      @command_delegate command, pthtail, JSON.parse(message)

  publish: (pth, data, opts) ->
    if pth@@ isnt String then pth = pth.join('/')
    console.log colors.green("PUB"), @vname, pth, data
    @mqtt.publish pth, data, opts
    
  subscribe: (pth) ->
    if pth@@ isnt String then pth = pth.join('/')
    console.log colors.red("SUB"), @vname, pth
    @mqtt.subscribe pth
    
  call: (pth, ...value) ->
    true

