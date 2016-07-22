define [
  'ember'
  'timezone'
  '../start_app'
  '../shared_ajax_fixtures'
  'helpers/fakeENV'
], (Ember, tz, startApp, fixtures, fakeENV) ->

  {run} = Ember

  setType = null

  module 'grading_cell',
    setup: ->
      fakeENV.setup()
      fixtures.create()
      App = startApp()
      @component = App.GradingCellComponent.create()

      ENV.GRADEBOOK_OPTIONS.multiple_grading_periods_enabled = true
      ENV.GRADEBOOK_OPTIONS.latest_end_date_of_admin_created_grading_periods_in_the_past = "2013-10-01T10:00:00Z"
      ENV.current_user_roles = []

      setType = (type) =>
        run => @assignment.set('grading_type', type)
      @component.reopen
        changeGradeURL: ->
          "/api/v1/assignment/:assignment/:submission"
      run =>
        @submission = Ember.Object.create
          grade: 'A'
          assignment_id: 1
          user_id: 1
        @assignment = Ember.Object.create
          due_at: tz.parse("2013-10-01T10:00:00Z")
          grading_type: 'points'
        @component.setProperties
          'submission': @submission
          assignment: @assignment
        @component.append()

    teardown: ->
      run =>
        @component.destroy()
        App.destroy()
        fakeENV.teardown()

  test "setting value on init", ->
    component = App.GradingCellComponent.create()
    equal(component.get('value'), '-')

    equal(@component.get('value'), 'A')


  test "saveURL", ->
    equal(@component.get('saveURL'), "/api/v1/assignment/1/1")

  test "isPoints", ->
    setType 'points'
    ok @component.get('isPoints')

  test "isPercent", ->
    setType 'percent'
    ok @component.get('isPercent')

  test "isLetterGrade", ->
    setType 'letter_grade'
    ok @component.get('isLetterGrade')

  test "isInPastGradingPeriodAndNotAdmin is false when multiple grading periods are not enabled", ->
    ENV.GRADEBOOK_OPTIONS.multiple_grading_periods_enabled = false
    equal @component.get('isInPastGradingPeriodAndNotAdmin'), false

  test "isInPastGradingPeriodAndNotAdmin is false when no grading periods are in the past", ->
    ENV.GRADEBOOK_OPTIONS.latest_end_date_of_admin_created_grading_periods_in_the_past = null
    equal @component.get('isInPastGradingPeriodAndNotAdmin'), false

  test "isInPastGradingPeriodAndNotAdmin is false when current user roles are undefined", ->
    ENV.current_user_roles = null
    equal @component.get('isInPastGradingPeriodAndNotAdmin'), false

  test "isInPastGradingPeriodAndNotAdmin is false when the current user is an admin", ->
    ENV.current_user_roles = ['admin']
    equal @component.get('isInPastGradingPeriodAndNotAdmin'), false

  test "isInPastGradingPeriodAndNotAdmin is true for assignments in the previous grading period", ->
    run => @assignment.set('due_at', tz.parse("2013-10-01T09:59:00Z"))
    equal @component.get('isInPastGradingPeriodAndNotAdmin'), true

  test "isInPastGradingPeriodAndNotAdmin is true for assignments due exactly at the end of the previous grading period", ->
    run => @assignment.set('due_at', tz.parse("2013-10-01T10:00:00Z"))
    equal @component.get('isInPastGradingPeriodAndNotAdmin'), true

  test "isInPastGradingPeriodAndNotAdmin is false for assignments after the previous grading period", ->
    run => @assignment.set('due_at', tz.parse("2013-10-01T10:01:00Z"))
    equal @component.get('isInPastGradingPeriodAndNotAdmin'), false

  test "isInPastGradingPeriodAndNotAdmin is false for assignments without a due date", ->
    run => @assignment.set('due_at', null)
    equal @component.get('isInPastGradingPeriodAndNotAdmin'), false

  test "nilPointsPossible", ->
    ok @component.get('nilPointsPossible')
    run => @assignment.set('points_possible', 10)
    equal @component.get('nilPointsPossible'), false

  test "isGpaScale", ->
    setType 'gpa_scale'
    ok @component.get('isGpaScale')

  asyncTest "focusOut", ->
    stub = @stub @component, 'boundUpdateSuccess'
    submissions = []

    requestStub = null
    run =>
      requestStub = Ember.RSVP.resolve all_submissions: submissions

    @stub(@component, 'ajax').returns requestStub

    run =>
      @component.set('value', 'ohai')
      @component.send('focusOut', {target: {id: 'student_and_assignment_grade'}})
      start()

    ok stub.called

  test "onUpdateSuccess", ->
    run => @assignment.set('points_possible', 100)
    flashWarningStub = @stub $, 'flashWarning'
    @component.onUpdateSuccess({all_submissions: [], score: 150})
    ok flashWarningStub.called
