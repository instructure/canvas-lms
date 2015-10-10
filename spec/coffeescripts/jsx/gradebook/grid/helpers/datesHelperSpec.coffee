define [
  'react'
  'jsx/gradebook/grid/helpers/datesHelper'
  'underscore'
], (React, DatesHelper, _) ->

  defaultAssignment = ->
    {
      title: "assignment",
      created_at: "2015-07-06T18:35:22Z",
      due_at: "2015-07-14T18:35:22Z",
      updated_at: "2015-07-07T18:35:22Z"
    }

  module 'DatesHelper#parseDates',

  test 'returns a new object with specified dates parsed', ->
    assignment = defaultAssignment()
    datesToParse = ['created_at', 'due_at']
    assignment = DatesHelper.parseDates(assignment, datesToParse)

    ok _.isDate(assignment.created_at)
    ok _.isDate(assignment.due_at)
    notOk _.isDate(assignment.updated_at)

  test 'gracefully handles null values', ->
    assignment = defaultAssignment()
    assignment.due_at = null
    datesToParse = ['created_at', 'due_at']
    assignment = DatesHelper.parseDates(assignment, datesToParse)

    ok _.isDate(assignment.created_at)
    ok _.isNull(assignment.due_at)

  test 'gracefully handles undefined values', ->
    assignment = defaultAssignment()
    datesToParse = ['created_at', 'undefined_due_at']
    assignment = DatesHelper.parseDates(assignment, datesToParse)

    ok _.isDate(assignment.created_at)
    ok _.isUndefined(assignment.undefined_due_at)
