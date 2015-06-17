define [
  'react'
  'jquery'
  'underscore'
  'jsx/grading/gradingPeriodCollection'
  'jquery.instructure_misc_plugins'
], (React, $, _, GradingPeriodCollection) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate

  module 'GradingPeriodCollection with read and manage permission for all periods',
    setup: ->
      @stub($, 'flashMessage', ->)
      @stub($, 'flashError', ->)
      @stub(window, 'confirm', -> true)
      @server = sinon.fakeServer.create()
      ENV.current_user_roles = ["teacher"]
      ENV.GRADING_PERIODS_URL = "/api/v1/courses/1/grading_periods"
      @indexData = "grading_periods":[
        {
          "id":"1", "start_date":"2015-03-01T06:00:00Z", "end_date":"2015-05-31T05:00:00Z",
          "weight":null, "title":"Spring", "permissions": { "read":true, "manage":true }
        },
        {
          "id":"2", "start_date":"2015-06-01T05:00:00Z", "end_date":"2015-08-31T05:00:00Z",
          "weight":null, "title":"Summer", "permissions": { "read":true, "manage":true }
        }
      ]
      @formattedIndexData = "grading_periods":[
        {
          "id":"1", "startDate": new Date("2015-03-01T06:00:00Z"), "endDate": new Date("2015-05-31T05:00:00Z"),
          "weight":null, "title":"Spring", "permissions": { "read":true, "manage":true }
        },
        {
          "id":"2", "startDate": new Date("2015-06-01T05:00:00Z"), "endDate": new Date("2015-08-31T05:00:00Z"),
          "weight":null, "title":"Summer", "permissions": { "read":true, "manage":true }
        }
      ]
      @createdPeriodData = "grading_periods":[
        {
          "id":"3", "start_date":"2015-04-20T05:00:00Z", "end_date":"2015-04-21T05:00:00Z",
          "weight":null, "title":"New Period!", "permissions": { "read":true, "manage":true }
        }
      ]
      @server.respondWith "GET", ENV.GRADING_PERIODS_URL, [200, {"Content-Type":"application/json"}, JSON.stringify @indexData]
      @server.respondWith "POST", ENV.GRADING_PERIODS_URL, [200, {"Content-Type":"application/json"}, JSON.stringify @createdPeriodData]
      @server.respondWith "DELETE", ENV.GRADING_PERIODS_URL + "/1", [204, {}, ""]
      @gradingPeriodCollection = TestUtils.renderIntoDocument(GradingPeriodCollection())
      @server.respond()
    teardown: ->
      React.unmountComponentAtNode(@gradingPeriodCollection.getDOMNode().parentNode)
      ENV.current_user_roles = null
      ENV.GRADING_PERIODS_URL = null
      @server.restore()

  test 'gets the grading periods from the grading periods controller', ->
    deepEqual @gradingPeriodCollection.state.periods, @formattedIndexData.grading_periods

  test 'canManageAtLeastOnePeriod returns true', ->
    periods = @gradingPeriodCollection.state.periods
    ok @gradingPeriodCollection.canManageAtLeastOnePeriod(periods)

  test 'cannotDeleteLastPeriod returns false if there is one period left and manage permission is true', ->
    onePeriod = [
      {
        "id":"1", "startDate": new Date("2029-03-01T06:00:00Z"), "endDate": new Date("2030-05-31T05:00:00Z"),
        "weight":null, "title":"A Lonely Grading Period with manage permission",
        "permissions": { "read":true, "manage":true }
      }
    ]
    @gradingPeriodCollection.setState({periods: onePeriod})
    ok !@gradingPeriodCollection.cannotDeleteLastPeriod()

  test 'getPeriods requests the index data from the server', ->
    @spy($, "ajax")
    @gradingPeriodCollection.getPeriods()
    ok $.ajax.calledOnce

  test 'getPeriods calls gotPeriods once the data is received', ->
    @stub(@gradingPeriodCollection, 'gotPeriods')
    @gradingPeriodCollection.getPeriods()
    @server.respond()
    ok @gradingPeriodCollection.gotPeriods.calledOnce

  test 'gotPeriods sets disabled state to false', ->
    @gradingPeriodCollection.setState({disabled: true})
    ok @gradingPeriodCollection.state.disabled
    @gradingPeriodCollection.gotPeriods(@formattedIndexData.grading_periods)
    ok !@gradingPeriodCollection.state.disabled

  test 'gotPeriods concatenates the index returned from the ajax call with any new, unsaved grading periods, and sets the result to the periods state', ->
    unsavedPeriods = [
      {
        "id":"new1", "startDate": new Date("2029-03-01T06:00:00Z"), "endDate": new Date("2030-05-31T05:00:00Z"),
        "weight":null, "title":"New Period. I'm not saved yet!",
        "permissions": { "read":true, "manage":true }
      },
      {
        "id":"new2", "startDate": new Date("2039-03-01T06:00:00Z"), "endDate": new Date("2042-05-31T05:00:00Z"),
        "weight":null, "title":"Another New Period. Also not saved yet!",
        "permissions": { "read":true, "manage":true }
      }
    ]
    @gradingPeriodCollection.setState({periods: unsavedPeriods})
    @gradingPeriodCollection.gotPeriods(@formattedIndexData.grading_periods)
    newPeriods = @formattedIndexData.grading_periods.concat(unsavedPeriods)
    deepEqual @gradingPeriodCollection.state.periods, newPeriods

  test 'gotPeriods excludes the grading period with the id matching idToExclude when setting state', ->
    idToExclude = 'new2'
    unsavedPeriods = [
      {
        "id":"new1", "startDate": new Date("2029-03-01T06:00:00Z"), "endDate": new Date("2030-05-31T05:00:00Z"),
        "weight":null, "title":"New Period. I'm not saved yet!",
        "permissions": { "read":true, "manage":true }
      },
      {
        "id":"new2", "startDate": new Date("2039-03-01T06:00:00Z"), "endDate": new Date("2042-05-31T05:00:00Z"),
        "weight":null, "title":"Another New Period. Also not saved yet! I won't be in the new state.",
        "permissions": { "read":true, "manage":true }
      }
    ]
    @gradingPeriodCollection.setState({periods: unsavedPeriods})
    @gradingPeriodCollection.gotPeriods(@formattedIndexData.grading_periods, idToExclude)
    newPeriods = @formattedIndexData.grading_periods.concat(unsavedPeriods[0])
    deepEqual @gradingPeriodCollection.state.periods, newPeriods

  test 'lastRemainingPeriod returns false if there is more than one period left', ->
    ok !@gradingPeriodCollection.lastRemainingPeriod()

  test 'lastRemainingPeriod returns true if there is one period left', ->
    onePeriod = [
      {
        "id":"1", "startDate": new Date("2029-03-01T06:00:00Z"), "endDate": new Date("2030-05-31T05:00:00Z"),
        "weight":null, "title":"A Lonely Grading Period",
        "permissions": { "read":true, "manage":true }
      }
    ]
    @gradingPeriodCollection.setState({periods: onePeriod})
    ok @gradingPeriodCollection.lastRemainingPeriod()

  test 'createNewGradingPeriod adds a new period', ->
    deepEqual @gradingPeriodCollection.state.periods.length, 2
    @gradingPeriodCollection.createNewGradingPeriod()
    deepEqual @gradingPeriodCollection.state.periods.length, 3

  test 'createNewGradingPeriod adds the new period with a blank title, start date, and end date', ->
    @gradingPeriodCollection.createNewGradingPeriod()
    newPeriod = _.find(@gradingPeriodCollection.state.periods, (p) => p.id.indexOf('new') > -1)
    deepEqual newPeriod.title, ''
    deepEqual newPeriod.startDate.getTime(), new Date('').getTime()
    deepEqual newPeriod.endDate.getTime(), new Date('').getTime()

  test 'deleteGradingPeriod does not call confirmDelete if the grading period is not saved', ->
    unsavedPeriod = [
      {
        "id":"new1", "startDate": new Date("2029-03-01T06:00:00Z"), "endDate": new Date("2030-05-31T05:00:00Z"),
        "weight":null, "title":"New Period. I'm not saved yet!",
        "permissions": { "read":true, "manage":true }
      }
    ]
    @gradingPeriodCollection.setState({periods: unsavedPeriod})
    confirmDelete = @stub($.fn, 'confirmDelete')
    @gradingPeriodCollection.deleteGradingPeriod('new1')
    ok confirmDelete.notCalled

  test 'deleteGradingPeriod calls confirmDelete if the period being deleted is not new (it is saved server side)', ->
    confirmDelete = @stub($.fn, 'confirmDelete')
    @gradingPeriodCollection.deleteGradingPeriod('1')
    ok confirmDelete.calledOnce

  test 'updateGradingPeriodCollection correctly updates the periods state', ->
    updatedPeriodData = {
      "id":"1", "startDate": new Date("2069-03-01T06:00:00Z"), "endDate": new Date("2070-05-31T05:00:00Z"),
      "weight":null, "title":"Updating an existing period!"
    }
    updatedPermissions = { "read":true, "manage":true }
    @gradingPeriodCollection.updateGradingPeriodCollection(updatedPeriodData, updatedPermissions)
    updatedPeriod = _.find(@gradingPeriodCollection.state.periods, (p) => p.id == "1")
    deepEqual updatedPeriod.title, updatedPeriodData.title

  test 'updateGradingPeriodCollection calls getPeriods if a previousStateId is passed in', ->
    @stub(@gradingPeriodCollection, 'getPeriods')
    @gradingPeriodCollection.updateGradingPeriodCollection({}, {}, '1')
    ok @gradingPeriodCollection.getPeriods.calledOnce


  test 'getPeriodById retuns the period with the matching id (if one exists)', ->
    period = @gradingPeriodCollection.getPeriodById('1')
    deepEqual period.id, '1'

  test 'a link to the settings page is displayed if there are 0 or 1 grading periods on the page', ->
    deepEqual @gradingPeriodCollection.refs.linkToSettings, undefined
    onePeriod = [
      {
        "id":"1", "startDate": new Date("2029-03-01T06:00:00Z"), "endDate": new Date("2030-05-31T05:00:00Z"),
        "weight":null, "title":"A Lonely Grading Period",
        "permissions": { "read":true, "manage":true }
      }
    ]
    @gradingPeriodCollection.setState({periods: onePeriod})
    ok @gradingPeriodCollection.refs.linkToSettings
    @gradingPeriodCollection.setState({periods: []})
    ok @gradingPeriodCollection.refs.linkToSettings

  test 'an admin created periods message is NOT displayed since the user has manage permission for the periods', ->
    deepEqual @gradingPeriodCollection.refs.adminPeriodsMessage, undefined

  module 'GradingPeriodCollection without read or manage permissions for any periods',
    setup: ->
      @fMessage = $.flashMessage
      @fError = $.flashError
      $.flashMessage = ->
      $.flashError = ->
      @stub(window, 'confirm', -> true)
      @server = sinon.fakeServer.create()
      ENV.current_user_roles = ["teacher"]
      ENV.GRADING_PERIODS_URL = "/api/v1/courses/1/grading_periods"
      @indexData = "grading_periods":[
        {
          "id":"1", "start_date":"2015-03-01T06:00:00Z", "end_date":"2015-05-31T05:00:00Z",
          "weight":null, "title":"Spring", "permissions": { "read":false, "manage":false }
        },
        {
          "id":"2", "start_date":"2015-06-01T05:00:00Z", "end_date":"2015-08-31T05:00:00Z",
          "weight":null, "title":"Summer", "permissions": { "read":false, "manage":false }
        }
      ]
      @formattedIndexData = "grading_periods":[
        {
          "id":"1", "startDate": new Date("2015-03-01T06:00:00Z"), "endDate": new Date("2015-05-31T05:00:00Z"),
          "weight":null, "title":"Spring", "permissions": { "read":false, "manage":false }
        },
        {
          "id":"2", "startDate": new Date("2015-06-01T05:00:00Z"), "endDate": new Date("2015-08-31T05:00:00Z"),
          "weight":null, "title":"Summer", "permissions": { "read":false, "manage":false }
        }
      ]
      @createdPeriodData = "grading_periods":[
        {
          "id":"3", "start_date":"2015-04-20T05:00:00Z", "end_date":"2015-04-21T05:00:00Z",
          "weight":null, "title":"New Period!", "permissions": { "read":true, "manage":true }
        }
      ]
      @server.respondWith "GET", ENV.GRADING_PERIODS_URL, [200, {"Content-Type":"application/json"}, JSON.stringify @indexData]
      @server.respondWith "POST", ENV.GRADING_PERIODS_URL, [200, {"Content-Type":"application/json"}, JSON.stringify @createdPeriodData ]
      @server.respondWith "DELETE", ENV.GRADING_PERIODS_URL + "/1", [204, {}, ""]
      @gradingPeriodCollection = TestUtils.renderIntoDocument(GradingPeriodCollection())
      @server.respond()
    teardown: ->
      React.unmountComponentAtNode(@gradingPeriodCollection.getDOMNode().parentNode)
      ENV.current_user_roles = null
      ENV.GRADING_PERIODS_URL = null
      $.flashMessage = @fMessage
      $.flashError = @fError
      @server.restore()

  test 'gets the grading periods from the grading periods controller', ->
    deepEqual @gradingPeriodCollection.state.periods, @formattedIndexData.grading_periods

  test 'canManageAtLeastOnePeriod returns false', ->
    periods = @gradingPeriodCollection.state.periods
    ok !@gradingPeriodCollection.canManageAtLeastOnePeriod(periods)

  test 'copyTemplatePeriods sets the disabled state to true while periods are being copied', ->
    @stub(@gradingPeriodCollection, 'getPeriods')
    ok !@gradingPeriodCollection.state.disabled
    @gradingPeriodCollection.copyTemplatePeriods(@gradingPeriodCollection.state.periods)
    @server.respond()
    ok @gradingPeriodCollection.state.disabled

  test 'copyTemplatePeriods calls getPeriods', ->
    @stub(@gradingPeriodCollection, 'getPeriods')
    @gradingPeriodCollection.copyTemplatePeriods(@gradingPeriodCollection.state.periods)
    @server.respond()
    ok @gradingPeriodCollection.getPeriods.calledOnce

  test 'deleteGradingPeriod calls copyTemplatePeriods if periods need to be copied (cannot manage any periods and there is at least 1)', ->
    copyPeriods = @stub(@gradingPeriodCollection, 'copyTemplatePeriods')
    @gradingPeriodCollection.deleteGradingPeriod('1')
    ok copyPeriods.calledOnce

  test 'updateGradingPeriodCollection calls copyTemplatePeriods if periods need to be copied (cannot manage any periods and there is at least 1)', ->
    copyPeriods = @stub(@gradingPeriodCollection, 'copyTemplatePeriods')
    @gradingPeriodCollection.updateGradingPeriodCollection({}, {}, '1')
    ok copyPeriods.calledOnce

  test 'cannotDeleteLastPeriod returns true if there is one period left and manage permission is false', ->
    onePeriod = [
      {
        "id":"1", "startDate": new Date("2029-03-01T06:00:00Z"), "endDate": new Date("2030-05-31T05:00:00Z"),
        "weight":null, "title":"A Lonely Grading Period without manage permission",
        "permissions": { "read":true, "manage":false }
      }
    ]
    @gradingPeriodCollection.setState({periods: onePeriod})
    ok @gradingPeriodCollection.cannotDeleteLastPeriod()

  test 'an admin created periods message is displayed since the user does not have manage permission for the periods', ->
    ok @gradingPeriodCollection.refs.adminPeriodsMessage

  test "given two grading periods that don't overlap, isOverlapping returns false", ->
    ok !@gradingPeriodCollection.isOverlapping('2')

  test 'given two overlapping grading periods, isOverlapping returns true', ->
    startDate = new Date("2015-03-01T06:00:00Z")
    endDate = new Date("2015-05-31T05:00:00Z")
    formattedIndexData = [
      {
        "id":"1", "startDate": startDate, "endDate": endDate,
        "weight":null, "title":"Spring", "permissions": { "read":false, "manage":false }
      },
      {
        "id":"2", "startDate": startDate, "endDate": endDate,
        "weight":null, "title":"Summer", "permissions": { "read":false, "manage":false }
      }
    ]
    @gradingPeriodCollection.setState({periods: formattedIndexData})
    ok @gradingPeriodCollection.isOverlapping('2')
