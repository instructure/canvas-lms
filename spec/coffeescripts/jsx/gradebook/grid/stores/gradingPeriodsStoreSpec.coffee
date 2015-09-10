define [
  'jsx/gradebook/grid/stores/gradingPeriodsStore',
  'jsx/gradebook/grid/constants',
  'helpers/fakeENV'
], (GradingPeriodsStore, GradebookConstants, fakeENV) ->

  gradingPeriodsData = ->
    GRADEBOOK_OPTIONS:
      active_grading_periods: [
        {
          id: '4'
          start_date: '2015-08-16T06:01:00Z'
          end_date: '2015-08-31T06:01:59Z'
          title: 'Period 2'
          is_last: true
        }
        {
          id: '3'
          start_date: '2015-08-11T06:00:00Z'
          end_date: '2015-08-16T06:00:59Z'
          title: 'Period 2'
          is_last: false
        }
      ]

  getGradingPeriod = (index) ->
    return gradingPeriodsData().GRADEBOOK_OPTIONS.active_grading_periods[index]

  baseSetup = ->
    fakeENV.setup gradingPeriodsData()
    GradingPeriodsStore.getInitialState()
    GradebookConstants.refresh()

  module 'GradingPeriodsStore#assignmentIsInPeriod',
    setup: ->
      baseSetup()
      @assignment =
        due_at: '2015-08-16T06:01:00Z'

    teardown: ->
      @assignment = undefined
      @gradingPeriod = undefined
      fakeENV.teardown()

  test 'knows when an assignment is in a grading period', ->
    gradingPeriod = getGradingPeriod 0
    result = GradingPeriodsStore.assignmentIsInPeriod(this.assignment, gradingPeriod)
    ok(result)

  test 'knows when an assignment is not in a grading period', ->
    gradingPeriod = getGradingPeriod 1
    result = GradingPeriodsStore.assignmentIsInPeriod(this.assignment, gradingPeriod)
    notOk(result)

  module 'GradingPeriodsStore#periodIsActive',
    setup: ->
      baseSetup()
    teardown: ->
      fakeENV.teardown()

  test 'knows if a period is active', ->
    periodId = '3'
    result = GradingPeriodsStore.periodIsActive(periodId)
    ok(result)

  test 'knows if a period is not active', ->
    periodId = '5'
    result = GradingPeriodsStore.periodIsActive(periodId)
    notOk(result)

  module 'GradingPeriodsStore#lastPeriod',
    setup: ->
      baseSetup()
    teardown: ->
      fakeENV.teardown()

  test 'knows which grading period is last', ->
    expected = getGradingPeriod 0
    actual = GradingPeriodsStore.lastPeriod()
    deepEqual(actual, expected)

  module 'GradingPeriodsStore#assignmentsInPeriod',
    setup: ->
      baseSetup()
      @assignment1 =
        due_at: '2015-08-31T06:01:59Z'
      @assignment2 =
        due_at: '2015-08-16T06:00:00Z'
      @assignment3 =
        due_at: null
      @assignments = [
        @assignment1
        @assignment2
        @assignment3
      ]
      @gradingPeriod = getGradingPeriod 1
      @allGradingPeriods =
        id: '0'
        start_date: '2015-08-16T06:01:00Z'
        end_date: '2015-08-31T06:01:59Z'
        title: 'All Grading Periods'
        is_last: false

    teardown: ->
      fakeENV.teardown()

  test 'can filter a list of assignments by grading period', ->
    expected = [@assignment2]
    actual = GradingPeriodsStore.assignmentsInPeriod @assignments, @gradingPeriod
    deepEqual(actual, expected)

  test 'puts an assignment with no due date in "all periods" period', ->
    expected = @assignments
    actual = GradingPeriodsStore.assignmentsInPeriod @assignments, @allGradingPeriods
    deepEqual(expected, actual)
