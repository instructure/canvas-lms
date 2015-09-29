define [
  'react'
  'jsx/gradebook/grid/stores/assignmentGroupsStore'
  'underscore'
], (React, AssignmentGroupsStore, _) ->

  assignmentGroup = ->
    title: 'assignment group'
    position: 1

  assignmentWithoutOverrides = ->
    title: 'assignment without overrides'
    created_at: '2015-07-06T18:35:22Z'
    due_at: '2015-07-14T18:35:22Z'
    updated_at: null
    lock_at: null
    unlock_at: null
    has_overrides: false

  assignmentWithOverrides = ->
    title: 'assignment with overrides'
    created_at: '2015-07-06T18:35:22Z'
    due_at: '2015-07-14T18:35:22Z'
    updated_at: null
    lock_at: null
    unlock_at: null
    has_overrides: true
    overrides: [
      {
        all_day_date: null, due_at: '2015-08-14T18:35:22Z',
        lock_at: null, unlock_at: null
      },
      {
        all_day_date: null, due_at: '2015-07-24T18:35:22Z',
        lock_at: '2015-07-26T18:35:22Z', unlock_at: '2015-07-20T18:35:22Z'
      }
    ]

  module 'AssignmentGroupsStore#formatAssignment',

  test 'parses created_at, updated_at, due_at, lock_at, and unlock_at (if exist and non null)', ->
    assignment = assignmentWithoutOverrides()
    group = assignmentGroup()
    formattedAssignment = AssignmentGroupsStore.formatAssignment(assignment, group)

    ok _.isDate(formattedAssignment.created_at)
    ok _.isDate(formattedAssignment.due_at)

  test 'parses all_day_date, due_at, lock_at, and unlock_at on any overrides', ->
    assignment = assignmentWithOverrides()
    group = assignmentGroup()
    formattedAssignment = AssignmentGroupsStore.formatAssignment(assignment, group)
    formattedOverrides = formattedAssignment.overrides

    ok _.isDate(formattedOverrides[0].due_at)
    ok _.isDate(formattedOverrides[1].due_at)
    ok _.isDate(formattedOverrides[1].lock_at)
    ok _.isDate(formattedOverrides[1].unlock_at)

  test 'adds an assignment_group_position property to the assignment', ->
    assignment = assignmentWithoutOverrides()
    group = assignmentGroup()
    ok _.isUndefined(assignment.assignment_group_position)
    formattedAssignment = AssignmentGroupsStore.formatAssignment(assignment, group)

    deepEqual formattedAssignment.assignment_group_position, 1

  module 'AssignmentGroupsStore#assignments',
    setup: ->
      @assignmentGroup = assignmentGroup()
      @assignments = [
        {
          id: '1'
          title: 'assignment without overrides'
          created_at: '2015-07-06T18:35:22Z'
          due_at: '2015-07-14T18:35:22Z'
          updated_at: null
          lock_at: null
          unlock_at: null
          has_overrides: false
        }
        {
          id: '2'
          title: 'assignment without overrides'
          created_at: '2015-07-06T18:35:22Z'
          due_at: '2015-07-14T18:35:22Z'
          updated_at: null
          lock_at: null
          unlock_at: null
          has_overrides: false
        }
        {
          id: '3'
          title: 'assignment without overrides'
          created_at: '2015-07-06T18:35:22Z'
          due_at: '2015-07-14T18:35:22Z'
          updated_at: null
          lock_at: null
          unlock_at: null
          has_overrides: false
        }
      ]
      @assignmentGroup.assignments = @assignments
      @assignmentIds = ['2', '3']
      AssignmentGroupsStore.getInitialState()
      AssignmentGroupsStore.onLoadCompleted([@assignmentGroup])
    teardown: ->
      @assignment = undefined

  test 'converts a list of assignment ids to assignments', ->
    expected = [
      @assignments[1]
      @assignments[2]
    ]
    actual = AssignmentGroupsStore.assignments ['2', '3']
    deepEqual(actual, expected)
