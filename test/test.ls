require! {
  path
  assert
  '../index.ls': { RootNode, Node }
}

describe 'abstract', ->

  specify 'node publish', ->

      
    location = new Node('root')

    location.on 'change', (child, p) ->
      console.log 'location change', child, p, child.changedAttributes()
    
    publist = [  ]

    device = location.child('device1')
    temperature = device.child('temperature')
    motion = device.child('motion')

    # # direct publish
    # device.publish 'battery', 100
    # motion.publish 'morecomplex', bla: 23

    # assert.deepEqual do
    #   [ [ 'device1/battery', 100 ], [ 'device1/motion/morecomplex', { bla: 23 } ] ],
    #   publist

    publist = [  ]

    # smart publish    
    temperature.val 21
    motion.set { bla: 3, kaka: { deep: 'data', temp: 33 } }


    temperature.test = (...args) ->
      console.log 'called with', args
    location.call('device1/temperature/test', 3, 1)


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
