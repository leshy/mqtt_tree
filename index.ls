require! {
  mqtt, os, path
  bluebird: p
  lodash: { each, reduce }
  'backbone4000': Backbone
}


export Node = Backbone.Model.extend4000 do
  initialize: (@name, @parent) ->
    @on 'change', ~> 
      each @changedAttributes(), (value, key) ~>
        @publish key, value

    if not @parent then @initRoot()
      
        
  path: -> if @parent then path.join(@parent.path(), @name) else @name
  
  val: (val) ->
    if val then @set val: val
    else @get 'val'

  publish: (name, value) ->
    if @parent then @parent.publish(path.join(@name, name), value)
    else @pub path.join(@name, 'status', name), value
    
  child: (name) ->
    Cls = @childClass or @constructor
    new Cls name, @

  pub: (name, value) ->
    ...

  sub: (name, value) ->
    ...

  initRoot: ->
    ...



export Device = Node.extend4000 do
  initialize: (@parent, @name) ->
    @on 'change', (self, state) ~> 
      values = @changedAttributes()
      path = @path()

      each values, (value, name) ~> 
        @parent.publish path.join(@name, name), value


  setState: (state) ->
    @mqtt.publish do
      path.join(@mqtt.settings.root, 'status', @name)
      JSON.stringify({ lu: Date.now()  } <<< state ), { retain: true }


export Sensor = Node.extend4000({})


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
