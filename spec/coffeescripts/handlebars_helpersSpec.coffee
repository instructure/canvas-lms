define [
  'compiled/handlebars_helpers'
  'jquery'
  'underscore'
  'timezone'
  'vendor/timezone/America/Detroit'
], ({helpers}, $, _, tz, detroit) ->

  module 'handlebars_helpers'

  module 'checkbox'

  context =
    likes:
      tacos: true
    human: true
    alien: false

  testCheckbox = (context, prop, hash={}) ->
    $input = $("<span>#{helpers.checkbox.call(context, prop, {hash: hash}).string}</span>").find('input').eq(1)

    checks = _.defaults hash,
      value: 1
      tagName: 'INPUT'
      type: 'checkbox'
      name: prop
      checked: context[prop]
      id: prop

    for key, val of checks
      equal $input.prop(key), val

  test 'simple case', ->
    testCheckbox context, 'human'

  test 'custom hash attributes', ->
    hash =
      class: 'foo bar baz'
      id: 'custom_id'
    testCheckbox context, 'human', hash, hash

  test 'nested property', ->
    testCheckbox context, 'likes.tacos',
      id: 'likes_tacos'
      name: 'likes[tacos]'
      checked: context.likes.tacos

  test 'titleize', ->
    equal helpers.titleize('test_string'), 'Test String'
    equal helpers.titleize(null), ''
    equal helpers.titleize('test_ _string'), 'Test String'

  test 'toPrecision', ->
    equal helpers.toPrecision(3.6666666, 2), '3.7'

  module 'truncate'
  test 'default truncates 30 characters', ->
    text = "asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf"
    truncText = helpers.truncate text
    equal truncText.length, 30, "Truncates down to 30 letters"

  test 'expects options for max (length)', ->
    text = "asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf"
    truncText = helpers.truncate text, 10
    equal truncText.length, 10, "Truncates down to 10 letters"

  test 'supports truncation left', ->
    text = "going to the store"
    truncText = helpers.truncate_left text, 15
    equal truncText, "...to the store", "Reverse truncates"

  module 'friendlyDatetime',
    setup: -> @snapshot = tz.snapshot()
    teardown: -> tz.restore(@snapshot)

  test 'can take an ISO string', ->
    tz.changeZone(detroit, 'America/Detroit')
    # the datetime attribute in the output element is (for now) inappropriately
    # fudged, so we need to cover that in the spec. we'll correct it in a later
    # commit where we can manage all the ramifications
    datetime = $.fudgeDateForProfileTimezone(new Date(0)).toISOString()
    equal helpers.friendlyDatetime('1970-01-01 00:00:00Z', hash: {pubDate: false}).string,
      "<time title='Dec 31, 1969 at  7:00pm' datetime='#{datetime}' undefined>Dec 31, 1969</time>"

  test 'can take a date object', ->
    tz.changeZone(detroit, 'America/Detroit')
    # ditto
    datetime = $.fudgeDateForProfileTimezone(new Date(0)).toISOString()
    equal helpers.friendlyDatetime(new Date(0), hash: {pubDate: false}).string,
      "<time title='Dec 31, 1969 at  7:00pm' datetime='#{datetime}' undefined>Dec 31, 1969</time>"
