require! {
  path
  assert
  '../index.ls': { RootNode, Node }
}

describe 'abstract', ->

  specify 'node publish', ->

    TestNode = Node.extend4000 do
      initRoot: -> true
      sub: -> true
      pub: (name, value) ->
        console.log "PUB", name, value
      
    location = new TestNode('root')
    publist = [  ]

    device = location.child('device1')
    temperature = device.child('temperature')
    motion = device.child('motion')

    # direct publish
    device.publish 'battery', 100
    motion.publish 'morecomplex', bla: 23

    # assert.deepEqual do
    #   [ [ 'device1/battery', 100 ], [ 'device1/motion/morecomplex', { bla: 23 } ] ],
    #   publist

    publist = [  ]

    # smart publish    
    temperature.val 21
    motion.set { bla: 3, kaka: { deep: 'data', temp: 33 } }

  specify 'node reply', ->
    
    true

    # assert.deepEqual do
    #   [ [ 'device1/temperature/val', 21 ],
    #     [ 'device1/motion/bla', 3 ],
    #     [ 'device1/motion/kaka', { deep: 'data', temp: 33 } ] ],
    #   publist


  # specify 'rootPublish', ->
  #   root = new RootNode('root')
  #   root.pub 
  #   console.log root.publish {
  #     someval: 11
  #     device: {
  #       batteru: 83
  #       temperature: { lu: 'lala', val: 21 }
  #       motion: { lu: 'never', val: false }
  #     }
  #   }
