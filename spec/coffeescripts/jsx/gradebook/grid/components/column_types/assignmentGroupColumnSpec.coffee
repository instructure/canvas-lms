define [
  'react'
  'react-dom'
  'jsx/gradebook/grid/components/column_types/assignmentGroupColumn'
  'jsx/gradebook/grid/stores/gradingPeriodsStore'
  'jsx/gradebook/grid/stores/assignmentGroupsStore'
  'jsx/gradebook/grid/constants'
  'helpers/fakeENV'
  'jquery'
  'jquery.ajaxJSON'
], (React, ReactDOM, AssignmentGroupColumn, GradingPeriodsStore, AssignmentGroupsStore, GradebookConstants, fakeENV, $) ->
  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  gradingPeriodsData = ->
    GRADEBOOK_OPTIONS:
      current_grading_period_id: '0'

  assignmentGroups = ->
    [{ assignments: [{ id: '3', points_possible: 25 }]}]

  submissions = ->
    [{ assignment_id: '3', id: '6', score: 25 }]

  defaultProps = =>
    groups = assignmentGroups()
    cellData:
      submissions: submissions()
      assignmentGroup: groups[0],
    rowData:
      assignmentGroups: groups

  buildComponent = (props) ->
    cellData = props || defaultProps()
    renderComponent(cellData)

  renderComponent = (props) ->
    element = React.createElement(AssignmentGroupColumn, props)
    ReactDOM.render(element, wrapper)

  innerHTML = (component) ->
    component.refs.cell.getDOMNode().innerHTML

  module 'ReactGradebook.assignmentGroupColumn',
    setup: ->
      fakeENV.setup(gradingPeriodsData())
      GradebookConstants.refresh()
      GradingPeriodsStore.getInitialState()
      AssignmentGroupsStore.getInitialState()
      AssignmentGroupsStore.onLoadCompleted(assignmentGroups())
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper
      fakeENV.teardown()

  test 'mounts on build', ->
    ok(buildComponent().isMounted())

  test 'shows a "%" sign', ->
    component = buildComponent()
    ok(innerHTML(component).match(/%/))

  test 'displays "-" if points possible is 0', ->
    props = defaultProps()
    props.cellData.assignmentGroups = [{assignments: []}]
    props.cellData.submissions = []

    component = buildComponent(props)
    ok(innerHTML(component).match(/-/))

  test 'has title attribute for assignment group cells', ->
    component = buildComponent(defaultProps())
    title = component.refs.cell.props.title
    equal("25 / 25", title)
