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

  gradingPeriodsData = ->
    GRADEBOOK_OPTIONS:
      current_grading_period_id: '0'

  getGrade = (props) ->
    component = buildComponent(props)
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
      fakeENV.teardown()

  test 'mounts on build', ->
    ok(buildComponent().isMounted())

  test 'displays "0%" if there are no submissions yet', ->
    grade = buildComponent().refs.totalGrade.getDOMNode().innerHTML
    equal(grade, '-')

  test 'Displays a % on a numeric value', ->
    cellData = {
      rowData: {
        enrollment: {},
        assignmentGroups: [{ assignments: [{ id: '3', points_possible: 25 }]}],
        submissions: [{ assignment_id: '3', score: 25 }]
      }
    }
    grade = getGrade(cellData)
    equal(grade, '100%')

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
