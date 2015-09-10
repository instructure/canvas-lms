define [
  'react'
  'jsx/gradebook/grid/stores/submissionsStore'
  'jsx/gradebook/grid/stores/assignmentGroupsStore'
  'jsx/gradebook/grid/stores/gradingPeriodsStore'
  'jsx/gradebook/grid/constants'
  'helpers/fakeENV'
  'jquery'
], (React, SubmissionsStore, AssignmentGroupsStore, GradingPeriodsStore,
    GradebookConstants, fakeENV, $) ->
  TestUtils = React.addons.TestUtils

  defaultSubmissions = ->
    [
      {
        assignment_id: '1'
        submissions: [
          id: '1'
        ]
      }
      {
        assignment_id: '4'
        submissions: [
          id: '2'
        ]
      }
    ]

  assignmentObject = (id) ->
    {
      id: "#{id}"
      assignment_group_position: undefined
      speedgrader_url: "undefined/gradebook/speed_grader?assignment_id=#{id}"
      submissions_downloads: 0
      shouldShowNoPointsWarning: true
    }

  postedGrade = () ->
    userId: '1'
    grade: '100'
    assignmentId: 1

  submissionData = (assignmentSubmission) ->
    [{section_id: '1', submissions: assignmentSubmission || [], user_id: '1'}]

  response = () ->
    id: 1
    grade: '100'

  submissionsLength = () ->
    SubmissionsStore.submissions.data[0].submissions.length

  module 'ReactGradebook.submissionsStore',
    teardown: ->
      SubmissionsStore.getInitialState()

  test '#getInitialState() should return an object with data, error, and selected attributes', ->
    initialState = SubmissionsStore.getInitialState()
    propEqual(initialState, {data: null, error: null, selected: null})

  test 'should display an error when updating submission fails', ->
    flashErrorMock = sinon.mock($)
    errorExpectation = flashErrorMock.expects('flashError')
    errorExpectation.once()
    SubmissionsStore.onUpdateGradeFailed()

    ok(errorExpectation.verify())
    flashErrorMock.restore()

  test '#onLoadCompleted should set submissions.data and trigger a setState', ->
    triggerMock =  sinon.mock(SubmissionsStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    SubmissionsStore.onLoadCompleted(submissionData())

    ok(SubmissionsStore.submissions.data)
    ok(triggerExpectation.once())
    triggerMock.restore()

  test '#onLoadFailed should set submissions.error and trigger a setState', ->
    triggerMock = sinon.mock(SubmissionsStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    SubmissionsStore.onLoadFailed('error')

    ok(SubmissionsStore.submissions.error)
    ok(triggerExpectation.once())
    triggerMock.restore()

  test 'should push submission on user submissions array when it is a new submission', ->
    SubmissionsStore.onLoadCompleted(submissionData())
    SubmissionsStore.onUpdateGradeCompleted(postedGrade(), response())
    equal(submissionsLength(), 1)

  test 'should replace submission on user submissions array when a submission is updated', ->
    assignmentSubmission =
      id: 1
      grade: '100'

    SubmissionsStore.onLoadCompleted(submissionData([assignmentSubmission]))
    equal(submissionsLength(), 1)

    SubmissionsStore.onUpdateGradeCompleted(postedGrade(), response())
    equal(submissionsLength(), 1)

  test 'should trigger state change during #onUpdateGradeCompleted', ->
    triggerMock =  sinon.mock(SubmissionsStore)
    triggerExpectation = triggerMock.expects('trigger').twice()
    SubmissionsStore.onLoadCompleted(submissionData())
    SubmissionsStore.onUpdateGradeCompleted(postedGrade(), response())

    ok(triggerExpectation.verify())
    triggerMock.restore()

  test '#onUpdatedSubmissionsReceived updates existing submissions', ->
    submissions = [
      { id: '1', grade: '100' },
      { id: '2', grade: '50' }
    ]
    SubmissionsStore.onLoadCompleted(submissionData(submissions))
    updatedSubmissions = [{ id: '2', grade: '95' }]
    SubmissionsStore.onUpdatedSubmissionsReceived(updatedSubmissions)
    actual = SubmissionsStore.submissions.data[0].submissions
    expected = [{ id: '1', grade: '100' }, { id: '2', grade: '95' }]
    propEqual actual, expected

  module 'SubmissionsStore#filterSubmissions',
    setup: ->
      @submissions = defaultSubmissions()

      @assignments = [
        { id: '1' }
        { id: '2' }
        { id: '3' }
      ]
      SubmissionsStore.on
    teardown: ->
      @submissions = undefined
      @assignments = undefined

  test 'filters out submissions which are not in the assignment list', ->
    expected = [@submissions[0]]
    actual = SubmissionsStore.filterSubmissions(@submissions, @assignments)
    deepEqual(actual, expected)

  module 'SubmissionsStore#assignmentGroupsForSubmissions',
    setup: ->
      @submissions = defaultSubmissions()
      @assignmentGroups = [
        {
          id: '1'
          assignments: [
            {
              id: '1'
            }
          ]
        }
        {
          id: '2'
          assignments: [
            {
              id: '2'
            }
          ]
        }
        {
          id: '3'
          assignments: [
            {
              id: '4'
            }
          ]
        }
      ]
    teardown: ->
      @submissions = undefined
      @assignmentGroups = undefined

  test 'filters out assignment groups which do not have a submitted assignment in the list', ->
    expected = [@assignmentGroups[0], @assignmentGroups[2]]
    actual = SubmissionsStore.assignmentGroupsForSubmissions(@submissions, @assignmentGroups)
    deepEqual(actual, expected)

  module 'SubmissionsStore#assignmentsForSubmissions',
    setup: ->
      @submissions = defaultSubmissions()
      @assignmentGroups = [
        {
          id: '1'
          assignments: [
            {
              id: '1'
            }
            {
              id: '2'
            }
            {
              id: '3'
            }
            {
              id: '4'
            }
          ]
        }
      ]
      AssignmentGroupsStore.getInitialState()
      AssignmentGroupsStore.onLoadCompleted(@assignmentGroups)
    teardown: ->
      @submissions = undefined
      @assignmentGroups = undefined

  test 'gets assignments for given submissions', ->
    expected = [
      assignmentObject(1)
      assignmentObject(4)
    ]
    actual = SubmissionsStore.assignmentsForSubmissions(@submissions)
    deepEqual(actual, expected)

  gradingPeriodsData = ->
    GRADEBOOK_OPTIONS:
      current_grading_period_id: '3'
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

  module 'SubmissionsStore#submissionsInPeriod',
    setup: ->
      fakeENV.setup(gradingPeriodsData())
      @submissions = defaultSubmissions()
      @assignments = [
            {
              id: '1'
              due_at: '2015-08-16T06:01:00Z'
            }
            {
              id: '2'
              due_at: '2015-08-16T06:01:00Z'
            }
            {
              id: '3'
              due_at: '2016-08-11T06:00:00Z'
            }
            {
              id: '4'
              due_at: '2015-08-11T06:00:00Z'
            }
        ]
      @assignmentGroups = [
        {
          id: '1'
          assignments: @assignments
        }
      ]
      @period = gradingPeriodsData().GRADEBOOK_OPTIONS.active_grading_periods[1]
      GradingPeriodsStore.getInitialState()
      AssignmentGroupsStore.getInitialState()
      AssignmentGroupsStore.onLoadCompleted(@assignmentGroups)
    teardown: ->
      @period = undefined
      @assignmentGroups = undefined
      @assignments = undefined
      @submissions = undefined
      fakeENV.teardown()

  test 'filters a list of submissions by a given grading period', ->
    expected = [@submissions[1]]
    actual = SubmissionsStore.submissionsInPeriod(@submissions, @period)
    deepEqual(actual, expected)

  module 'SubmissionsStore#submissionsInCurrentPeriod',
    setup: ->
      @submissions = defaultSubmissions()
      fakeENV.setup(gradingPeriodsData())
      @assignments = [
            {
              id: '1'
              due_at: '2015-08-16T06:01:00Z'
            }
            {
              id: '2'
              due_at: '2015-08-16T06:01:00Z'
            }
            {
              id: '3'
              due_at: '2016-08-11T06:00:00Z'
            }
            {
              id: '4'
              due_at: '2015-08-11T06:00:00Z'
            }
        ]
      @assignmentGroups = [
        {
          id: '1'
          assignments: @assignments
        }
      ]
      GradebookConstants.refresh()
      GradingPeriodsStore.getInitialState()
      AssignmentGroupsStore.getInitialState()
      AssignmentGroupsStore.onLoadCompleted(@assignmentGroups)
    teardown: ->
      fakeENV.teardown()
      @submissions = undefined
      @assignments = undefined
      @assignmentGroups = undefined

  test 'retrieves the submissions in the current grading period', ->
    expected = [@submissions[1]]
    actual = SubmissionsStore.submissionsInCurrentPeriod(@submissions)
    deepEqual(actual, expected)
