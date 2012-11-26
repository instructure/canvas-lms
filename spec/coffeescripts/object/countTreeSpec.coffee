define [
  'compiled/object/countTree'
], (countTree) ->

  module 'countTree'

  test 'counts a tree', ->
    obj = {a:[{a:[{a:[{}]}]}]}
    equal countTree(obj, 'a'), 3
    equal countTree(obj, 'foo'), 0

    obj = {
      a: [
        {a: [ #1
          {a: [ #2
            {a:[ #3
              {} #4
              {} #5
            ]}
            {a:[ #6
              {} #7
              {} #8
            ]}
          ]}
          {} #9
          {} #10
        ]}
        {
          a: [] # empty
        } #11
      ]
    }
    equal countTree(obj, 'a'), 11

