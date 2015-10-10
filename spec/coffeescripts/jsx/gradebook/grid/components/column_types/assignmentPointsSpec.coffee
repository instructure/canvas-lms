define [
  'react'
  'jsx/gradebook/grid/components/column_types/assignmentPoints'
  'jquery'
], (React, AssignmentPoints, $) ->

  renderComponent = (data) ->
    componentFactory = React.createFactory(AssignmentPoints)
    React.render(componentFactory(data), wrapper)

  buildComponent = (props, additionalProps) ->
    cellData = props || {cellData: {id: '1', points_possible: 10}}
    $.extend(cellData, additionalProps)
    renderComponent(cellData)

  buildComponentWithSubmission = (additionalProps, grade) ->
    cellData =
      cellData: {id: '1', points_possible: 100}
      submission: {id: '1', grade: grade, score: '10',assignment_id: '1'}
    $.extend(cellData, additionalProps)
    buildComponent(cellData)

  TestUtils = React.addons.TestUtils
  wrapper   = document.getElementById('fixtures')

  module 'ReactGradebook.assignmentLetterGradeComponent',
    teardown: ->
      React.unmountComponentAtNode(wrapper)

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
