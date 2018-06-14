backbone = require 'backbone4000'
require! { mqtt, os, path, bluebird: p }


exports.lego = backbone.Model.extend4000 do
  requires: [ 'logger' ]
  
  settings: do
    name: os.hostname() + "/" + path.basename(path.dirname(require.main.filename))
    port: 1883
    
  init: (callback) ->
    @env.mqtt = @
    @settings.name = @settings.name
    @settings.path = path.join(@settings.root, 'device', @settings.name)
    @env.log 'connecting to ' + @settings.host, {}, 'offline'
    @client = mqtt.connect @settings{ host, port } <<<
      will: { topic: @settings.path + '/status', payload: false }
      
    @client.on 'connect', ~> 
      @client.publish @settings.path + '/status', 'online'
      @client.publish 'connect', @settings.path
      
      @client.subscribe [ 'who' ]
      
      @client.on 'message', (topic, msg) ~> 
        if topic != 'who' then return
        @client.publish msg, @settings.path
        
      @env.log 'mqtt connected to ' + @settings.host, {}, 'init','ok'
      callback()

  who: -> new p (resolve,reject) ~> 
    who = "who" + new Date().getTime()
    @client.subscribe who, ~>
      clients = {  }
      @client.on 'message', (topic, msg) -> if topic != who then return else clients[String msg] = true
      @client.publish 'who', who
      setTimeout((~> @client.unsubscribe who, -> resolve clients), 500)

  subscribe: (...args) -> @client.subscribe.apply(@client, args)
  publish: (...args) -> @client.publish.apply(@client, args)
  unsubscribe: (...args) -> @client.unsubscribe.apply(@client, args)
  
  end: -> @client.end()
