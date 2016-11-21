define [
  'react'
  'react-dom'
  'jquery'
  'jsx/gradebook/grid/components/column_types/assignmentPassFail'
], (React, ReactDOM, $, AssignmentPassFail) ->

  TestUtils = React.addons.TestUtils
  Simulate  = TestUtils.Simulate
  wrapper   = document.getElementById('fixtures')

  renderComponent = (submission) =>
    cellData    = {id: 1}
    data =
      cellData: cellData
      submission: submission
      rowData: {enrollment: {}}
      isActiveCell: true
    element = React.createElement(AssignmentPassFail, data)
    ReactDOM.render(element, wrapper)

  createSubmission = (score) =>
    id: 2
    assignment_id: 1
    workflow_state: 'graded'
    grade: score

  createCompleteSubmission = () =>
    createSubmission('complete')

  createIncompleteSubmission = () =>
    createSubmission('incomplete')

  module 'ReactGradebook.assignmentPassFail',
    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)

  test 'should mount', =>
    ok(renderComponent().isMounted())

  test 'should display "-" if no submission is present', =>
    grade = renderComponent().refs.grade.getDOMNode()
    grade = $(grade.innerHTML).text()
    equal(grade, '-')

  test 'should display a checkbox when the submission is complete', =>
    submission = createCompleteSubmission()
    component  = renderComponent(submission)
    element    = component.refs.grade.getDOMNode()
    ok($(element).hasClass('gradebook-checkbox-complete'))

  test 'should display an "x" for when the submission is incomplete', =>
    submission = createIncompleteSubmission()
    component  = renderComponent(submission)
    element    = component.refs.grade.getDOMNode()
    ok($(element).hasClass('gradebook-checkbox-incomplete'))

  test 'should display an empty box after clicking a submission with a null grade', =>
    component = renderComponent()
    Simulate.click(component.refs.grade.getDOMNode())
    $element = $(component.refs.grade.getDOMNode())
    ok($element.hasClass('gradebook-checkbox'))
    ok($element.hasClass('gradebook-checkbox-null'))
    ok($element.hasClass('editable'))

  test 'should display an editable checkbox after clicking a complete submission', =>
    component = renderComponent(createCompleteSubmission())
    Simulate.click(component.refs.grade.getDOMNode())
    $element = $(component.refs.grade.getDOMNode())
    ok($element.hasClass('gradebook-checkbox-complete'))
    ok($element.hasClass('editable'))

  test 'should display an editable "x" after clicking an incomplete submission', =>
    component = renderComponent(createIncompleteSubmission())
    Simulate.click(component.refs.grade.getDOMNode())
    $element = $(component.refs.grade.getDOMNode())
    ok($element.hasClass('gradebook-checkbox-incomplete'))
    ok($element.hasClass('editable'))

  test 'should change editable complete to editable incomplete submission', =>
    component = renderComponent(createCompleteSubmission())
    Simulate.click(component.refs.grade.getDOMNode())
    $element = $(component.refs.grade.getDOMNode())
    ok($element.hasClass('gradebook-checkbox-complete'))

