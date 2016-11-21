define [
  'react'
  'react-dom'
  'jsx/gradebook/grid/components/column_types/assignmentLetterGrade'
  'jquery'
], (React, ReactDOM, AssignmentLetterGrade, $) ->

  TestUtils = React.addons.TestUtils
  wrapper   = document.getElementById('fixtures')

  renderComponent = (data) ->
    element = React.createElement(AssignmentLetterGrade, data)
    ReactDOM.render(element, wrapper)

  buildComponent = (props, additionalProps) ->
    cellData = props || {cellData: {id: '1'}, rowData: {enrollment: {}, submissions: []}}
    $.extend(cellData, additionalProps)
    renderComponent(cellData)

  buildComponentWithSubmission = (additionalProps, grade, gradingType) ->
    cellData =
      cellData: {id: '1', grading_type: gradingType || 'letter_grade'}
      submission: {id: '1', grade: grade, score: '10',assignment_id: '1'}
      rowData: {enrollment: {}}
    $.extend(cellData, additionalProps)
    buildComponent(cellData)

  module 'ReactGradebook.assignmentLetterGradeComponent',
    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)

  test 'should mount', ->
    ok(buildComponent().isMounted())

  test 'should display "-" if no submission is present', ->
    grade = buildComponent().refs.grade.getDOMNode().innerHTML
    equal(grade, '-')

  test 'should display "-" if submission grade is null', ->
    component = buildComponentWithSubmission({}, null)
    grade = component.refs.grade.getDOMNode().innerHTML
    equal(grade, '-')

  test 'should display grade and score when assignment is a letter grade', ->
    component = buildComponentWithSubmission({}, 'A')
    elements = component.refs.grade.getDOMNode().children
    grade = elements[0].innerHTML
    score = elements[1].innerHTML

    equal(grade, 'A')
    equal(score, '10')

  test 'should display only grade when assignment is a GPA scale grade', ->
    component = buildComponentWithSubmission({}, 'A', 'gpa_scale')
    elements = component.refs.grade.getDOMNode().children
    grade = elements[0].innerHTML
    score = elements[1].innerHTML

    equal(grade, 'A')
    equal(score, '')
