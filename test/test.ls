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
      @broker = new mosca.Server do
        port: @port
        persistence: {
          factory: mosca.persistence.Memory
        }
      @broker.on 'clientConnected',(client) -> 
          console.log('client connected', client.id);

      @broker.on 'ready', resolve

  describe 'map', ->
    true

  specify 'broker running', ->
    assert @broker
    console.log 'port', @port

  describe 'real mqtt', -> 
    before -> new p (resolve,reject) ~> 
      @root1 = new MqttNode(
        vname: 'root1'
        name: 'node0',
        host: "localhost",
        port: @port
      )

      @service_root1 = @root1.pubNode 'service1', do
        init: ->
          console.log 'seting node init val'
          @set somevalue: 1
          
        expose: { +some_api }


      setTimeout do
        (~>  

          @root2 = new MqttNode(
            vname: 'root2'
            name: 'node0',
            host: "localhost",
            port: @port
          )

          @service_root2 = @root2.subNode 'service1', remote: { +some_api }
          setTimeout resolve, 100
        ),
        100
      
    specify 'RETAIN', -> new p (resolve,reject) ~>
      assert.equal @service_root1.get('somevalue'), 1
      assert.equal @service_root2.get('somevalue'), 1
      resolve true

    specify 'STATUS', -> new p (resolve,reject) ~> 
      @service_root2.on 'remotechange:somevalue', (model, val) ->
          resolve assert.equal val, 2

      @service_root1.set somevalue: 2

    specify 'COMMAND', -> new p (resolve,reject) ~> 
      @service_root2.some_api(lala: 2)
      @service_root1.some_api = (args) ->
        resolve()

    specify 'COMMAND and receive STATUS', -> new p (resolve,reject) ~> 
      @service_root2.some_api(lala: 3)
      @service_root2.on 'remotechange:blab', (model, val) ->
        assert.deepEqual val, lala: 3
        resolve()

      @service_root1.some_api = (args) ->
        @set blab: args

    specify 'SET', -> new p (resolve,reject) ~> 
      @service_root2.set(bla: 3)
      @service_root1.on 'remotechange:bla', (model, val) ->
        resolve()

