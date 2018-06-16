require! {
  path
  assert
  lodash: { map, omit }
  '../index.ls': { RootNode, CallNode }
  bluebird: p
}

describe 'abstract', ->
  specify 'node publish', ->
    location = new CallNode('room')
    
    publist = [  ]

    location.on 'change', (child, data, pth) ->
      change = child.changedAttributes()
      if not change.lu then change.lu = Date.now()
#      console.log 'PUB', pth, change
      publist.push [ pth, change ]

    device = location.child('device1')
    temperature = device.child 'temperature'
    motion = device.child 'motion' 

    # smart publish    
    temperature.val 21
    motion.set { bla: 3, kaka: { deep: 'data', temp: 33 } }

    assert.deepEqual do
      (map publist, ([path, val]) -> [path, omit(val, 'lu')]),
      [ [ 'room/device1/temperature', { val: 21 } ],
        [ 'room/device1/motion', { bla: 3, kaka: { deep: 'data', temp: 33 } } ] ]

  describe 'rpc', ->
    room = new CallNode('room')
    device1 = room.child 'device1'

    specify 'expose', -> 

      calls = [  ]
      temperature = device1.child 'temperature', do
        expose:
          # method whitelist
          lala: true
          # inline call
          turnoff: (...args) ->
            assert.equal temperature, @ # make sure this is preserved
            calls.push ['turnoff', args]
          
        lala: (...args) ->
          assert.equal temperature, @
          calls.push ['lala', args]

      room.call('device1/temperature/lala', 'whitelist', 1, 2)
      room.call('device1/temperature/turnoff', 'inline', 'bla')
      
      assert.deepEqual do
        [ [ 'lala', [ 'whitelist', 1, 2 ] ],[ 'turnoff', [ 'inline', 'bla' ] ] ]
        calls  

    specify 'remote', -> 
      motion = device1.child 'motion', do
        remote: { +turnoff }
        
      calls = [  ]
      
      room.on 'call', (child, data, pth) ->
        calls.push [ pth, data ]
        assert.equal child, motion

      motion.turnoff(true, 2)
      
      assert.deepEqual do
        [ [ 'room/device1/turnoff', [ true, 2 ] ] ]
        calls

      
      

  describe 'real world mqtt', ->
    mosca = require('mosca');
    
    before -> new p (resolve,reject) ~> 
      require('get-port')().then (@port) ~>  
        @broker = new mosca.Server port: @port

        @broker.on 'clientConnected',(client) -> 
            console.log('client connected', client.id);

        #fired when a message is received
        @broker.on 'published',(packet, client) -> 
          console.log('Published', packet.payload);

        @broker.on 'ready', resolve
          
    specify 'broker running', ->
      assert @broker
      console.log 'port', @port

    specify 'real world connection', ->
      true
        

    
