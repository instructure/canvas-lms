define [
  'compiled/util/invert'
], (invert) ->

  module 'invert'

  test 'object', ->
    deepEqual invert({a: 'A', b: 'B', c: 'C', dup: 'A', obj: {foo: 'BAR'}}),
      {A: 'dup', B: 'b', C: 'c', '[object Object]': 'obj'}

  test 'object with formatter', ->
    deepEqual invert({a: 'A', b: 'B', c: 'C', dup: 'A', obj: {foo: 'BAR'}}, (s) -> s.toUpperCase()),
      {A: 'DUP', B: 'B', C: 'C', '[object Object]': 'OBJ'}

  test 'array', ->
    deepEqual invert(['a', 'b', 'c', 'd']),
      {a: '0', b: '1', c: '2', d: '3'}

  test 'array with formatter', ->
    deepEqual invert(['a', 'b', 'c', 'd'], parseInt),
      {a: 0, b: 1, c: 2, d: 3}

