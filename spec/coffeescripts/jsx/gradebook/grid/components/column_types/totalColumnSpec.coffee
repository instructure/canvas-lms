define [
  'underscore'
  'react'
  'react-dom'
  'jsx/gradebook/grid/components/column_types/totalColumn'
  'jsx/gradebook/grid/stores/gradingPeriodsStore'
  'jsx/gradebook/grid/stores/assignmentGroupsStore'
  'jsx/gradebook/grid/constants'
  'helpers/fakeENV'
  'jquery'
  'jquery.ajaxJSON'
], (_, React, ReactDOM, TotalColumn, GradingPeriodsStore, AssignmentGroupsStore, GradebookConstants, fakeENV, $) ->
  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  assignmentGroups = ->
    [{ assignments: [{ id: '3', points_possible: 25 }]}]

  submissions = ->
    [{ assignment_id: '3', id: '6', score: 25 }]

  propsWithSubmissions = ->
    rowData:
      assignmentGroups: [{ assignments: [{ id: '3', points_possible: 25 }]}],
      submissions: submissions()

  gradingPeriodsData = ->
    GRADEBOOK_OPTIONS:
      current_grading_period_id: '0'

  totalGradeOutput = (component) ->
    component.refs.totalGrade.getDOMNode().innerHTML

  buildComponent = (props) ->
    cellData = props || {cellData: '1', rowData: {submissions: []}}
    element = React.createElement(TotalColumn, cellData)
    ReactDOM.render(element, wrapper)

  firstTestAssignment = (opts) ->
    defaultAssignment = { name: 'assignment 1', id: '3', points_possible: 25, submission_types: ['graded'] }
    _.defaults(opts || {}, defaultAssignment)

  secondTestAssignment = (opts) ->
    defaultAssignment = { name: 'assignment 2', id: '7', points_possible: 15, submission_types: ['graded'] }
    _.defaults(opts || {}, defaultAssignment)

  generateCellData = (assignment1Properties, assignment2Properties, groupProperties) ->
    assignmentGroup = _.defaults(groupProperties || {}, { name: 'Group A' })
    assignmentGroup.assignments = [
      firstTestAssignment(assignment1Properties),
      secondTestAssignment(assignment2Properties)
    ]
    rowData:
      assignmentGroups: [assignmentGroup]

  module 'ReactGradebook.totalColumn',
    setup: ->
      fakeENV.setup(gradingPeriodsData())
      GradebookConstants.refresh()
      GradingPeriodsStore.getInitialState()
      AssignmentGroupsStore.getInitialState()
      AssignmentGroupsStore.onLoadCompleted(assignmentGroups())
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper
      AssignmentGroupsStore.assignmentGroups = undefined
      GradingPeriodsStore.gradingPeriods = undefined
      fakeENV.teardown()

  test 'mounts on build', ->
    ok(buildComponent().isMounted())

  test 'displays "-" if there are no submissions yet', ->
    component = buildComponent()
    deepEqual(totalGradeOutput(component), '-')

  test 'Displays a % on a numeric value', ->
    props = propsWithSubmissions()
    component = buildComponent(props)
    deepEqual(totalGradeOutput(component), '100%')

  test 'displays warning icon if all assignments combined have 0 points possible', ->
    cellData = generateCellData({ points_possible: 0 }, { points_possible: 0 }, { shouldShowNoPointsWarning: false })
    component = buildComponent(cellData)
    equal component.refs.icon.props.className, 'icon-warning final-warning'

  test 'shows grade as points if the user selects "Show As Points"', ->
    props = propsWithSubmissions()
    component = buildComponent(props)
    component.setState({ toolbarOptions: { showTotalGradeAsPoints: true } })
    deepEqual(totalGradeOutput(component), '25')

  test 'displays "-" if there are no submissions yet with "Show As Points" selected', ->
    component = buildComponent()
    component.setState({ toolbarOptions: { showTotalGradeAsPoints: true } })
    deepEqual(totalGradeOutput(component), '-')

  test 'displays mute icon if an assignment is muted', ->
    cellData = generateCellData({ muted: true }, { muted: true })
    component = buildComponent(cellData)
    equal component.refs.icon.props.className, 'icon-muted final-warning'

  test 'assignments(): picks all assignments out of assignmentGroups()', ->
    cellData = generateCellData()
    totalColumn = buildComponent(cellData)
    deepEqual(totalColumn.assignments(), [firstTestAssignment(), secondTestAssignment()])

  test 'visibleAssignments(): assignments without the not_graded submissions type', ->
    cellData = generateCellData(submission_types: ['not_graded'])
    totalColumn = buildComponent(cellData)
    propEqual(totalColumn.visibleAssignments(), [secondTestAssignment()])

  test 'getWarning() for anyMutedAssignments', ->
    cellData = generateCellData(muted: true)
    totalColumn = buildComponent(cellData)
    equal(totalColumn.getWarning(), "This grade differs from the student's view of the grade because some assignments are muted")

  test 'getWarning() for group with no points', ->
    cellData = generateCellData({ submission_types: ['not_graded'] }, null, { shouldShowNoPointsWarning: true })
    groupWeightingSchemeData = ->
      GRADEBOOK_OPTIONS:
        group_weighting_scheme: 'percent'
    fakeENV.setup(groupWeightingSchemeData())
    totalColumn = buildComponent(cellData)
    equal(totalColumn.getWarning(), 'Score does not include Group A because it has no points possible')

  test 'getWarning() for multiple groups with no points', ->
    cellData = generateCellData(
      { submission_types: ['not_graded'], points_possible: null },
      { points_possible: null },
      { shouldShowNoPointsWarning: true }
    )
    groupB =
      shouldShowNoPointsWarning: true
      name: 'Group B'
      assignments: [
        { id: '1', submission_types: ['not_graded']}
        { id: '2', submission_types: ['graded']}
      ]
    cellData.rowData.assignmentGroups.push(groupB)

    groupWeightingSchemeData = ->
      GRADEBOOK_OPTIONS:
        group_weighting_scheme: 'percent'
    fakeENV.setup(groupWeightingSchemeData())
    totalColumn = buildComponent(cellData)
    equal(totalColumn.getWarning(), 'Score does not include Group A and Group B because they have no points possible')


  test 'getWarning() for noPointsPossible', ->
    cellData = generateCellData({ points_possible: 0 }, { points_possible: 0 })
    totalColumn = buildComponent(cellData)
    equal(totalColumn.getWarning(), "Can't compute score until an assignment has points possible")

  test 'anyMutedAssignments() for one muted assignment', ->
    cellData = generateCellData(muted: true)
    totalColumn = buildComponent(cellData)
    ok(totalColumn.anyMutedAssignments())

  test 'anyMutedAssignments() for no muted assignments', ->
    cellData = generateCellData()
    totalColumn = buildComponent(cellData)
    notOk(totalColumn.anyMutedAssignments())

  test 'noPointsPossible() for null and 0 points is true', ->
    cellData = generateCellData({ points_possible: null }, { points_possible: 0 })
    totalColumn = buildComponent(cellData)
    ok(totalColumn.noPointsPossible())

  test 'noPointsPossible() for greater than 0 points is false', ->
    cellData = generateCellData(points_possible: null)
    totalColumn = buildComponent(cellData)
    notOk(totalColumn.noPointsPossible())

  test 'iconClassNames() produces no class names for no muted and has points', ->
    cellData = generateCellData()
    totalColumn = buildComponent(cellData)
    equal(totalColumn.iconClassNames(), '')

  test 'iconClassNames() produces class names for muted', ->
    cellData = generateCellData(muted: true)
    totalColumn = buildComponent(cellData)
    equal(totalColumn.iconClassNames(), 'icon-muted final-warning')

  test 'iconClassNames() produces class names no points', ->
    cellData = generateCellData({ points_possible: 0 }, { points_possible: 0 })
    totalColumn = buildComponent(cellData)
    equal(totalColumn.iconClassNames(), 'icon-warning final-warning')

  test "assignmentGroups() returns rowData's assignmentGroups", ->
    cellData = generateCellData()
    totalColumn = buildComponent(cellData)
    propEqual(totalColumn.assignmentGroups(), [{
      name: 'Group A', assignments: [firstTestAssignment(), secondTestAssignment()]
    }] )
