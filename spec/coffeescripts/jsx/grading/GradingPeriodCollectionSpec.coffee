define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jquery'
  'underscore'
  'jsx/grading/gradingPeriodCollection'
  'helpers/fakeENV'
  'jquery.instructure_misc_plugins'
  'compiled/jquery.rails_flash_notifications'
], (React, ReactDOM, TestUtils, $, _, GradingPeriodCollection, fakeENV) ->

  QUnit.module 'GradingPeriodCollection',
    setup: ->
      @stub($, 'flashMessage')
      @stub($, 'flashError')
      @stub(window, 'confirm').returns(true)
      @server = sinon.fakeServer.create()
      fakeENV.setup()
      ENV.current_user_roles = ["admin"]
      ENV.GRADING_PERIODS_URL = "/api/v1/accounts/1/grading_periods"
      ENV.GRADING_PERIODS_WEIGHTED = true
      @indexData =
        "grading_periods":[
          {
            "id":"1",
            "title":"Spring",
            "start_date":"2015-03-01T06:00:00Z",
            "end_date":"2015-05-31T05:00:00Z",
            "close_date":"2015-06-07T05:00:00Z",
            "weight":null,
            "permissions": { "update":true, "delete":true }
          },
          {
            "id":"2",
            "title":"Summer",
            "start_date":"2015-06-01T05:00:00Z",
            "end_date":"2015-08-31T05:00:00Z",
            "close_date":"2015-09-07T05:00:00Z",
            "weight":null,
            "permissions": { "update":true, "delete":true }
          }
        ]
        "grading_periods_read_only": false,
        "can_create_grading_periods": true

      @formattedIndexData =
        "grading_periods":[
          {
            "id":"1",
            "title":"Spring",
            "startDate": new Date("2015-03-01T06:00:00Z"),
            "endDate": new Date("2015-05-31T05:00:00Z"),
            "closeDate": new Date("2015-06-07T05:00:00Z"),
            "weight":null,
            "permissions": { "update":true, "delete":true }
          },
          {
            "id":"2",
            "title":"Summer",
            "startDate": new Date("2015-06-01T05:00:00Z"),
            "endDate": new Date("2015-08-31T05:00:00Z"),
            "closeDate": new Date("2015-09-07T05:00:00Z"),
            "weight":null,
            "permissions": { "update":true, "delete":true }
          }
        ]
        "grading_periods_read_only": false,
        "can_create_grading_periods": true

      @createdPeriodData = "grading_periods":[
        {
          "id":"3",
          "title":"New Period!",
          "start_date":"2015-04-20T05:00:00Z",
          "end_date":"2015-04-21T05:00:00Z",
          "close_date":"2015-04-28T05:00:00Z",
          "weight":null,
          "permissions": { "update":true, "delete":true }
        }
      ]
      @server.respondWith "GET", ENV.GRADING_PERIODS_URL, [200, {"Content-Type":"application/json"}, JSON.stringify @indexData]
      @server.respondWith "POST", ENV.GRADING_PERIODS_URL, [200, {"Content-Type":"application/json"}, JSON.stringify @createdPeriodData]
      @server.respondWith "DELETE", ENV.GRADING_PERIODS_URL + "/1", [204, {}, ""]

      GradingPeriodCollectionElement = React.createElement(GradingPeriodCollection)
      @gradingPeriodCollection = TestUtils.renderIntoDocument(GradingPeriodCollectionElement)
      @server.respond()
    teardown: ->
      ReactDOM.unmountComponentAtNode(@gradingPeriodCollection.getDOMNode().parentNode)
      fakeENV.teardown()
      @server.restore()

  test 'gets the grading periods from the grading periods controller', ->
    deepEqual @gradingPeriodCollection.state.periods, @formattedIndexData.grading_periods

  test 'getPeriods requests the index data from the server', ->
    @spy($, "ajax")
    @gradingPeriodCollection.getPeriods()
    ok $.ajax.calledOnce

  test "renders grading periods with 'readOnly' set to the returned value (false)", ->
    equal @gradingPeriodCollection.refs.grading_period_1.props.readOnly, false
    equal @gradingPeriodCollection.refs.grading_period_2.props.readOnly, false

  test "renders grading periods with 'weighted' set to the ENV variable (true)", ->
    equal @gradingPeriodCollection.refs.grading_period_1.props.weighted, true
    equal @gradingPeriodCollection.refs.grading_period_2.props.weighted, true

  test "renders grading periods with their individual 'closeDate'", ->
    deepEqual @gradingPeriodCollection.refs.grading_period_1.props.closeDate, new Date("2015-06-07T05:00:00Z")
    deepEqual @gradingPeriodCollection.refs.grading_period_2.props.closeDate, new Date("2015-09-07T05:00:00Z")

  test 'deleteGradingPeriod calls confirmDelete if the period being deleted is not new (it is saved server side)', ->
    confirmDelete = @stub($.fn, 'confirmDelete')
    @gradingPeriodCollection.deleteGradingPeriod('1')
    ok confirmDelete.calledOnce

  test 'updateGradingPeriodCollection correctly updates the periods state', ->
    updatedPeriodComponent = {}
    updatedPeriodComponent.state= {
      "id":"1", "startDate": new Date("2069-03-01T06:00:00Z"), "endDate": new Date("2070-05-31T05:00:00Z"),
      "weight":null, "title":"Updating an existing period!"
    }
    updatedPeriodComponent.props = {permissions: {read: true, update: true, delete: true}}
    @gradingPeriodCollection.updateGradingPeriodCollection(updatedPeriodComponent)
    updatedPeriod = _.find(@gradingPeriodCollection.state.periods, (p) => p.id == "1")
    deepEqual updatedPeriod.title, updatedPeriodComponent.state.title

  test 'getPeriodById returns the period with the matching id (if one exists)', ->
    period = @gradingPeriodCollection.getPeriodById('1')
    deepEqual period.id, '1'

  test "given two grading periods that don't overlap, areNoDatesOverlapping returns true", ->
    ok @gradingPeriodCollection.areNoDatesOverlapping(@gradingPeriodCollection.state.periods[0])

  test 'given two overlapping grading periods, areNoDatesOverlapping returns false', ->
    startDate = new Date("2015-03-01T06:00:00Z")
    endDate = new Date("2015-05-31T05:00:00Z")
    formattedIndexData = [
      {
        "id":"1", "startDate": startDate, "endDate": endDate,
        "weight":null, "title":"Spring", "permissions": { "read":false, "update":false, "delete":false }
      },
      {
        "id":"2", "startDate": startDate, "endDate": endDate,
        "weight":null, "title":"Summer", "permissions": { "read":false, "update":false, "delete":false }
      }
    ]
    @gradingPeriodCollection.setState({periods: formattedIndexData})
    ok !@gradingPeriodCollection.areNoDatesOverlapping(@gradingPeriodCollection.state.periods[0])

  test 'serializeDataForSubmission serializes periods by snake casing keys', ->
    firstPeriod  = @gradingPeriodCollection.state.periods[0]
    secondPeriod = @gradingPeriodCollection.state.periods[1]
    expectedOutput =
      grading_periods: [{
        id: firstPeriod.id,
        title: firstPeriod.title,
        start_date: firstPeriod.startDate,
        end_date: firstPeriod.endDate
      }, {
        id: secondPeriod.id,
        title: secondPeriod.title,
        start_date: secondPeriod.startDate,
        end_date: secondPeriod.endDate
      }]
    deepEqual @gradingPeriodCollection.serializeDataForSubmission(), expectedOutput

  test 'batchUpdatePeriods makes an AJAX call if validations pass', ->
    @sandbox.stub(@gradingPeriodCollection, 'areGradingPeriodsValid').returns(true)
    ajax = @sandbox.spy($, 'ajax')
    @gradingPeriodCollection.batchUpdatePeriods()
    ok ajax.calledOnce

  test 'batchUpdatePeriods does not make an AJAX call if validations fail', ->
    @sandbox.stub(@gradingPeriodCollection, 'areGradingPeriodsValid').returns(false)
    ajax = @sandbox.spy($, 'ajax')
    @gradingPeriodCollection.batchUpdatePeriods()
    ok ajax.notCalled

  test 'isTitleCompleted checks for a title being present', ->
    period = {title: 'Spring'}
    ok @gradingPeriodCollection.isTitleCompleted(period)

  test 'isTitleCompleted fails blank titles', ->
    period = {title: ' '}
    ok !@gradingPeriodCollection.isTitleCompleted(period)

  test 'isStartDateBeforeEndDate passes', ->
    period = { startDate: new Date("2015-03-01T06:00:00Z"), endDate: new Date("2015-05-31T05:00:00Z") }
    ok @gradingPeriodCollection.isStartDateBeforeEndDate(period)

  test 'isStartDateBeforeEndDate fails', ->
    period = { startDate: new Date("2015-05-31T05:00:00Z"), endDate: new Date("2015-03-01T06:00:00Z") }
    ok !@gradingPeriodCollection.isStartDateBeforeEndDate(period)

  test 'areDatesValid passes', ->
    period = { startDate: new Date("2015-03-01T06:00:00Z"), endDate: new Date("2015-05-31T05:00:00Z") }
    ok @gradingPeriodCollection.areDatesValid(period)

  test 'areDatesValid fails', ->
    period = { startDate: new Date("foo"), endDate: new Date("foo") }
    ok !@gradingPeriodCollection.areDatesValid(period)
    period = { startDate: new Date("foo"), endDate: new Date("2015-05-31T05:00:00Z") }
    ok !@gradingPeriodCollection.areDatesValid(period)
    period = { startDate: ("2015-03-01T06:00:00Z"), endDate: new Date("foo") }
    ok !@gradingPeriodCollection.areDatesValid(period)

  test 'areNoDatesOverlapping periods are not overlapping when endDate of earlier period is the same as start date for the latter', ->
    periodOne = {
      'id': '1', startDate: new Date("2029-03-01T06:00:00Z"), endDate: new Date("2030-05-31T05:00:00Z"),
      weight: null, title: "Spring", permissions: { read:true, update: true, delete: true }
    }
    periodTwo = {
      'id': 'new2', startDate: new Date("2030-05-31T05:00:00Z"), endDate: new Date("2031-05-31T05:00:00Z"),
      weight: null, title: "Spring", permissions: { read:true, update: true, delete: true }
    }
    @gradingPeriodCollection.setState({periods: [periodOne, periodTwo]})
    ok @gradingPeriodCollection.areNoDatesOverlapping(periodTwo)

  test 'areNoDatesOverlapping periods are overlapping when a period falls within another', ->
    periodOne = {
      'id': '1', startDate: new Date("2029-01-01T00:00:00Z"), endDate: new Date("2030-01-01T00:00:00Z"),
      weight: null, title: "Spring", permissions: { read:true, update: true, delete: true }
    }
    periodTwo = {
      'id': 'new2', startDate: new Date("2029-01-01T00:00:00Z"), endDate: new Date("2030-01-01T00:00:00Z"),
      weight: null, title: "Spring", permissions: { read:true, update: true, delete: true }
    }
    @gradingPeriodCollection.setState({periods: [periodOne, periodTwo]})
    ok !@gradingPeriodCollection.areNoDatesOverlapping(periodTwo)

  test 'areDatesOverlapping adding two periods at the same time that overlap returns true', ->
    existingPeriod = @gradingPeriodCollection.state.periods[0]
    periodOne = {
      id: 'new1', startDate: new Date("2029-01-01T00:00:00Z"), endDate: new Date("2030-01-01T00:00:00Z"), title: "Spring", permissions: {update: true, delete: true}
    }
    periodTwo = {
      id: 'new2', startDate: new Date("2029-01-01T00:00:00Z"), endDate: new Date("2030-01-01T00:00:00Z"), title: "Spring", permissions: {update: true, delete: true}
    }
    @gradingPeriodCollection.setState({periods: [existingPeriod, periodOne, periodTwo]})
    ok !@gradingPeriodCollection.areDatesOverlapping(existingPeriod)
    ok @gradingPeriodCollection.areDatesOverlapping(periodOne)
    ok @gradingPeriodCollection.areDatesOverlapping(periodTwo)

  test 'renderSaveButton does not render a button if the user cannot update any of the periods on the page', ->
    uneditable = [{
      "id":"12", "startDate": new Date("2015-03-01T06:00:00Z"), "endDate": new Date("2015-05-31T05:00:00Z"),
      "weight":null, "title":"Spring", "permissions": { "read":true, "update":false, "delete":false }
    }]
    @gradingPeriodCollection.setState({ periods: uneditable })
    notOk @gradingPeriodCollection.renderSaveButton()

    _.extend(uneditable, {"permissions": {"update": true, delete: false}})
    @gradingPeriodCollection.setState({ periods: uneditable})
    notOk @gradingPeriodCollection.renderSaveButton()

    _.extend(uneditable, {"permissions": {"delete": false, delete: true}})
    @gradingPeriodCollection.setState({ periods: uneditable})
    notOk @gradingPeriodCollection.renderSaveButton()

  test 'renderSaveButton renders a button if the user is not at the course grading periods page', ->
    ok @gradingPeriodCollection.renderSaveButton()

  QUnit.module 'GradingPeriodCollection with read-only grading periods',
    setup: ->
      @server = sinon.fakeServer.create()
      fakeENV.setup()
      ENV.current_user_roles = ["admin"]
      ENV.GRADING_PERIODS_URL = "/api/v1/accounts/1/grading_periods"
      ENV.GRADING_PERIODS_WEIGHTED = false
      @indexData =
        "grading_periods":[
          {
            "id":"1", "start_date":"2015-03-01T06:00:00Z", "end_date":"2015-05-31T05:00:00Z",
            "weight":null, "title":"Spring", "permissions": { "update":true, "delete":true }
          }
        ]
        "grading_periods_read_only": true,
        "can_create_grading_periods": true

      @server.respondWith "GET", ENV.GRADING_PERIODS_URL, [200, {"Content-Type":"application/json"}, JSON.stringify @indexData]
      GradingPeriodCollectionElement = React.createElement(GradingPeriodCollection)
      @gradingPeriodCollection = TestUtils.renderIntoDocument(GradingPeriodCollectionElement)
      @server.respond()

    teardown: ->
      ReactDOM.unmountComponentAtNode(@gradingPeriodCollection.getDOMNode().parentNode)
      fakeENV.teardown()
      @server.restore()

  test "renders grading periods with 'readOnly' set to true", ->
    equal @gradingPeriodCollection.refs.grading_period_1.props.readOnly, true

  test "renders grading periods with 'weighted' set to the ENV variable (false)", ->
    equal @gradingPeriodCollection.refs.grading_period_1.props.weighted, false
