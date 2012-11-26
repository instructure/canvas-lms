define ['compiled/arr/walk'], (walk) ->

  module 'arr/walk'

  test 'walks a tree object', ->
    arr = [{name: 'a'}, {name: 'b'}]
    prop = 'none'
    str = ''
    walk arr, prop, (item) -> str += item.name
    equal str, 'ab', 'calls iterator with item'

    a = [{}]
    walk a, 'nuthin', (item, arr) ->
      equal arr, a, 'calls iterator with obj'

    a = [
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

    c = 0
    walk a, 'a', -> c++
    equal c, 11

