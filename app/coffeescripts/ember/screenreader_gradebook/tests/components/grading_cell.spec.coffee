define [
  'jquery'
  'ember'
  'timezone'
  '../start_app'
  '../shared_ajax_fixtures'
], ($, Ember, tz, startApp, fixtures) ->

  {run} = Ember

  setType = null

  QUnit.module 'grading_cell',
    setup: ->
      window.ENV = {}
      fixtures.create()
      App = startApp()
      @component = App.GradingCellComponent.create()

      ENV.GRADEBOOK_OPTIONS.grading_period_set =
        id: '1'
        weighted: false
        display_totals_for_all_grading_periods: false
      ENV.current_user_roles = []

      setType = (type) =>
        run => @assignment.set('grading_type', type)
      @component.reopen
        changeGradeURL: ->
          "/api/v1/assignment/:assignment/:submission"
      run =>
        @submission = Ember.Object.create
          grade: 'A'
          gradeLocked: false
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
        window.ENV = {}

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

  test "isInPastGradingPeriodAndNotAdmin is true when the submission is gradeLocked", ->
    run => @submission.set('gradeLocked', true)
    equal @component.get('isInPastGradingPeriodAndNotAdmin'), true

  test "isInPastGradingPeriodAndNotAdmin is false when the submission is not gradeLocked", ->
    run => @submission.set('gradeLocked', false)
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
