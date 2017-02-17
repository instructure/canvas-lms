define [ 'compiled/str/TextHelper' ], ({delimit, truncateText, formatMessage}) ->
  QUnit.module 'TextHelper'

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

  test 'no double encoding of url', ->
    equal formatMessage("https://blah.blee.com/Steven%20Test/thing%20that%20cool…anvas_non_Demonstration_-_Flash_%28joel%29_-_123456_03.41.18PM.html "),
     "<a href='https:&#x2F;&#x2F;blah.blee.com&#x2F;Steven%20Test&#x2F;thing%20that%20cool…anvas_non_Demonstration_-_Flash_%28joel%29_-_123456_03.41.18PM.html'>https:&#x2F;&#x2F;blah.blee.com&#x2F;Steven%20Test&#x2F;thing%20that%20cool…anvas_non_Demonstration_-_Flash_%28joel%29_-_123456_03.41.18PM.html</a> "

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

  test 'formatMessage: prepends http:// to a link to example.com/things', ->
    equal formatMessage('example.com/things'), "<a href='http:&#x2F;&#x2F;example.com&#x2F;things'>example.com&#x2F;things</a>"
