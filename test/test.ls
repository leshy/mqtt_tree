require! {
  path
  assert
  lodash: { map, omit, head }
  '../index.ls': { RootNode, PubNode, SubNode, MqttNode }
  bluebird: p
}

# describe 'abstract', ->
#   specify 'node publish', ->
#     location = new CallNode('room')
    
#     publist = [  ]

#     location.on 'change', (child, data, pth) ->
#       change = child.changedAttributes()
#       if not change.lu then change.lu = Date.now()
# #      console.log 'PUB', pth, change
#       publist.push [ pth, change ]

#     device = location.child('device1')
#     temperature = device.child 'temperature'
#     motion = device.child 'motion' 

#     # smart publish    
#     temperature.val 21
#     motion.set { bla: 3, kaka: { deep: 'data', temp: 33 } }

#     assert.deepEqual do
#       (map publist, ([path, val]) -> [path, omit(val, 'lu')]),
#       [ [ [ 'device1', 'temperature'], { val: 21 } ],
#         [ ['device1', 'motion'], { bla: 3, kaka: { deep: 'data', temp: 33 } } ] ]

describe 'real world mqtt', ->
  mosca = require('mosca');

  before -> new p (resolve,reject) ~> 
    require('get-port')().then (@port) ~>  
      @broker = new mosca.Server port: @port

      @broker.on 'clientConnected',(client) -> 
          console.log('client connected', client.id);

      @broker.on 'ready', resolve

  specify 'broker running', ->
    assert @broker
    console.log 'port', @port

  describe 'real mqtt', -> 
    before -> new p (resolve,reject) ~> 
      @root1 = new MqttNode(
        name: 'node0',
        host: "localhost",
        port: @port
      )


      @root2 = new MqttNode(
        name: 'node0',
        host: "localhost",
        port: @port
      )

      @service_root1 = @root1.pubNode 'service1', do
        initialize: ->
          @set somevalue: 1
        expose: { +some_api }

      @service_root2 = @root2.subNode 'service1', do
        remote: { +some_api }

      setTimeout resolve, 100

    specify 'attribute change update', -> new p (resolve,reject) ~> 
      @service_root2.on 'remotechange:somevalue', (model, val) ->
          resolve assert.equal val, 2

      @service_root1.set somevalue: 2

    specify 'api call propagade update', -> new p (resolve,reject) ~> 
      @service_root2.some_api(lala: 2)

      @service_root1.some_api = (args) ->
        resolve()

    specify 'api call and change', -> new p (resolve,reject) ~> 
      @service_root2.some_api(lala: 3)

      @service_root2.on 'remotechange:blab', (model, val) ->
        assert.deepEqual val, lala: 3
        resolve()

      @service_root1.some_api = (args) ->
        @set blab: args

    specify 'change request', -> new p (resolve,reject) ~> 
      @service_root2.set(bla: 3)
      @service_root1.on 'change:bla', (model, val) ->
        resolve()

