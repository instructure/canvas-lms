define ['compiled/arr/reduceWalk'], (reduceWalk) ->

  module 'arr/reduceWalk'

  test 'reduces a tree to a single value', 3, ->

    arr = [{}]
    sum = reduceWalk arr, 'nothin', (mem, item, a) ->
      equal a, arr, 'calls iterator with arr'
    , 0

    arr = [
      {
        name: 'a'
        children:[
          {name: 'b'}
          {name: 'c'}
        ]
      }
      {
        name: 'd'
        children: [
          {name: 'e'}
        ]
      }
    ]

    names = reduceWalk arr, 'children', (str, item) ->
      str + item.name
    , ''
    equal names, 'abcde', 'walks depth first'

    arr = [
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
      { #11
        a: [] # empty
      }
    ]

    count = reduceWalk arr, 'a', (count, item) ->
      count + 1
    , 0

    equal count, 11

