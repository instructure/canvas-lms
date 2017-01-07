define [
  'underscore'
  'jsx/gradebook/shared/helpers/assignmentHelper',
], (_, assignmentHelper) ->

  module 'assignmentHelper#getComparator',
    setup: ->
    teardown: ->

  test 'returns the correct function when passed "due_date"', ->
    expectedFn = assignmentHelper.compareByDueDate
    returnedFn = assignmentHelper.getComparator('due_date')
    propEqual returnedFn, expectedFn

  test 'returns the correct function when passed "assignment_group"', ->
    expectedFn = assignmentHelper.compareByAssignmentGroup
    returnedFn = assignmentHelper.getComparator('assignment_group')
    propEqual returnedFn, expectedFn

  module 'assignmentHelper#compareByDueDate',
    setup: ->
    teardown: ->

  generateAssignment = (options) ->
    options = options || {}
    _.defaults(options, { name: 'assignment', due_at: new Date('Mon May 11 2015'), effectiveDueDates: {} })

  generateEffectiveDueDates = ->
    '1':
      due_at: 'Mon May 11 2015'
    '2':
      due_at: 'Tue May 12 2015'

  test 'compares assignments by due date', ->
    assignment1 = generateAssignment()
    assignment2 = generateAssignment({ due_at: new Date('Tue May 12 2015') })
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

    assignment1.due_at = new Date('Wed May 13 2015')
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

  test 'treats null values as "greater" than Date values', ->
    assignment1 = generateAssignment({ due_at: null })
    assignment2 = generateAssignment()
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

  test 'compares by name if dates are the same', ->
    assignment1 = generateAssignment({ name: 'Banana' })
    assignment2 = generateAssignment({ name: 'Apple' })
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

    assignment2.name = 'Carrot'
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

  test 'ignores case when comparing by name', ->
    assignment1 = generateAssignment({ name: 'Banana' })
    assignment2 = generateAssignment({ name: 'apple' })
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

    assignment2.name = 'Apple'
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

  test 'compares by due date overrides if dates are both null', ->
    assignment1 = generateAssignment({ due_at: null })
    assignment1.effectiveDueDates = generateEffectiveDueDates()
    assignment2 = generateAssignment({ due_at: null })
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

  test 'hasMultipleDueDates returns false when provided an empty object', ->
    assignment = {}
    notOk assignmentHelper.hasMultipleDueDates(assignment)

  test 'hasMultipleDueDates returns false when there is only 1 unique effective due date', ->
    assignment = generateAssignment(due_at: null)
    assignment.effectiveDueDates = { '1': { due_at: 'Mon May 11 2015' } }
    notOk assignmentHelper.hasMultipleDueDates(assignment)

  test 'hasMultipleDueDates returns true when provided overrides with a length greater than 1', ->
    assignment = generateAssignment(due_at: null)
    assignment.effectiveDueDates = generateEffectiveDueDates()
    ok assignmentHelper.hasMultipleDueDates(assignment)

  test 'treats assignments with a single override with a null date as' +
  '"greater" than assignments with multiple overrides', ->
    assignment1 = generateAssignment({ due_at: null })
    assignment1.effectiveDueDates = { '1': { due_at: null } }
    assignment2 = generateAssignment({ due_at: null })
    assignment2.effectiveDueDates =
      '1': { due_at: null },
      '2': { due_at: 'Mon May 11 2015' }
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

  test 'compares by name if dates are both null and both have multiple overrides', ->
    assignment1 = { name: 'Banana', due_at: null }
    assignment1.effectiveDueDates =
      '1': { due_at: null },
      '2': { due_at: 'Mon May 11 2015' }
    assignment2 = { name: 'Apple', due_at: null }
    assignment2.effectiveDueDates =
      '1': { due_at: null },
      '2': { due_at: 'Mon May 11 2015' }
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

    assignment2.name = 'Carrot'
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

  test 'compares by name if dates are both null and neither have due date overrides', ->
    assignment1 = { name: 'Banana', due_at: null }
    assignment2 = { name: 'Apple', due_at: null }
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

    assignment2.name = 'Carrot'
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

  test 'treats assignments with the same dates and names as equal', ->
    assignment1 = generateAssignment()
    assignment2 = generateAssignment()
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal == 0

  test 'handles one due_at passed in as string and another passed in as date', ->
    assignment1 = generateAssignment()
    assignment2 = generateAssignment({ due_at: '2015-05-20T06:59:00Z' })
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

    assignment2.due_at = '2015-05-05T06:59:00Z'
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

  test 'handles both due_ats passed in as strings', ->
    assignment1 = generateAssignment({ due_at: '2015-05-11T06:59:00Z' })
    assignment2 = generateAssignment({ due_at: '2015-05-20T06:59:00Z' })
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

    assignment2.due_at = '2015-05-05T06:59:00Z'
    comparisonVal = assignmentHelper.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

  module 'assignmentHelper#compareByAssignmentGroup',
    setup: ->
    teardown: ->

  test 'compares assignments by their assignment group position', ->
    assignment1 = { assignment_group_position: 1, position: 1 }
    assignment2 = { assignment_group_position: 2, position: 1 }
    comparisonVal = assignmentHelper.compareByAssignmentGroup(assignment1, assignment2)
    ok comparisonVal < 0

    assignment1.assignment_group_position = 3
    comparisonVal = assignmentHelper.compareByAssignmentGroup(assignment1, assignment2)
    ok comparisonVal > 0

  test 'compares by assignment position if assignment group position is the same', ->
    assignment1 = { assignment_group_position: 1, position: 2 }
    assignment2 = { assignment_group_position: 1, position: 1 }
    comparisonVal = assignmentHelper.compareByAssignmentGroup(assignment1, assignment2)
    ok comparisonVal > 0

    assignment2.position = 3
    comparisonVal = assignmentHelper.compareByAssignmentGroup(assignment1, assignment2)
    ok comparisonVal < 0

  test 'treats assignments with the same position and group position as equal', ->
    assignment1 = { assignment_group_position: 1, position: 1 }
    assignment2 = { assignment_group_position: 1, position: 1 }
    comparisonVal = assignmentHelper.compareByAssignmentGroup(assignment1, assignment2)
    ok comparisonVal == 0
