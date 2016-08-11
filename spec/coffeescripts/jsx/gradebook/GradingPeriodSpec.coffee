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

  module 'GradingPeriod',
    setup: ->
      @stub($, 'flashMessage', -> )
      @stub($, 'flashError', -> )
      @server = sinon.fakeServer.create()
      fakeENV.setup()
      ENV.GRADING_PERIODS_URL = "api/v1/courses/1/grading_periods"

      @createdPeriodData = "grading_periods":[
        {
          "id":"3", "start_date":"2015-04-20T05:00:00Z", "end_date":"2015-04-21T05:00:00Z",
          "weight":null, "title":"New Period!", "permissions": { "update":true, "delete":true }
        }
      ]
      @updatedPeriodData = "grading_periods":[
        {
          "id":"1", "startDate":"2015-03-01T06:00:00Z", "endDate":"2015-05-31T05:00:00Z",
          "weight":null, "title":"Updated Grading Period!", "permissions": { "update":true, "delete":true }
        }
      ]
      @server.respondWith "POST", ENV.GRADING_PERIODS_URL, [200, {"Content-Type":"application/json"}, JSON.stringify @createdPeriodData]
      @server.respondWith "PUT", ENV.GRADING_PERIODS_URL + "/1", [200, {"Content-Type":"application/json"}, JSON.stringify @updatedPeriodData]
      @props =
        id: "1"
        title: "Spring"
        startDate: new Date("2015-03-01T00:00:00Z")
        endDate: new Date("2015-05-31T00:00:00Z")
        weight: null
        disabled: false
        readOnly: false
        permissions: { read: true, update: true, create: true, delete: true }
        onDeleteGradingPeriod: ->
        updateGradingPeriodCollection: sinon.spy()

      @server.respond()
    renderComponent: ->
      GradingPeriodElement = React.createElement(GradingPeriod, @props)
      @gradingPeriod = TestUtils.renderIntoDocument(GradingPeriodElement)
    teardown: ->
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(@gradingPeriod).parentNode)
      ENV.GRADING_PERIODS_URL = null
      @server.restore()

  test 'sets initial state properly', ->
    @renderComponent()
    equal @gradingPeriod.state.title, @props.title
    equal @gradingPeriod.state.startDate, @props.startDate
    equal @gradingPeriod.state.endDate, @props.endDate
    equal @gradingPeriod.state.weight, @props.weight

  test 'onDateChange calls replaceInputWithDate', ->
    @renderComponent()
    replaceInputWithDate = @stub(@gradingPeriod, 'replaceInputWithDate')
    @gradingPeriod.onDateChange("startDate", "period_start_date_1")
    ok replaceInputWithDate.calledOnce

  test 'onDateChange calls updateGradingPeriodCollection', ->
    @renderComponent()
    @gradingPeriod.onDateChange("startDate", "period_start_date_1")
    ok @gradingPeriod.props.updateGradingPeriodCollection.calledOnce

  test 'onTitleChange changes the title state', ->
    @renderComponent()
    fakeEvent = { target: { name: "title", value: "MXP: Most Xtreme Primate" } }
    @gradingPeriod.onTitleChange(fakeEvent)
    deepEqual @gradingPeriod.state.title, "MXP: Most Xtreme Primate"

  test 'onTitleChange calls updateGradingPeriodCollection', ->
    @renderComponent()
    fakeEvent = { target: { name: "title", value: "MXP: Most Xtreme Primate" } }
    @gradingPeriod.onTitleChange(fakeEvent)
    ok @gradingPeriod.props.updateGradingPeriodCollection.calledOnce

  test 'replaceInputWithDate calls formatDatetimeForDisplay', ->
    @renderComponent()
    formatDatetime = @stub(DateHelper, 'formatDatetimeForDisplay')
    fakeDateElement = { val: -> }
    @gradingPeriod.replaceInputWithDate("startDate", fakeDateElement)
    ok formatDatetime.calledOnce

  test "assigns the 'readOnly' property on the template when false", ->
    @renderComponent()
    equal @gradingPeriod.refs.template.props.readOnly, false

  test "assigns the 'readOnly' property on the template when true", ->
    @props.readOnly = true
    @renderComponent()
    equal @gradingPeriod.refs.template.props.readOnly, true
