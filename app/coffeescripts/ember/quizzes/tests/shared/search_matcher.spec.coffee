define ['../../shared/search_matcher'], (searchMatcher) ->

  module 'search_matcher',
    setup: ->
      @target = "One two three four"

  test 'ignores case by default', ->
    equal(searchMatcher(@target, 'one'), true )

  test 'considers case when asked to', ->
    equal( searchMatcher(@target, 'one', false), false )

  test 'finds multiples', ->
    equal(searchMatcher(@target, 'one three'), true)

  test 'finds multiples out of order', ->
    equal(searchMatcher(@target, 'four three'), true)
