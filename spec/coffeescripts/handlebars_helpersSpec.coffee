define [
  'compiled/handlebars_helpers'
  'jquery'
  'underscore'
  'helpers/assertions'
  'helpers/fakeENV'
  'timezone'
  'timezone/America/Detroit'
  'timezone/America/Chicago'
  'timezone/America/New_York'
], ({helpers}, $, _, {contains}, fakeENV, tz, detroit, chicago, newYork) ->

  QUnit.module 'handlebars_helpers'

  QUnit.module 'checkbox'

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

  QUnit.module 'truncate'

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

  QUnit.module 'friendlyDatetime',
    setup: ->
      @snapshot = tz.snapshot()
      tz.changeZone(detroit, 'America/Detroit')

    teardown: -> tz.restore(@snapshot)

  test 'can take an ISO string', ->
    contains helpers.friendlyDatetime('1970-01-01 00:00:00Z', hash: {pubDate: false}).string,
      "Dec 31, 1969 at 7pm"

  test 'can take a date object', ->
    contains helpers.friendlyDatetime(new Date(0), hash: {pubDate: false}).string,
      "Dec 31, 1969 at 7pm"

  test 'should parse non-qualified string relative to profile timezone', ->
    contains helpers.friendlyDatetime('1970-01-01 00:00:00', hash: {pubDate: false}).string,
      "Jan 1, 1970 at 12am"

  test 'includes a screenreader accessible version', ->
    contains helpers.friendlyDatetime(new Date(0), hash: {pubDate: false}).string,
      "<span class='screenreader-only'>Dec 31, 1969 at 7pm</span>"

  test 'includes a visible version', ->
    contains helpers.friendlyDatetime(new Date(0), hash: {pubDate: false}).string,
      "<span aria-hidden='true'>Dec 31, 1969</span>"

  QUnit.module 'contextSensitive FriendlyDatetime',
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
    contains timeTag, "Local: Dec 31, 1969 at 7pm"
    contains timeTag, "Course: Dec 31, 1969 at 6pm"

  test 'displays both zones data from a date object', ->
    timeTag = helpers.friendlyDatetime(new Date(0), hash: {pubDate: false, contextSensitive: true}).string
    contains timeTag, "Local: Dec 31, 1969 at 7pm"
    contains timeTag, "Course: Dec 31, 1969 at 6pm"

  test 'should parse non-qualified string relative to both timezones', ->
    timeTag = helpers.friendlyDatetime('1970-01-01 00:00:00', hash: {pubDate: false, contextSensitive: true}).string
    contains timeTag, "Local: Jan 1, 1970 at 12am"
    contains timeTag, "Course: Dec 31, 1969 at 11pm"

  test 'reverts to friendly display when there is no contextual timezone', ->
    ENV.CONTEXT_TIMEZONE = null
    timeTag = helpers.friendlyDatetime('1970-01-01 00:00:00Z', hash: {pubDate: false, contextSensitive: true}).string
    contains timeTag, "<span aria-hidden='true'>Dec 31, 1969</span>"

  QUnit.module 'contextSensitiveDatetimeTitle',
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
    equal titleText, "Dec 31, 1969 at 7pm"

  test 'splits title text to both zones', ->
    titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 00:00:00Z', hash: {justText: true})
    equal titleText, "Local: Dec 31, 1969 at 7pm<br>Course: Dec 31, 1969 at 6pm"

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
    equal titleText, "Dec 31, 1969 at 7pm"

  test 'stays as one title when the time is no different even if timezone names differ', ->
    ENV.TIMEZONE = 'America/Detroit'
    ENV.CONTEXT_TIMEZONE = 'America/New_York'
    titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 00:00:00Z', hash: {justText: true})
    equal titleText, "Dec 31, 1969 at 7pm"

  test "produces the html attributes if you dont specify just_text", ->
    ENV.CONTEXT_TIMEZONE = null
    titleText = helpers.contextSensitiveDatetimeTitle('1970-01-01 00:00:00Z', hash: {justText: undefined})
    equal titleText, "data-tooltip data-html-tooltip-title=\"Dec 31, 1969 at 7pm\""

  QUnit.module 'datetimeFormatted',
    setup: -> @snapshot = tz.snapshot()
    teardown: -> tz.restore(@snapshot)

  test 'should parse and format relative to profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    equal helpers.datetimeFormatted('1970-01-01 00:00:00'),
      "Jan 1, 1970 at 12am"

  QUnit.module 'ifSettingIs'

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

   QUnit.module 'accessible date pickers'

   test 'it provides a format', ->
     equal(typeof(helpers.accessibleDateFormat()), "string")

   test 'it can shorten the format for dateonly purposes',->
     shortForm = helpers.accessibleDateFormat('date')
     equal(shortForm.indexOf("hh:mm"), -1)
     ok(shortForm.indexOf("YYYY") > -1)

   test 'it can shorten the format for time-only purposes',->
     shortForm = helpers.accessibleDateFormat('time')
     ok(shortForm.indexOf("hh:mm") > -1)
     equal(shortForm.indexOf("YYYY"), -1)

   test 'it provides a common format prompt wrapped around the format', ->
     formatPrompt = helpers.datepickerScreenreaderPrompt()
     ok(formatPrompt.indexOf(helpers.accessibleDateFormat()) > -1)

   test 'it passes format info through to date format', ->
     shortFormatPrompt = helpers.datepickerScreenreaderPrompt('date')
     equal(shortFormatPrompt.indexOf(helpers.accessibleDateFormat()), -1)
     ok(shortFormatPrompt.indexOf(helpers.accessibleDateFormat('date')) > -1)

  QUnit.module 'i18n number helper',
    setup: ->
      @ret = '47.00%'
      @stub(I18n, 'n').returns(@ret)

  test 'proxies to I18n.localizeNumber', ->
    num = 47
    precision = 2
    percentage = true
    equal helpers.n(num, hash: {precision, percentage}), @ret
    ok I18n.n.calledWithMatch(num, {precision, percentage})

