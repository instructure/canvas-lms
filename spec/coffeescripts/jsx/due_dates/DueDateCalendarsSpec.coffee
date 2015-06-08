define [
  'react'
  'underscore'
  'jsx/due_dates/DueDateCalendars'
  'helpers/fakeENV'
], (React, _, DueDateCalendars, fakeENV) ->

  Simulate = React.addons.TestUtils.Simulate
  SimulateNative = React.addons.TestUtils.SimulateNative

  module 'DueDateCalendars',
    setup: ->
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      @someDate = new Date(Date.UTC(2012, 1, 1, 7, 0, 0))
      props =
        replaceDate: ->
        rowKey: "nullnullnull"
        dates: {due_at: @someDate}
        overrides: [{get: (->), set:(->)}]
        sections: {}

      @dueDateCalendars = React.render(DueDateCalendars(props), $('<div>').appendTo('body')[0])

    teardown: ->
      fakeENV.teardown()
      React.unmountComponentAtNode(@dueDateCalendars.getDOMNode().parentNode)

  test 'renders', ->
    ok @dueDateCalendars.isMounted()

  test 'can get the date for a datetype', ->
    equal @dueDateCalendars.props.dates["due_at"], @someDate
