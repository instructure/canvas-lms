define ['jquery'], (jQuery) ->

  module 'instructure jquery patches'

  test 'parseJSON', ->
    deepEqual(jQuery.parseJSON('{ "var1": "1", "var2" : 2 }'), { "var1": "1", "var2" : 2 }, 'should still parse without the prefix')
    deepEqual(jQuery.parseJSON('while(1);{ "var1": "1", "var2" : 2 }'), { "var1": "1", "var2" : 2 }, 'should parse with the prefix')

