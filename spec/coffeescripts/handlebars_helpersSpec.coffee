define [
  'compiled/handlebars_helpers'
  'jquery'
  'underscore'
  'helpers/fakeENV'
  'timezone'
  'vendor/timezone/America/Detroit'
  'vendor/timezone/America/Chicago'
  'vendor/timezone/America/New_York'
], ({helpers}, $, _, fakeENV, tz, detroit, chicago, newYork) ->

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
    setup: ->
      @snapshot = tz.snapshot()
      tz.changeZone(detroit, 'America/Detroit')

    teardown: -> tz.restore(@snapshot)

  test 'can take an ISO string', ->
    equal helpers.friendlyDatetime('1970-01-01 00:00:00Z', hash: {pubDate: false}).string,
      "<time data-tooltip title='Dec 31, 1969 at  7:00pm' datetime='1970-01-01T00:00:00.000Z' undefined>Dec 31, 1969</time>"

  test 'can take a date object', ->
    equal helpers.friendlyDatetime(new Date(0), hash: {pubDate: false}).string,
      "<time data-tooltip title='Dec 31, 1969 at  7:00pm' datetime='1970-01-01T00:00:00.000Z' undefined>Dec 31, 1969</time>"

  test 'should parse non-qualified string relative to profile timezone', ->
    equal helpers.friendlyDatetime('1970-01-01 00:00:00', hash: {pubDate: false}).string,
      "<time data-tooltip title='Jan 1, 1970 at 12:00am' datetime='1970-01-01T05:00:00.000Z' undefined>Jan 1, 1970</time>"

  module 'contextSensitive FriendlyDatetime',
    setup: ->
      @snapshot = tz.snapshot()
      fakeENV.setup()
      ENV.CONTEXT_TIMEZONE = "America/Chicago"
      tz.changeZone(detroit, 'America/Detroit')
      tz.preload("America/Chicago", chicago)

    teardown: ->
      fakeENV.teardown()
      tz.restore(@snapshot)

  test 'displays both zones data from an ISO string', ->
    timeTag = helpers.friendlyDatetime('1970-01-01 00:00:00Z', hash: {pubDate: false, contextSensitive: true}).string
    ok(timeTag.indexOf("Local: Dec 31, 1969 at  7:00pm") > -1)
    ok(timeTag.indexOf("Course: Dec 31, 1969 at  6:00pm") > -1)

  test 'displays both zones data from a date object', ->
    timeTag = helpers.friendlyDatetime(new Date(0), hash: {pubDate: false, contextSensitive: true}).string
    ok(timeTag.indexOf("Local: Dec 31, 1969 at  7:00pm") > -1)
    ok(timeTag.indexOf("Course: Dec 31, 1969 at  6:00pm") > -1)

  test 'should parse non-qualified string relative to both timezones', ->
    timeTag = helpers.friendlyDatetime('1970-01-01 00:00:00', hash: {pubDate: false, contextSensitive: true}).string
    ok(timeTag.indexOf("Local: Jan 1, 1970 at 12:00am") > -1)
    ok(timeTag.indexOf("Course: Dec 31, 1969 at 11:00pm") > -1)

  test 'reverts to friendly display when there is no contextual timezone', ->
    ENV.CONTEXT_TIMEZONE = null
    timeTag = helpers.friendlyDatetime('1970-01-01 00:00:00Z', hash: {pubDate: false, contextSensitive: true}).string
    equal timeTag, "<time data-tooltip title='Dec 31, 1969 at  7:00pm' datetime='1970-01-01T00:00:00.000Z' undefined>Dec 31, 1969</time>"



  module 'contextSensitiveDatetimeTitle',
    setup: ->
      @snapshot = tz.snapshot()
      fakeENV.setup()
      ENV.CONTEXT_TIMEZONE = "America/Chicago"
      tz.changeZone(detroit, 'America/Detroit')
      tz.preload("America/Chicago", chicago)
      tz.preload("America/New_York", newYork)

    teardown: ->
      fakeENV.teardown()
      tz.restore(@snapshot)

  test 'just passes through to datetime string if there is no contextual timezone', ->
    ENV.CONTEXT_TIMEZONE = null
    titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 00:00:00Z', hash: {justText: true})
    equal titleText, "Dec 31, 1969 at  7:00pm"

  test 'splits title text to both zones', ->
    titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 00:00:00Z', hash: {justText: true})
    equal titleText, "Local: Dec 31, 1969 at  7:00pm<br>Course: Dec 31, 1969 at  6:00pm"

  test "properly spans day boundaries", ->
    ENV.TIMEZONE = 'America/Chicago'
    tz.changeZone(chicago, 'America/Chicago')
    ENV.CONTEXT_TIMEZONE = 'America/New_York'
    titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 05:30:00Z', hash: {justText: true})
    equal titleText, "Local: Dec 31, 1969 at 11:30pm<br>Course: Jan 1, 1970 at 12:30am"

  test 'stays as one title when the timezone is no different', ->
    ENV.TIMEZONE = 'America/Detroit'
    ENV.CONTEXT_TIMEZONE = 'America/Detroit'
    titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 00:00:00Z', hash: {justText: true})
    equal titleText, "Dec 31, 1969 at  7:00pm"

  test 'stays as one title when the time is no different even if timezone names differ', ->
    ENV.TIMEZONE = 'America/Detroit'
    ENV.CONTEXT_TIMEZONE = 'America/New_York'
    titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 00:00:00Z', hash: {justText: true})
    equal titleText, "Dec 31, 1969 at  7:00pm"

  test "produces the html attributes if you dont specify just_text", ->
    ENV.CONTEXT_TIMEZONE = null
    titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 00:00:00Z', hash: {justText: undefined})
    equal titleText, "data-tooltip title=\"Dec 31, 1969 at  7:00pm\""



  module 'datetimeFormatted',
    setup: -> @snapshot = tz.snapshot()
    teardown: -> tz.restore(@snapshot)

  test 'should parse and format relative to profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    equal helpers.datetimeFormatted('1970-01-01 00:00:00', hash: {pubDate: false}),
      "Jan 1, 1970 at 12:00am"

  module 'ifSettingIs',

    test 'it runs primary case if setting matches', ->
      ENV.SETTINGS = {key: 'value'}
      semaphore = false
      funcs = {
        fn: (()-> semaphore = true ),
        inverse: (()-> throw new Error("Dont call this!"))
      }
      helpers.ifSettingIs('key', 'value', funcs)
      equal semaphore, true

    test 'it runs inverse case if setting does not match', ->
      ENV.SETTINGS = {key: 'NOTvalue'}
      semaphore = false
      funcs = {
        inverse: (()-> semaphore = true ),
        fn: (()-> throw new Error("Dont call this!"))
      }
      helpers.ifSettingIs('key', 'value', funcs)
      equal semaphore, true

    test 'it runs inverse case if setting does not exist', ->
      ENV.SETTINGS = {}
      semaphore = false
      funcs = {
        inverse: (()-> semaphore = true ),
        fn: (()-> throw new Error("Dont call this!"))
      }
      helpers.ifSettingIs('key', 'value', funcs)
      equal semaphore, true
