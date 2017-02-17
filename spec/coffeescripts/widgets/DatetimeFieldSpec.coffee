define [
  'compiled/widget/DatetimeField'
  'jquery'
  'timezone'
  'timezone/America/Detroit'
  'timezone/America/Juneau'
  'timezone/pt_PT'
  'helpers/I18nStubber'
  'helpers/fakeENV'
], (DatetimeField, $, tz, detroit, juneau, portuguese, I18nStubber, fakeENV) ->

  moonwalk = tz.parse('1969-07-21T02:56:00Z')

  QUnit.module 'processTimeOptions',
    setup: ->
      @$field = $('<input type="text" name="due_at">')
      @field = new DatetimeField(@$field, {})

    teardown: ->
      I18nStubber.clear()

  test 'should include date and time, but not always time, by default', ->
    @field.processTimeOptions({})
    ok @field.showDate, 'showDate is true'
    ok @field.allowTime, 'allowTime is true'
    ok !@field.alwaysShowTime, 'alwaysShowTime is false'

  test 'should disallow time with dateOnly option true', ->
    @field.processTimeOptions(dateOnly: true)
    ok !@field.allowTime, 'allowTime is false'

  test 'should hide date and always show time with timeOnly option true', ->
    @field.processTimeOptions(timeOnly: true)
    ok !@field.showDate, 'showDate is false'
    ok @field.alwaysShowTime, 'alwaysShowTime is true'

  test 'should allow forcing always show time', ->
    @field.processTimeOptions(alwaysShowTime: true)
    ok @field.alwaysShowTime, 'alwaysShowTime is true'

  test 'should ignore alwaysShowTime with dateOnly option true', ->
    @field.processTimeOptions(dateOnly: true, alwaysShowTime: true)
    ok !@field.alwaysShowTime, 'alwaysShowTime is false'

  test 'should ignore both dateOnly and timeOnly if both true', ->
    @field.processTimeOptions(dateOnly: true, timeOnly: true)
    ok @field.showDate, 'showDate is true'
    ok @field.allowTime, 'allowTime is true'

  QUnit.module 'addDatePicker',
    setup: ->
      @$field = $('<input type="text" name="due_at">')
      # timeOnly=true to prevent creation of the datepicker before we do it in
      # the individual tests
      @field = new DatetimeField(@$field, timeOnly: true)

  test 'should wrap field in .input-append', ->
    @field.addDatePicker({})
    $wrapper = @$field.parent()
    ok $wrapper.hasClass('input-append'), 'parent has class .input-append'

  test 'should return the wrapper', ->
    result = @field.addDatePicker({})
    equal result[0], @$field.parent()[0]

  test 'should add datepicker trigger sibling', ->
    @field.addDatePicker({})
    $sibling = @$field.next()
    ok $sibling.hasClass('ui-datepicker-trigger'), 'has datepicker trigger sibling'

  test 'should hide datepicker trigger from aria and tab', ->
    @field.addDatePicker({})
    $trigger = @$field.next()
    equal $trigger.attr('aria-hidden'), 'true', 'hidden from aria'
    equal $trigger.attr('tabindex'), '-1', 'hidden from tab order'

  test 'should allow providing datepicker options', ->
    @field.addDatePicker(datepicker: {buttonText: 'pick me!'})
    $trigger = @$field.next()
    equal $trigger.text(), 'pick me!', 'used provided buttonText'

  QUnit.module 'addSuggests',
    setup: ->
      @$field = $('<input type="text" name="due_at">')
      @field = new DatetimeField(@$field, {})

      # undo so we can verify it was redone (or not) in the tests
      @field.$suggest?.remove()
      @field.$courseSuggest?.remove()
      @field.$suggest = @field.$courseSuggest = null

  test 'should add suggest field', ->
    @field.addSuggests(@$field)
    ok @field.$suggest
    equal @$field.next()[0], @field.$suggest[0]

  test 'should not add course suggest field by default', ->
    @field.addSuggests(@$field)
    ok !@field.$courseSuggest

  test 'should add course suggest field if ENV.CONTEXT_TIMEZONE differs', ->
    fakeENV.setup(TIMEZONE: 'America/Detroit', CONTEXT_TIMEZONE: 'America/Juneau')
    @field.addSuggests(@$field)
    ok @field.$courseSuggest
    equal @field.$suggest.next()[0], @field.$courseSuggest[0]
    fakeENV.teardown()

  QUnit.module 'constructor',
    setup: ->
      fakeENV.setup()
      @$field = $('<input type="text" name="due_at">')

    teardown: ->
      fakeENV.teardown()

  test 'should add datepicker by default', ->
    new DatetimeField(@$field, {})
    equal @$field.parent().length, 1, 'datepicker added'

  test 'should not add datepicker when timeOnly', ->
    new DatetimeField(@$field, timeOnly: true)
    equal @$field.parent().length, 0, 'datepicker not added'

  test 'should place suggest outside wrapper when adding datepicker', ->
    field = new DatetimeField(@$field, {})
    equal @$field.parent().next()[0], field.$suggest[0], 'wrapper and suggest are siblings'

  test 'should place suggest next to field when not adding datepicker', ->
    field = new DatetimeField(@$field, timeOnly: true)
    equal @$field.next()[0], field.$suggest[0], 'field and suggest are siblings'

  test 'should set the button to disabled when given the option to do so', ->
    field = new DatetimeField(@$field, disableButton: true)
    ok @$field.next().attr('disabled')

  test 'should not add hidden input by default', ->
    new DatetimeField(@$field, {})
    ok !@$field.data('hiddenInput'), 'no hidden input'
    equal @$field.attr('name'), 'due_at', 'name preserved on field'

  test 'should add hidden input when requested', ->
    new DatetimeField(@$field, addHiddenInput: true)
    ok @$field.data('hiddenInput'), 'hidden input'
    equal @$field.data('hiddenInput').attr('name'), 'due_at', 'coopted name'
    equal @$field.attr('name'), null, 'name removed from field'

  test 'should initialize from the field value', ->
    @$field.val('Jul 21, 1969 at 2:56am')
    field = new DatetimeField(@$field, {})
    equal field.$suggest.text(), 'Mon Jul 21, 1969 2:56am'

  test 'should tie it to update on change/focus/blur/keyup', ->
    field = new DatetimeField(@$field, {})

    @$field.val('Jul 21, 1969 at 2:56am').trigger('change')
    equal field.$suggest.text(), 'Mon Jul 21, 1969 2:56am'

    @$field.val('Jul 21, 1969 at 3:56am').trigger('focus')
    equal field.$suggest.text(), 'Mon Jul 21, 1969 3:56am'

    @$field.val('Jul 21, 1969 at 4:56am').trigger('blur')
    equal field.$suggest.text(), 'Mon Jul 21, 1969 4:56am'

    @$field.val('Jul 21, 1969 at 5:56am').trigger('keyup')
    equal field.$suggest.text(), 'Mon Jul 21, 1969 5:56am'

  QUnit.module 'setFromValue',
    setup: ->
      fakeENV.setup()
      @$field = $('<input type="text" name="due_at">')
      @field = new DatetimeField(@$field, {})

    teardown: ->
      fakeENV.teardown()

  test 'should set data fields', ->
    @$field.val('Jul 21, 1969 at 2:56am')
    @field.setFromValue()
    equal +@$field.data('unfudged-date'), +tz.parse('1969-07-21T02:56Z')

  test 'should set suggest text', ->
    @$field.val('Jul 21, 1969 at 2:56am')
    @field.setFromValue()
    equal @field.$suggest.text(), 'Mon Jul 21, 1969 2:56am'

  QUnit.module 'parseValue',
    setup: ->
      @snapshot = tz.snapshot()
      @$field = $('<input type="text" name="due_at">')
      @field = new DatetimeField(@$field, {})

    teardown: ->
      tz.restore(@snapshot)

  test 'sets @fudged according to browser (fudged) timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    @$field.val(tz.format(moonwalk, '%b %-e, %Y at %-l:%M%P'))
    @field.parseValue()
    equal +@field.fudged, +$.fudgeDateForProfileTimezone(moonwalk)

  test 'sets @datetime according to profile timezone', ->
    tz.changeZone(detroit, 'America/Detroit')
    @$field.val(tz.format(moonwalk, '%b %-e, %Y at %-l:%M%P'))
    @field.parseValue()
    equal +@field.datetime, +moonwalk

  test 'sets @showTime true by default', ->
    @$field.val("Jan 1, 1970 at 12:01am")
    @field.parseValue()
    equal @field.showTime, true

  test 'sets @showTime false when value is midnight in profile timezone', ->
    @$field.val("Jan 1, 1970 at 12:00am")
    @field.parseValue()
    equal @field.showTime, false

  test 'sets @showTime true for midnight if @alwaysShowTime', ->
    @field.alwaysShowTime = true
    @$field.val("Jan 1, 1970 at 12:00am")
    @field.parseValue()
    equal @field.showTime, true

  test 'sets @showTime false for non-midnight if not @allowTime', ->
    @field.allowTime = false
    @$field.val("Jan 1, 1970 at 12:01am")
    @field.parseValue()
    equal @field.showTime, false

  test 'sets not @blank and not @invalid on valid input', ->
    @$field.val("Jan 1, 1970 at 12:00am")
    @field.parseValue()
    equal @field.blank, false
    equal @field.invalid, false

  test 'sets @blank and not @invalid and null dates when no input', ->
    @$field.val("")
    @field.parseValue()
    equal @field.blank, true
    equal @field.invalid, false
    equal @field.datetime, null
    equal @field.fudged, null

  test 'sets @invalid and not @blank and null dates when invalid input', ->
    @$field.val("invalid")
    @field.parseValue()
    equal @field.blank, false
    equal @field.invalid, true
    equal @field.datetime, null
    equal @field.fudged, null

  test 'interprets bare numbers < 8 in time-only fields as 12-hour PM', ->
    @field.showDate = false
    @$field.val("7")
    @field.parseValue()
    equal tz.format(@field.datetime, '%-l%P'), '7pm'

  test 'interprets bare numbers >= 8 in time-only fields as 24-hour', ->
    @field.showDate = false
    @$field.val("8")
    @field.parseValue()
    equal tz.format(@field.datetime, '%-l%P'), '8am'
    @$field.val("13")
    @field.parseValue()
    equal tz.format(@field.datetime, '%-l%P'), '1pm'

  test 'interprets time-only fields as occurring on implicit date if set', ->
    @field.showDate = false
    @field.setDate(moonwalk)
    @$field.val("12PM")
    @field.parseValue()
    equal tz.format(@field.datetime, '%F %T'), tz.format(moonwalk, '%F ') + '12:00:00'

  QUnit.module 'updateData',
    setup: ->
      @snapshot = tz.snapshot()
      tz.changeZone(detroit, 'America/Detroit')
      @$field = $('<input type="text" name="due_at">')
      @$field.val('Jan 1, 1970 at 12:01am')
      @field = new DatetimeField(@$field, {})
      @field.datetime = moonwalk
      @field.fudged = $.fudgeDateForProfileTimezone(moonwalk)

    teardown: ->
      tz.restore(@snapshot)

  test 'sets date field to fudged time', ->
    @field.updateData()
    equal +@$field.data('date'), +@field.fudged

  test 'sets unfudged-date field to actual time', ->
    @field.updateData()
    equal +@$field.data('unfudged-date'), +moonwalk

  test 'sets invalid field', ->
    @field.updateData()
    equal @$field.data('invalid'), false

  test 'sets blank field', ->
    @field.updateData()
    equal @$field.data('blank'), false

  test 'sets value of hiddenInput, if present, to fudged time', ->
    @field.addHiddenInput()
    @field.updateData()
    equal @$field.data('hiddenInput').val(), @field.fudged.toString()

  test 'sets time-* to fudged, 12-hour values', ->
    @field.updateData()
    equal @$field.data('time-hour'), '9'
    equal @$field.data('time-minute'), '56'
    equal @$field.data('time-ampm'), 'pm'

  test 'sets time-* to fudged, 24-hour values', ->
    tz.changeLocale(portuguese, 'pt_PT', 'pt')
    @field.updateData()
    equal @$field.data('time-hour'), '21'
    equal @$field.data('time-minute'), '56'
    equal @$field.data('time-ampm'), null

  test 'only sets time-* if for full datetime field', ->
    @$field.removeData('time-hour')
    @field.showDate = false
    @field.updateData()
    equal @$field.data('time-hour'), undefined
    @field.allowTime = false
    @field.updateData()
    equal @$field.data('time-hour'), undefined

  test 'clear time-* to null if blank', ->
    @field.blank = true
    @field.updateData()
    equal @$field.data('time-hour'), null

  test 'clear time-* to null if invalid', ->
    @field.invalid = true
    @field.updateData()
    equal @$field.data('time-hour'), null

  test 'clear time-* to null if not @showTime (midnight)', ->
    @field.showTime = false
    @field.updateData()
    equal @$field.data('time-hour'), null

  QUnit.module 'updateSuggest',
    setup: ->
      @$field = $('<input type="text" name="due_at">')
      @field = new DatetimeField(@$field, {})

  test 'puts formatSuggest result in suggest text', ->
    value = 'suggested value'
    @field.formatSuggest = -> value
    @field.updateSuggest()
    equal @field.$suggest.text(), value

  test 'puts non-empty formatSuggestCourse result w/ Course prefix in course suggest text', ->
    value = 'suggested course value'
    $courseSuggest = $('<div>')
    @field.$courseSuggest = $courseSuggest
    @field.formatSuggestCourse = -> value
    @field.updateSuggest()
    equal @field.$courseSuggest.text(), "Course: #{value}"

  test 'adds Local prefix to suggest text if non-empty formatSuggestCourse result', ->
    @field.$courseSuggest = $('<div>')
    @field.formatSuggestCourse = -> 'non-empty'
    @field.updateSuggest()
    equal @field.$suggest.text(), "Local: #{@field.formatSuggest()}"

  test 'omits course suggest text if formatSuggestCourse is empty', ->
    @field.$courseSuggest = $('<div>')
    @field.formatSuggestCourse = -> ""
    @field.updateSuggest()
    equal @field.$suggest.text(), @field.formatSuggest()
    equal @field.$courseSuggest.text(), ""

  test 'adds invalid_datetime class to suggest if invalid', ->
    @field.updateSuggest()
    ok !@field.$suggest.hasClass('invalid_datetime')
    @field.invalid = true
    @field.updateSuggest()
    ok @field.$suggest.hasClass('invalid_datetime')

  QUnit.module 'alertScreenreader',
    setup: ->
      @$field = $('<input type="text" name="due_at">')
      @field = new DatetimeField(@$field, {})
      # our version of lodash doesn't play nice with sinon fake timers, so it's
      # not feasible to confirm $.screenReaderFlashMessageExclusive itself gets
      # called. but we can confirm this step, despite the coupling to
      # implementation
      @spy(@field, 'debouncedSRFME')

  test 'should alert screenreader on failure', ->
    @$field.val('invalid')
    @$field.change()
    ok @field.debouncedSRFME.withArgs("That's not a date!").called

  test 'flashes suggest text to screenreader', ->
    value = 'suggested value'
    @field.formatSuggest = -> value
    @$field.change()
    ok @field.debouncedSRFME.withArgs(value).called

  test 'flashes combined suggest text to screenreader when there is course suggest text', ->
    @field.$courseSuggest = $('<div>')
    localValue = 'suggested value'
    courseValue = 'suggested course value'
    combinedValue = "Local: #{localValue}\nCourse: #{courseValue}"
    @field.formatSuggest = -> localValue
    @field.formatSuggestCourse = -> courseValue
    @$field.change()
    ok @field.debouncedSRFME.withArgs(combinedValue).called

  test 'does not reflash same suggest text when key presses do not change anything', ->
    value = 'suggested value'
    @field.formatSuggest = -> value
    @$field.change()
    ok @field.debouncedSRFME.withArgs(value).calledOnce
    @$field.change()
    ok @field.debouncedSRFME.withArgs(value).calledOnce

  # TODO: add spec asserting actual call to $.screenReaderFlashMessageExclusive
  # is debounced, so e.g. three triggers with different suggest values within
  # ~100ms only actually creates one alert. will require upgrading lodash first
  # so we can use debounced.flush()

  QUnit.module 'formatSuggest',
    setup: ->
      @snapshot = tz.snapshot()
      tz.changeZone(detroit, 'America/Detroit')
      @$field = $('<input type="text" name="due_at">')
      @$field.val('Jul 20, 1969 at 9:56pm')
      @field = new DatetimeField(@$field, {})

    teardown: ->
      tz.restore(@snapshot)

  test 'returns result formatted in profile timezone', ->
    equal @field.formatSuggestCourse(), 'Sun Jul 20, 1969 9:56pm'

  test 'returns "" if @blank', ->
    @field.blank = true
    equal @field.formatSuggest(), ""

  test 'returns error message if @invalid', ->
    @field.invalid = true
    equal @field.formatSuggest(), @field.parseError

  test 'returns date only if @showTime false', ->
    @field.showTime = false
    equal @field.formatSuggest(), 'Sun Jul 20, 1969'

  test 'returns time only if @showDate false', ->
    @field.showDate = false
    equal @field.formatSuggest(), ' 9:56pm'

  test 'localizes formatting of dates and times', ->
    tz.changeLocale(portuguese, 'pt_PT', 'pt')
    I18nStubber.pushFrame()
    I18nStubber.setLocale 'pt_PT'
    I18nStubber.stub 'pt_PT', 'date.formats.full_with_weekday': "%a, %-d %b %Y %k:%M"
    equal @field.formatSuggest(), 'Dom, 20 Jul 1969 21:56'
    I18nStubber.popFrame()

  QUnit.module 'formatSuggestCourse',
    setup: ->
      @snapshot = tz.snapshot()
      tz.changeZone(detroit, 'America/Detroit')
      tz.preload('America/Juneau', juneau)
      fakeENV.setup(TIMEZONE: 'America/Detroit', CONTEXT_TIMEZONE: 'America/Juneau')
      @$field = $('<input type="text" name="due_at">')
      @$field.val('Jul 20, 1969 at 9:56pm')
      @field = new DatetimeField(@$field, {})

    teardown: ->
      fakeENV.teardown()
      tz.restore(@snapshot)

  test 'returns result formatted in course timezone', ->
    equal @field.formatSuggestCourse(), 'Sun Jul 20, 1969 7:56pm'

  test 'returns "" if @blank', ->
    @field.blank = true
    equal @field.formatSuggestCourse(), ""

  test 'returns "" if @invalid', ->
    @field.invalid = true
    equal @field.formatSuggestCourse(), ""

  test 'returns "" if @showTime false', ->
    @field.showTime = false
    equal @field.formatSuggestCourse(), ""

  test 'returns time only if @showDate false', ->
    @field.showDate = false
    equal @field.formatSuggestCourse(), ' 7:56pm'

  QUnit.module 'normalizeValue',
    setup: ->
      @$field = $('<input type="text" name="due_at">')
      @field = new DatetimeField(@$field, {})

  test 'trims whitespace', ->
    equal @field.normalizeValue("  abc  "), "abc"
    equal @field.normalizeValue("  "), ""

  test 'just passes through null and undefined', ->
    equal @field.normalizeValue(null), null
    equal @field.normalizeValue(undefined), undefined

  test 'does nothing else when @showDate is true', ->
    @field.showDate = true
    equal @field.normalizeValue("0"), "0"

  test 'passes through non-hour string even when @showDate is false', ->
    @field.showDate = false
    equal @field.normalizeValue("123"), "123"
    equal @field.normalizeValue("12a"), "12a"
    equal @field.normalizeValue("b12"), "b12"

  test 'treats leading zero as 24-hour time', ->
    @field.showDate = false
    equal @field.normalizeValue("0"), "0:00"
    equal @field.normalizeValue("00"), "00:00"
    equal @field.normalizeValue("01"), "01:00"
    equal @field.normalizeValue("09"), "09:00"

  test 'treats 1 through 7 as 12-hour pm time', ->
    @field.showDate = false
    equal @field.normalizeValue("1"), "1pm"
    equal @field.normalizeValue("7"), "7pm"

  test 'treats 8 through 23 as 24-hour time', ->
    @field.showDate = false
    equal @field.normalizeValue("8"), "8:00"
    equal @field.normalizeValue("11"), "11:00"
    equal @field.normalizeValue("12"), "12:00"
    equal @field.normalizeValue("23"), "23:00"

  test 'passes through 24 and greater', ->
    @field.showDate = false
    equal @field.normalizeValue("24"), "24"
    equal @field.normalizeValue("25"), "25"
    equal @field.normalizeValue("99"), "99"

  QUnit.module 'setFormattedDatetime',
    setup: ->
      @snapshot = tz.snapshot()
      tz.changeZone(detroit, 'America/Detroit')
      @$field = $('<input type="text" name="due_at">')
      @field = new DatetimeField(@$field, {})

    teardown: ->
      tz.restore(@snapshot)

  test 'sets to blank with null value', ->
    @field.setFormattedDatetime(null, 'any')
    equal @field.datetime, null
    equal @field.fudged, null
    equal @field.blank, true
    equal @field.invalid, false
    equal @$field.val(), ''

  test 'treats value as unfudged', ->
    @field.setFormattedDatetime(moonwalk, 'date.formats.full')
    equal +@field.datetime, +moonwalk
    equal +@field.fudged, +$.fudgeDateForProfileTimezone(moonwalk)
    equal @field.blank, false
    equal @field.invalid, false
    equal @$field.val(), 'Jul 20, 1969 9:56pm'

  test 'formats value into val() according to format parameter', ->
    @field.setFormattedDatetime(moonwalk, 'date.formats.medium')
    equal @$field.val(), 'Jul 20, 1969'
    @field.setFormattedDatetime(moonwalk, 'time.formats.tiny')
    equal @$field.val(), '9:56pm'

  test 'localizes value', ->
    tz.changeLocale(portuguese, 'pt_PT', 'pt')
    I18nStubber.pushFrame()
    I18nStubber.setLocale 'pt_PT'
    I18nStubber.stub 'pt_PT', 'date.formats.full': "%-d %b %Y %-k:%M"
    @field.setFormattedDatetime(moonwalk, 'date.formats.full')
    equal @$field.val(), '20 Jul 1969 21:56'
    I18nStubber.popFrame()

  QUnit.module 'setDate/setTime/setDatetime',
    setup: ->
      @snapshot = tz.snapshot()
      tz.changeZone(detroit, 'America/Detroit')
      @$field = $('<input type="text" name="due_at">')
      @field = new DatetimeField(@$field, {})

    teardown: ->
      tz.restore(@snapshot)

  test 'setDate formats into val() with just date', ->
    @field.setDate(moonwalk)
    equal @$field.val(), 'Jul 20, 1969'

  test 'setTime formats into val() with just time', ->
    @field.setTime(moonwalk)
    equal @$field.val(), '9:56pm'

  test 'setDatetime formats into val() with full date and time', ->
    @field.setDatetime(moonwalk)
    equal @$field.val(), 'Jul 20, 1969 9:56pm'
