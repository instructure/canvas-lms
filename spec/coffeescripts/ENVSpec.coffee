define ['require'], (require) ->

  module 'ENV'

  asyncTest 'simple', ->
    require ['ENV'], (env1) ->
      env1.thing1 = 3
      require ['ENV'], (env2) ->
        env2.thing2 = 4
        equal env1.thing1, 3
        equal env1.thing2, 4
        equal env2.thing1, 3
        equal env2.thing2, 4
        strictEqual env1, env2
        start()

