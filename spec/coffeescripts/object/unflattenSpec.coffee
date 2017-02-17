define ['compiled/object/unflatten'], (unflatten) ->

  QUnit.module 'unflatten'

  test 'simple object', ->
    input =
      foo: 1
      bar: 'baz'
    deepEqual unflatten(input), input

  test 'nested params', ->
    input =
      'a[0]': 1
      'a[1]' : 2
      'a[2]' : 3
      'b': 4
      'c[d]': 5
      'c[e][ea]' : 'asdf'
      'c[f]' : true
      'c[g]' : false
      'c[h]' : ''
      'i': 7

    expected =
      a: [ 1, 2, 3 ]
      b: 4
      c:
        d: 5
        e:
          ea: 'asdf'
        f: true
        g: false
        h: ''
      i: 7

    deepEqual unflatten(input), expected
