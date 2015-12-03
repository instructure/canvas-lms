define [
  'underscore'
  'react'
  'jsx/gradebook/grid/components/column_types/totalColumn'
  'jsx/gradebook/grid/stores/gradingPeriodsStore'
  'jsx/gradebook/grid/stores/assignmentGroupsStore'
  'jsx/gradebook/grid/constants'
  'helpers/fakeENV'
  'jquery'
  'jquery.ajaxJSON'
], (_, React, TotalColumn, GradingPeriodsStore, AssignmentGroupsStore, GradebookConstants, fakeENV, $) ->
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
    React.render(element, wrapper)

  module 'ReactGradebook.totalColumn',
    setup: ->
      fakeENV.setup(gradingPeriodsData())
      GradebookConstants.refresh()
      GradingPeriodsStore.getInitialState()
      AssignmentGroupsStore.getInitialState()
      AssignmentGroupsStore.onLoadCompleted(assignmentGroups())
    teardown: ->
      React.unmountComponentAtNode wrapper
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

  test 'displays warning icon if assignment group has 0 points possible', ->
    cellData =
      rowData:
        assignmentGroups: [{shouldShowNoPointsWarning: true, assignments: [{id: '3', points_possible: 0}]}]

    component = buildComponent(cellData)
    equal component.refs.icon.props.className, 'icon-warning final-warning'

  test 'displays warning icon if all assignments combined have 0 points possible', ->
    cellData =
      rowData:
        assignmentGroups: [{shouldShowNoPointsWarning: false, assignments: [{id: '3', points_possible: 0}]}]

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
    cellData =
      rowData:
        assignmentGroups: [{assignments: [{ id: '3', muted: true }] }]
    component = buildComponent(cellData)
    equal component.refs.icon.props.className, 'icon-muted final-warning'
