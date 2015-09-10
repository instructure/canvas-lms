define [
  'react'
  'jsx/gradebook/grid/components/column_types/assignmentGroupColumn'
  'jsx/gradebook/grid/stores/gradingPeriodsStore'
  'jsx/gradebook/grid/stores/assignmentGroupsStore'
  'jsx/gradebook/grid/constants'
  'helpers/fakeENV'
  'jquery'
  'jquery.ajaxJSON'
], (React, AssignmentGroupColumn, GradingPeriodsStore, AssignmentGroupsStore, GradebookConstants, fakeENV, $) ->
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

  defaultProps = {
    cellData: '0'
    rowData: {
      assignmentGroups: assignmentGroups(),
      submissions: submissions()
    }
  }

  buildComponent = (props) ->
    cellData = props || defaultProps
    renderComponent(cellData)

  renderComponent = (props) ->
    componentFactory = React.createFactory(AssignmentGroupColumn)
    React.render(componentFactory(props), wrapper)

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
      React.unmountComponentAtNode wrapper
      fakeENV.teardown()

  test 'mounts on build', ->
    ok(buildComponent().isMounted())

  test 'shows a "%" sign', ->
    component = buildComponent()
    ok(innerHTML(component).match(/%/))

  test 'is not editable', ->
    component = buildComponent()
    Simulate.click(component)
    notOk(component.refs.cell.props.className.match(/editable/))

  test 'displays "-" if points possible is 0', ->
    props = defaultProps
    props.rowData.assignmentGroups = [{assignments: []}]
    props.rowData.submissions = []

    component = buildComponent(props)
    ok(innerHTML(component).match(/-/))
