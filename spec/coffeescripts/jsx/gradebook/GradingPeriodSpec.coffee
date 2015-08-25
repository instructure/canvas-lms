define [
  'react'
  'jquery'
  'underscore'
  'jsx/grading/gradingPeriod'
  'jquery.instructure_misc_plugins'
  'compiled/jquery.rails_flash_notifications'
], (React, $, _, GradingPeriod) ->

  TestUtils = React.addons.TestUtils

  module 'GradingPeriod',
    setup: ->
      @stub($, 'flashMessage', -> )
      @stub($, 'flashError', -> )
      @server = sinon.fakeServer.create()
      ENV.GRADING_PERIODS_URL = "api/v1/courses/1/grading_periods"

      @createdPeriodData = "grading_periods":[
        {
          "id":"3", "start_date":"2015-04-20T05:00:00Z", "end_date":"2015-04-21T05:00:00Z",
          "weight":null, "title":"New Period!", "permissions": { "read":true, "manage":true }
        }
      ]
      @updatedPeriodData = "grading_periods":[
        {
          "id":"1", "startDate":"2015-03-01T06:00:00Z", "endDate":"2015-05-31T05:00:00Z",
          "weight":null, "title":"Updated Grading Period!", "permissions": { "read":true, "manage":true }
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
        permissions:
          read: true
          manage: true
        cannotDelete: -> false
        onDeleteGradingPeriod: ->
        updateGradingPeriodCollection: ->
        isOverlapping: ->
      @gradingPeriod = TestUtils.renderIntoDocument(GradingPeriod(@props))
      @server.respond()
    teardown: ->
      React.unmountComponentAtNode(@gradingPeriod.getDOMNode().parentNode)
      ENV.GRADING_PERIODS_URL = null
      @server.restore()

  test 'sets initial state properly', ->
    deepEqual @gradingPeriod.state.id, @props.id
    deepEqual @gradingPeriod.state.title, @props.title
    deepEqual @gradingPeriod.state.startDate, @props.startDate
    deepEqual @gradingPeriod.state.endDate, @props.endDate
    deepEqual @gradingPeriod.state.weight, @props.weight
    deepEqual @gradingPeriod.state.permissions, @props.permissions
    ok @gradingPeriod.state.shouldUpdateBeDisabled

  test 'handleDateChange changes the state of the respective date passed in', ->
    startDateInput = @gradingPeriod.refs.startDate.getDOMNode()
    newDate = new Date("Feb 20, 2015 2:55 am")
    startDateInput.value = $.datetimeString(newDate, format: "medium")
    fakeEvent = { target: { name: "startDate", value: "Feb 20, 2015 2:55 am" } }
    $(startDateInput).blur()
    @gradingPeriod.handleDateChange(fakeEvent)
    deepEqual @gradingPeriod.state.startDate.toUTCString(), new Date("Feb 20, 2015 2:55 am").toUTCString()

  test 'handleDateChange calls replaceInputWithDate', ->
    fakeEvent = { target: { name: "startDate", value: "Feb 20, 2015 2:55 am" } }
    replaceInputWithDate = @stub(@gradingPeriod, 'replaceInputWithDate')
    @gradingPeriod.handleDateChange(fakeEvent)
    ok replaceInputWithDate.calledOnce

  test 'handleDateChange calls updateGradingPeriodCollection', ->
    fakeEvent = { target: { name: "startDate", value: "Feb 20, 2015 2:55 am" } }
    update = @stub(@gradingPeriod.props, 'updateGradingPeriodCollection')
    @gradingPeriod.handleDateChange(fakeEvent)
    ok update.calledOnce

  test 'isNewGradingPeriod returns false if the id does not contain "new"', ->
    ok !@gradingPeriod.isNewGradingPeriod()

  test 'isNewGradingPeriod returns true if the id contains "new"', ->
    @gradingPeriod.setState({id: "new1"})
    ok @gradingPeriod.isNewGradingPeriod()

  test 'handleTitleChange changes the title state', ->
    fakeEvent = { target: { name: "title", value: "MXP: Most Xtreme Primate" } }
    @gradingPeriod.handleTitleChange(fakeEvent)
    deepEqual @gradingPeriod.state.title, "MXP: Most Xtreme Primate"

  test 'handleTitleChange calls updateGradingPeriodCollection', ->
    fakeEvent = { target: { name: "title", value: "MXP: Most Xtreme Primate" } }
    update = @stub(@gradingPeriod.props, 'updateGradingPeriodCollection')
    @gradingPeriod.handleTitleChange(fakeEvent)
    ok update.calledOnce

  test 'replaceInputWithDate calls formatDateForDisplay', ->
    formatDate = @stub(@gradingPeriod, 'formatDateForDisplay')
    @gradingPeriod.replaceInputWithDate(@gradingPeriod.refs.startDate)
    ok formatDate.calledOnce

  test 'triggerDeleteGradingPeriod calls onDeleteGradingPeriod', ->
    deletePeriod = @stub(@gradingPeriod.props, 'onDeleteGradingPeriod')
    @gradingPeriod.triggerDeleteGradingPeriod()
    ok deletePeriod.calledOnce
