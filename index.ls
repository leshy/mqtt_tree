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

  initialize: (@name, @parent, @options={}) ->
    @children.on 'all', (event, child, data, pth) ~>
      if not pth or pth@@ is Object then pth = child.name
      @trigger event, child, data, path.join(@name, pth)
  
  val: (val) ->
    if val then @set val: val
    else @get 'val'
    
  child: (name, extend) ->
    Cls = @childClass or @constructor
    if extend then Cls = Cls.extend4000 extend
    child = new Cls name, @
    @addChild(child)
    
        

export CallNode = Node.extend4000 do

  initialize: ->
    if @remote then @remote = each @remote, (value, name) ~>
      @[ name ] = (...args) ~>
        @trigger 'call', @, args, name
      
  call: (pth, ...value) ->
    if pth@@ is String then pth = pth.split('/')

    [ target, ...pth ] = pth
    
    if (not pth.length)
      targetFunction = @expose?[target]
      if not targetFunction then return console.log "warning, no function named '#{ target }' at #{ @inspect() }"
      if targetFunction is true then targetFunction = @[ target ]
      targetFunction.apply @, value
    else
      targetChild = head @getChild(target)
      if not targetChild then return console.log 'warning, child with name', target, 'not found'
      targetChild.call(pth, ...value)
      

export MqttNode = Node.extend4000 do
  pub: (name, value) ->
    true
    
  sub: (name, callback) ->
    true

  initRoot: -> true
  


export lego = Node.extend4000 do
  requires: [ 'logger' ]
  
  settings: do
    name: os.hostname() + "/" + path.basename(path.dirname(require.main.filename))
    port: 1883

  init: (callback) ->
    @settings.name = @settings.name
    @settings.path = path.join(@settings.name)
    
    @logger = @env.l.child({tags: {+mqtt}})
    @log = @logger.log.bind(@logger)
    
    @log 'connecting to mqtt://' + @settings.host + ":" + @settings.port, {}, 'offline'
    @client = mqtt.connect @settings{ host, port }
    #<<<
    #  will: { topic: @settings.path + '/status', payload: JSON.stringify({ status: -1 }) }
      
    @client.on 'connect', ~> 
#      @client.publish @settings.path + '/status', JSON.stringify({ status: 1 })
      
      @client.subscribe [ 'who' ]
      
      @client.on 'message', (topic, msg) ~> 
        if topic != 'who' then return
        @client.publish msg, @settings.path
        
      @log 'connected', {  }, 'init', 'ok'
      callback()

  who: -> new p (resolve,reject) ~> 
    who = "who" + new Date().getTime()
    @client.subscribe who, ~>
      clients = {  }
      @client.on 'message', (topic, msg) -> if topic != who then return else clients[String msg] = true
      @client.publish 'who', who
      setTimeout((~> @client.unsubscribe who, -> resolve clients), 500)

  on: (...args) -> @client.on.apply(@client, args)
  
  subscribe: (...args) -> @client.subscribe.apply(@client, args)
  
  publish: (...args) -> @client.publish.apply(@client, args)
  
  unsubscribe: (...args) -> @client.unsubscribe.apply(@client, args)

  Device: (name) -> new export Device(@, name)
  
  Sensor: (name) -> new export Node(@, path.join('sensors', name))
    
  end: -> @client.end()
