define [
  'react'
  'react-dom'
  'jsx/gradebook/grid/components/column_types/assignmentPercentage'
  'jquery'
  'jquery.ajaxJSON'
], (React, ReactDOM, AssignmentPercentage, $) ->

  TestUtils = React.addons.TestUtils
  wrapper   = document.getElementById('fixtures')

  renderComponent = (data) ->
    element = React.createElement(AssignmentPercentage, data)
    ReactDOM.render(element, wrapper)

  buildComponent = (props, additionalProps) ->
    cellData = props || {
      rowData: {
        student: {
          enrollment_state: "active"
        }
      }
    }
    $.extend(cellData, additionalProps)
    renderComponent(cellData)

  buildComponentWithSubmission = (additionalProps) ->
    cellData =
      cellData: {id: '1', grade: '100%', assignment_id: '1'}
      rowData: {
        student: {
          enrollment_state: "active"
        }
      }
    $.extend(cellData, additionalProps)
    buildComponent(cellData)

  module 'ReactGradebook.assignmentPercentageComponent',
    setup: ->
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'should mount', ->
    ok(buildComponent().isMounted())

  test 'should display "-" if no submission present"', ->
    grade = buildComponent().refs.grade.getDOMNode().innerHTML
    equal(grade, '-')

  test 'should display a grade when a submission is present', ->
    component = buildComponentWithSubmission()
    grade = component.refs.grade.getDOMNode().innerHTML
    equal(grade, '100')

  test 'should add "%" to grade when editing', ->
    component = buildComponentWithSubmission({isActiveCell: true})
    grade = component.refs.gradeInput.getDOMNode().value
    equal(grade, '100%')

  test 'should diplay a text field after clicking on the cell', ->
    component = buildComponent(null, {isActiveCell: true})
    equal(component.refs.gradeInput.getDOMNode().tagName, 'INPUT')

  test 'should select the text of the grade after click', ->
    component = buildComponentWithSubmission({isActiveCell: true})
    component.componentDidUpdate({}, {})
    grade = component.refs.gradeInput.getDOMNode().value
    equal(grade, window.getSelection().toString())

  #TODO: use squire
  #test 'should return to view state when enter is pressed when editing', ->
  #  component = buildComponentWithSubmission()
  #  Simulate.click(component.refs.grade.getDOMNode())
  #  Simulate.keyUp(component.refs.gradeInput.getDOMNode(), {key: 'Enter'})
  #  notOk(component.refs.gradeInput)
  #  ok(component.refs.grade)
