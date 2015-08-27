define [
  'react'
  'underscore'
  'jquery'
  'jsx/due_dates/DueDateCalendarPicker'
  'timezone'
  'vendor/timezone/fr_FR'
  'helpers/I18nStubber'
  'helpers/fakeENV'
], (React, _, $, DueDateCalendarPicker, tz, french, I18nStubber, fakeENV) ->

  Simulate = React.addons.TestUtils.Simulate
  SimulateNative = React.addons.TestUtils.SimulateNative

  module 'unlock_at DueDateCalendarPicker',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      @clock = sinon.useFakeTimers()
      props =
        handleUpdate: ->
        dateValue: new Date(Date.UTC(2012, 1, 1, 7, 0, 0))
        dateType: "unlock_at"
        rowKey: "nullnullnull"
        labelledBy: "foo"

      @dueDateCalendarPicker = React.render(DueDateCalendarPicker(props), $('<div>').appendTo('body')[0])

    teardown: ->
      fakeENV.teardown()
      React.unmountComponentAtNode(@dueDateCalendarPicker.getDOMNode().parentNode)
      @clock = sinon.restore()

  test 'renders', ->
    ok @dueDateCalendarPicker.isMounted()

  test 'formattedDate returns a nicely formatted Date', ->
    equal "Feb 1, 2012 at 7:00am", @dueDateCalendarPicker.formattedDate()

  test 'formattedDate returns a localized Date', ->
    snapshot = tz.snapshot()
    tz.changeLocale(french, 'fr_FR')
    I18nStubber.pushFrame()
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR',
      'date.formats.medium': "%-d %b %Y"
      'time.formats.tiny': "%-k:%M"
      'time.event': "%{date} à %{time}"
    equal "1 févr. 2012 à 7:00", @dueDateCalendarPicker.formattedDate()
    I18nStubber.popFrame()
    tz.restore(snapshot)

  test 'recieved proper class depending on dateType', ->
    classes = @dueDateCalendarPicker.refs.datePickerWrapper.props.className
    equal "DueDateRow__LockUnlockInput", classes

  test 'call the update prop when changed', ->
    dateInput = $(@dueDateCalendarPicker.getDOMNode()).find('.date_field').datetime_field()[0]
    update = @spy(@dueDateCalendarPicker.props, "handleUpdate")
    $(dateInput).val("tomorrow")
    $(dateInput).trigger("change")
    ok update.calledOnce

  test 'deals with empty inputs properly', ->
    dateInput = $(@dueDateCalendarPicker.getDOMNode()).find('.date_field').datetime_field()[0]
    update = @spy(@dueDateCalendarPicker.props, "handleUpdate")
    $(dateInput).val("")
    $(dateInput).trigger("change")
    ok update.calledWith(null)

  test 'does not convert to fancy midnight (because it is unlock_at)', ->
    d = new Date()
    d.setHours(0,0,0,0)
    ok !@dueDateCalendarPicker.fancyMidnightNeeded("tomorrow", d)

  module 'due_at DueDateCalendarPicker',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      @clock = sinon.useFakeTimers()
      props =
        handleUpdate: ->
        dateValue: new Date(Date.UTC(2012, 1, 1, 7, 0, 0))
        dateType: "due_at"
        rowKey: "nullnullnull"
        labelledBy: "foo"

      @dueDateCalendarPicker = React.render(DueDateCalendarPicker(props), $('<div>').appendTo('body')[0])

    teardown: ->
      fakeENV.teardown()
      React.unmountComponentAtNode(@dueDateCalendarPicker.getDOMNode().parentNode)
      @clock = sinon.restore()

  test 'recieved proper class depending on dateType', ->
    classes = @dueDateCalendarPicker.refs.datePickerWrapper.props.className
    equal "DueDateInput__Container", classes

  test 'converts to fancy midnight (because it is due_at)', ->
    d = new Date()
    d.setHours(0,0,0,0)
    ok @dueDateCalendarPicker.fancyMidnightNeeded("tomorrow", d)
    equal @dueDateCalendarPicker.changeToFancyMidnight(d, 0).getMinutes(), 59
