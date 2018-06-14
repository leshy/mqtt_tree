backbone = require 'backbone4000'
require! { mqtt, os }

exports.lego = backbone.Model.extend4000 do
  requires: [ 'logger' ]
  
  settings: do
    name: os.hostname()
    port: 1883
    
  init: (callback) ->
    @settings.name = @settings.name
    @settings.path = 'devices/' + @settings.name
    
    @env.log 'connecting to ' + @settings.host, {}, 'offline'
    @env.mqtt = @client = mqtt.connect @settings{ host, port } <<<
      will: { topic: @settings.path + '/status', payload: false }
      
    @client.on 'connect', ~> 
      @client.publish @settings.path + '/status', 'online'
      @client.publish 'connect', @settings.path

      
      @client.subscribe [ 'who' ]
      
      @client.on 'message', (topic, msg) ~> 
        if topic != 'who' then return
        console.log 'who', msg
        @client.publish msg, @settings.path
        
      @env.log 'mqtt connected to ' + @settings.host, {}, 'init','ok'
      callback()

 
