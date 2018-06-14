backbone = require 'backbone4000'
require! { mqtt, os }

exports.lego = backbone.Model.extend4000 do
  requires: [ 'logger' ]
  init: (callback) ->
    @settings.name = @settings.name or os.hostname()
    @env.client = @client = mqtt.connect do
      'mqtts://yourbroker',
      will: { topic: 'disconnect', payload: @settings.name }
      
    @client.on 'connect', ~> 
      client.publish 'connect', @settings.name
      @env.log 'mqtt connected to ' + colors.green(@settings.host), {}, 'init','ok'
      callback()

 
