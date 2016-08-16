define [
  'react'
  'react-dom'
  'jquery'
  'underscore'
  'jsx/grading/gradingPeriod'
  'helpers/fakeENV'
  'jsx/shared/helpers/dateHelper'
  'jquery.instructure_misc_plugins'
  'compiled/jquery.rails_flash_notifications'
], (React, ReactDOM, $, _, GradingPeriod, fakeENV, DateHelper) ->

  TestUtils = React.addons.TestUtils
  wrapper = document.getElementById('fixtures')

  module 'GradingPeriod',
    setup: ->
      @stub($, 'flashMessage', -> )
      @stub($, 'flashError', -> )
      @server = sinon.fakeServer.create()
      fakeENV.setup()
      ENV.GRADING_PERIODS_URL = "api/v1/courses/1/grading_periods"

      @updatedPeriodData = "grading_periods":[
        {
          "id":"1",
          "title":"Updated Grading Period!",
          "startDate":"2015-03-01T06:00:00Z",
          "endDate":"2015-05-31T05:00:00Z",
          "closeDate":"2015-06-07T05:00:00Z",
          "weight":null,
          "permissions": { "update":true, "delete":true }
        }
      ]
      @server.respondWith "PUT", ENV.GRADING_PERIODS_URL + "/1", [200, {"Content-Type":"application/json"}, JSON.stringify @updatedPeriodData]
      @server.respond()

    renderComponent: (opts = {}) ->
      exampleProps =
        id: "1"
        title: "Spring"
        startDate: new Date("2015-03-01T00:00:00Z")
        endDate: new Date("2015-05-31T00:00:00Z")
        closeDate: new Date("2015-06-07T00:00:00Z")
        weight: null
        disabled: false
        readOnly: false
        permissions: { read: true, update: true, create: true, delete: true }
        onDeleteGradingPeriod: ->
        updateGradingPeriodCollection: sinon.spy()

      props = _.defaults(opts, exampleProps)
      GradingPeriodElement = React.createElement(GradingPeriod, props)
      ReactDOM.render(GradingPeriodElement, wrapper)

    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)
      ENV.GRADING_PERIODS_URL = null
      @server.restore()

  test 'sets initial state properly', ->
    gradingPeriod = @renderComponent()
    equal gradingPeriod.state.title, "Spring"
    deepEqual gradingPeriod.state.startDate, new Date("2015-03-01T00:00:00Z")
    deepEqual gradingPeriod.state.endDate, new Date("2015-05-31T00:00:00Z")
    equal gradingPeriod.state.weight, null

  test 'onDateChange calls replaceInputWithDate', ->
    gradingPeriod = @renderComponent()
    replaceInputWithDate = @stub(gradingPeriod, 'replaceInputWithDate')
    gradingPeriod.onDateChange("startDate", "period_start_date_1")
    ok replaceInputWithDate.calledOnce

  test 'onDateChange calls updateGradingPeriodCollection', ->
    gradingPeriod = @renderComponent()
    gradingPeriod.onDateChange("startDate", "period_start_date_1")
    ok gradingPeriod.props.updateGradingPeriodCollection.calledOnce

  test 'onTitleChange changes the title state', ->
    gradingPeriod = @renderComponent()
    fakeEvent = { target: { name: "title", value: "MXP: Most Xtreme Primate" } }
    gradingPeriod.onTitleChange(fakeEvent)
    equal gradingPeriod.state.title, "MXP: Most Xtreme Primate"

  test 'onTitleChange calls updateGradingPeriodCollection', ->
    gradingPeriod = @renderComponent()
    fakeEvent = { target: { name: "title", value: "MXP: Most Xtreme Primate" } }
    gradingPeriod.onTitleChange(fakeEvent)
    ok gradingPeriod.props.updateGradingPeriodCollection.calledOnce

  test 'replaceInputWithDate calls formatDatetimeForDisplay', ->
    gradingPeriod = @renderComponent()
    formatDatetime = @stub(DateHelper, 'formatDatetimeForDisplay')
    fakeDateElement = { val: -> }
    gradingPeriod.replaceInputWithDate("startDate", fakeDateElement)
    ok formatDatetime.calledOnce

  test "assigns the 'readOnly' property on the template when false", ->
    gradingPeriod = @renderComponent()
    equal gradingPeriod.refs.template.props.readOnly, false

  test "assigns the 'readOnly' property on the template when true", ->
    gradingPeriod = @renderComponent(readOnly: true)
    equal gradingPeriod.refs.template.props.readOnly, true

  test "assigns the 'closeDate' property", ->
    gradingPeriod = @renderComponent()
    deepEqual gradingPeriod.refs.template.props.closeDate, new Date("2015-06-07T00:00:00Z")

  test "assigns 'endDate' as 'closeDate' when 'closeDate' is not defined", ->
    gradingPeriod = @renderComponent(closeDate: null)
    deepEqual gradingPeriod.refs.template.props.closeDate, new Date("2015-05-31T00:00:00Z")
