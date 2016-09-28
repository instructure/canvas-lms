define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'underscore'
  'jquery'
  'jsx/due_dates/DueDateCalendarPicker'
  'timezone'
  'vendor/timezone/fr_FR'
  'helpers/I18nStubber'
  'helpers/fakeENV'
], (
  React, ReactDOM, {Simulate, SimulateNative, findRenderedDOMComponentWithTag}, _, $, DueDateCalendarPicker, tz,
  french, I18nStubber, fakeENV
) ->

  module 'unlock_at DueDateCalendarPicker',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      @clock = sinon.useFakeTimers()
      @props =
        handleUpdate: ->
        dateValue: new Date(Date.UTC(2012, 1, 1, 7, 1, 0))
        dateType: "unlock_at"
        rowKey: "nullnullnull"
        labelledBy: "foo"
        inputClasses: "date_field datePickerDateField DueDateInput"
        disabled: false

      @mountPoint = $('<div>').appendTo('body')[0]
      DueDateCalendarPickerElement = React.createElement(DueDateCalendarPicker, @props)
      @dueDateCalendarPicker = ReactDOM.render(DueDateCalendarPickerElement, @mountPoint)

    teardown: ->
      fakeENV.teardown()
      ReactDOM.unmountComponentAtNode(@mountPoint)
      @clock.restore()

  test 'renders', ->
    ok @dueDateCalendarPicker.isMounted()

  test 'formattedDate returns a nicely formatted Date', ->
    equal "Feb 1, 2012 at 7:01am", @dueDateCalendarPicker.formattedDate()

  test 'formattedDate returns a localized Date', ->
    snapshot = tz.snapshot()
    tz.changeLocale(french, 'fr_FR', 'fr')
    I18nStubber.pushFrame()
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR',
      'date.formats.medium': "%-d %b %Y"
      'time.formats.tiny': "%-k:%M"
      'time.event': "%{date} à %{time}"
    equal "1 févr. 2012 à 7:01", @dueDateCalendarPicker.formattedDate()
    I18nStubber.popFrame()
    tz.restore(snapshot)

  test 'recieved proper class depending on dateType', ->
    classes = @dueDateCalendarPicker.refs.datePickerWrapper.className
    equal "DueDateRow__LockUnlockInput", classes

  test 'call the update prop when changed', ->
    update = @spy(@props, "handleUpdate")
    DueDateCalendarPickerElement = React.createElement(DueDateCalendarPicker, @props)
    @dueDateCalendarPicker = ReactDOM.render(DueDateCalendarPickerElement, @mountPoint)
    dateInput = $(ReactDOM.findDOMNode(@dueDateCalendarPicker)).find('.date_field').datetime_field()[0]
    $(dateInput).val("tomorrow")
    $(dateInput).trigger("change")
    ok update.calledOnce
    update.restore()

  test 'deals with empty inputs properly', ->
    update = @spy(@props, "handleUpdate")
    DueDateCalendarPickerElement = React.createElement(DueDateCalendarPicker, @props)
    @dueDateCalendarPicker = ReactDOM.render(DueDateCalendarPickerElement, @mountPoint)
    dateInput = $(ReactDOM.findDOMNode(@dueDateCalendarPicker)).find('.date_field').datetime_field()[0]
    $(dateInput).val("")
    $(dateInput).trigger("change")
    ok update.calledWith(null)
    update.restore()

  test 'does not convert to fancy midnight (because it is unlock_at)', ->
    # This date will be set to midnight in the time zone of the app.
    date = tz.parse('2015-08-31T00:00:00')
    equal @dueDateCalendarPicker.changeToFancyMidnightIfNeeded(date), date

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
        inputClasses: "date_field datePickerDateField DueDateInput"
        disabled: false

      DueDateCalendarPickerElement = React.createElement(DueDateCalendarPicker, props)
      @dueDateCalendarPicker = ReactDOM.render(DueDateCalendarPickerElement, $('<div>').appendTo('body')[0])

    teardown: ->
      fakeENV.teardown()
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@dueDateCalendarPicker).parentNode)
      @clock.restore()

  test 'recieved proper class depending on dateType', ->
    classes = @dueDateCalendarPicker.refs.datePickerWrapper.className
    equal "DueDateInput__Container", classes

  test 'converts to fancy midnight (because it is due_at)', ->
    # This date will be set to midnight in the time zone of the app.
    date = tz.parse('2015-08-31T00:00:00')
    date = @dueDateCalendarPicker.changeToFancyMidnightIfNeeded(date)

    equal date.getMinutes(), 59

  test 'converts to fancy midnight in the time zone of the user', ->
    # This date will be set to midnight in the time zone of the *user*.
    snapshot = tz.snapshot()
    tz.changeZone('America/Chicago')

    date = tz.parse('2015-08-31T00:00:00')
    date = @dueDateCalendarPicker.changeToFancyMidnightIfNeeded(date)

    equal date.getMinutes(), 59
    tz.restore(snapshot)

  module 'disabled DueDateCalendarPicker',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      @props =
        handleUpdate: ->
        dateValue: new Date(Date.UTC(2012, 1, 1, 7, 1, 0))
        dateType: "unlock_at"
        rowKey: "foobar"
        labelledBy: "foo"
        inputClasses: "date_field datePickerDateField DueDateInput"
        disabled: true

      @mountPoint = document.getElementById("fixtures")
      DueDateCalendarPickerElement = React.createElement(DueDateCalendarPicker, @props)
      @dueDateCalendarPicker = ReactDOM.render(DueDateCalendarPickerElement, @mountPoint)

    teardown: ->
      fakeENV.teardown()
      ReactDOM.unmountComponentAtNode(@mountPoint)

  test 'sets the input as readonly', ->
    input = findRenderedDOMComponentWithTag(@dueDateCalendarPicker, 'input')
    equal input.readOnly, true

  test 'disables the calendar picker button', ->
    button = findRenderedDOMComponentWithTag(@dueDateCalendarPicker, 'button')
    ok button.getAttribute("aria-disabled"), true
