define [
  'react'
  'react-dom'
  'jsx/gradebook/grid/components/column_types/assignmentPoints'
  'jquery'
], (React, ReactDOM, AssignmentPoints, $) ->

  renderComponent = (data) ->
    element = React.createElement(AssignmentPoints, data)
    ReactDOM.render(element, wrapper)

  buildComponent = (props, additionalProps) ->
    cellData = props || {
      columnData: { assignment: { id: '1', points_possible: 10 } }
      rowData: { student: { enrollment_state: 'active' } }
    }
    $.extend(cellData, additionalProps)
    renderComponent(cellData)

  buildComponentWithSubmission = (additionalProps, grade) ->
    props =
      cellData:  {id: '1', grade: grade, score: '10', assignment_id: '1'}
      columnData: {assignment: {id: '1', points_possible: 100}}
      rowData: { student: { enrollment_state: 'active' } }
    $.extend(props, additionalProps)
    buildComponent(props)

  TestUtils = React.addons.TestUtils
  wrapper   = document.getElementById('fixtures')

  module 'ReactGradebook.assignmentPointsComponent',
    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)

  test 'should mount', ->
    ok(buildComponent().isMounted())

  test 'should display "-" if no submission is present', ->
    grade = buildComponent().refs.grade.getDOMNode().innerHTML
    equal(grade, '-')

  test 'should display "-" if the submission grade is null', ->
    component = buildComponentWithSubmission({}, null)
    grade = component.refs.grade.getDOMNode().innerHTML
    equal(grade, '-')

  test 'should display "-/10" when first creating the submission', ->
    component = buildComponent(null, {isActiveCell: true})
    grade = component.refs.gradeInput.getDOMNode().value
    pointsPossible = component.refs.pointsPossible.getDOMNode().innerHTML

    equal(grade, '-')
    equal(pointsPossible, '10')

  test 'should display grade when submission has a grade', ->
    component = buildComponentWithSubmission({isActiveCell: true}, '10')
    grade = component.refs.gradeInput.getDOMNode().value
    pointsPossible = component.refs.pointsPossible.getDOMNode().innerHTML

    equal(grade, '10')
    equal(pointsPossible, '100')
