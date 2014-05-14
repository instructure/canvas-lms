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

  test 'checkboxes - hidden input values', ->
    hiddenInput = ({disabled}) ->
      inputs = helpers.checkbox.call context, "blah",
        hash: {disabled}
      div = $("<div>#{inputs}</div>")
      div.find("[type=hidden]")

    ok !hiddenInput(disabled: false).prop("disabled")
    ok  hiddenInput(disabled: true).prop("disabled")

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
    equal helpers.friendlyDatetime('1970-01-01 00:00:00Z', hash: {pubDate: false}).string,
      "<time title='Dec 31, 1969 at  7:00pm' datetime='1970-01-01T00:00:00.000Z' undefined>Dec 31, 1969</time>"

  test 'can take a date object', ->
    tz.changeZone(detroit, 'America/Detroit')
    equal helpers.friendlyDatetime(new Date(0), hash: {pubDate: false}).string,
      "<time title='Dec 31, 1969 at  7:00pm' datetime='1970-01-01T00:00:00.000Z' undefined>Dec 31, 1969</time>"

  test 'should parse non-qualified string relative to profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    equal helpers.friendlyDatetime('1970-01-01 00:00:00', hash: {pubDate: false}).string,
      "<time title='Jan 1, 1970 at 12:00am' datetime='1970-01-01T05:00:00.000Z' undefined>Jan 1, 1970</time>"

  module 'datetimeFormatted',
    setup: -> @snapshot = tz.snapshot()
    teardown: -> tz.restore(@snapshot)

  test 'should parse and format relative to profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    equal helpers.datetimeFormatted('1970-01-01 00:00:00', hash: {pubDate: false}),
      "Jan 1, 1970 at 12:00am"
