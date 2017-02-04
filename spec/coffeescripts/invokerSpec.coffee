define ['compiled/util/invoker'], (invoker) ->

  obj = invoker
    one: ->
      1
    noMethod: ->
      'noMethod'

  QUnit.module 'Invoker'

  test 'should call a method with invoke', =>
    result = obj.invoke 'one'
    equal result, 1

  test "should call noMethod when invoked method doesn't exist", =>
    result = obj.invoke 'non-existent'
    equal result, 'noMethod'

