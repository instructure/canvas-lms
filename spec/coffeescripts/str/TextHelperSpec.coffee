define [ 'compiled/str/TextHelper' ], ({delimit}) ->
  module 'TextHelper'

  test 'delimit: comma-delimits long numbers', ->
    equal delimit(123456), '123,456'
    equal delimit(9999999), '9,999,999'
    equal delimit(-123456), '-123,456'
    equal delimit(123456), '123,456'

  test 'delimit: comma-delimits integer portion only of decimal numbers', ->
    equal delimit(123456.12521), '123,456.12521'
    equal delimit(9999999.99999), '9,999,999.99999'

  test 'delimit: does not comma-delimit short numbers', ->
    equal delimit(123), '123'
    equal delimit(0), '0'
    equal delimit(null), '0'

  test 'delimit: should not error on NaN', ->
    equal delimit(0/0), 'NaN'
    equal delimit(5/0), 'Infinity'
    equal delimit(-5/0), '-Infinity'
