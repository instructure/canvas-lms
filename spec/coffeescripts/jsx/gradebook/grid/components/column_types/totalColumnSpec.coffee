define [
  'react'
  'jsx/gradebook/grid/components/column_types/totalColumn'
  'jsx/gradebook/grid/stores/gradingPeriodsStore'
  'jsx/gradebook/grid/stores/assignmentGroupsStore'
  'jsx/gradebook/grid/constants'
  'helpers/fakeENV'
  'jquery'
  'jquery.ajaxJSON'
], (React, TotalColumn, GradingPeriodsStore, AssignmentGroupsStore, GradebookConstants, fakeENV, $) ->
  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  assignmentGroups = ->
    [{ assignments: [{ id: '3', points_possible: 25 }]}]

  submissions = ->
    [{ assignment_id: '3', id: '6', score: 25 }]

  propsWithSubmissions = ->
    rowData:
      enrollment: {},
      assignmentGroups: [{ assignments: [{ id: '3', points_possible: 25 }]}],
      submissions: submissions()

  gradingPeriodsData = ->
    GRADEBOOK_OPTIONS:
      current_grading_period_id: '0'

  getGrade = (component) ->
    component.refs.totalGrade.getDOMNode().innerHTML

  buildComponent = (props) ->
    cellData = props || {cellData: '1', rowData: {enrollment: {}, submissions: []}}
    renderComponent(cellData)

  renderComponent = (props) ->
    componentFactory = React.createFactory(TotalColumn)
    React.render(componentFactory(props), wrapper)

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
    deepEqual(getGrade(component), '-')

  test 'Displays a % on a numeric value', ->
    props = propsWithSubmissions()
    component = buildComponent(props)
    deepEqual(getGrade(component), '100%')

  test 'is not editable', ->
    component = buildComponent()
    Simulate.click(component)
    notOk(component.refs.cell.props.className.match(/editable/))

  test 'displays warning icon if assignment group has 0 points possible', ->
    cellData =
      rowData:
        assignmentGroups: [{shouldShowNoPointsWarning: true, assignments: [{id: '3', points_possible: 0}]}]
        enrollment: {}

    component = buildComponent(cellData)
    ok component.refs.icon

  test 'displays warning icon if all assignments combined have 0 points possible', ->
    cellData =
      rowData:
        assignmentGroups: [{shouldShowNoPointsWarning: false, assignments: [{id: '3', points_possible: 0}]}]
        enrollment: {}

    component = buildComponent(cellData)
    ok component.refs.icon

  test 'shows grade as points if the user selects "Show As Points"', ->
    props = propsWithSubmissions()
    component = buildComponent(props)
    component.setState({ toolbarOptions: { showTotalGradeAsPoints: true } })
    deepEqual(getGrade(component), '25')

  test 'displays "-" if there are no submissions yet with "Show As Points" selected', ->
    component = buildComponent()
    component.setState({ toolbarOptions: { showTotalGradeAsPoints: true } })
    deepEqual(getGrade(component), '-')
