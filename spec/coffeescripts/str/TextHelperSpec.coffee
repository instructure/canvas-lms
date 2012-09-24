define [ 'compiled/str/TextHelper' ], ({delimit, truncateText}) ->
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

  test 'truncateText: should truncate on word boundaries without exceeding max', ->
    equal truncateText("zomg zomg zomg", max: 11), "zomg..."
    equal truncateText("zomg zomg zomg", max: 12), "zomg zomg..."
    equal truncateText("zomg zomg zomg", max: 13), "zomg zomg..."
    equal truncateText("zomg      whitespace!   ", max: 15), "zomg..."

  test 'truncateText: should not truncate if the string fits', ->
    equal truncateText("zomg zomg zomg", max: 14), "zomg zomg zomg"
    equal truncateText("zomg      whitespace!   ", max: 16), "zomg whitespace!"

  test 'truncateText: should break up the first word if it exceeds max', ->
    equal truncateText("zomgzomg", max: 6), "zom..."
    equal truncateText("zomgzomg", max: 7), "zomg..."
