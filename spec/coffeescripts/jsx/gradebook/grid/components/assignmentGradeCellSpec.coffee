define [
  'react'
  'react-dom'
  'jsx/gradebook/grid/components/assignmentGradeCell'
  'underscore'
  'jsx/gradebook/grid/constants'
], (React, ReactDOM, AssignmentGradeCell, _, GradebookConstants) ->

  Simulate = React.addons.TestUtils.Simulate
  wrapper  = document.getElementById('fixtures')

  renderComponent = (props) ->
    element = React.createElement(AssignmentGradeCell, props)
    ReactDOM.render(element, wrapper)

  buildComponent = (props, additionalProps) ->
    cellData = props || {
      columnData: {
        assignment: {id: '1', points_possible: 10}
      },
      renderer: mockComponent,
      activeCell: false,
      rowData: {}
    }
    $.extend(cellData, additionalProps)
    renderComponent(cellData)

  mockComponent = React.createClass({
      render: () ->
        React.createElement('div')
  })

  buildComponentWithSubmission = (additionalProps, submissionType) ->
    cellData =
      columnData:
        assignment: {id: '1', points_possible: 100}
      cellData:
        id: '1'
        submission_type: submissionType || 'discussion_topic'
        assignment_id: '1'
        workflow_state: 'submitted'
      renderer: mockComponent
      activeCell: false
      rowData: {}
    $.extend(cellData, additionalProps)
    buildComponent(cellData)

  getIconClassName = (component) ->
    component.refs.icon.getDOMNode().className

  module 'ReactGradebook.assignmentGradeCellComponent',
    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)

  test 'should mount', ->
    ok(buildComponentWithSubmission().isMounted())

  module 'ReactGradebook.assignmentGradeCellComponent icons',
    setup: ->
      @component = buildComponentWithSubmission()
    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)

  test 'should render discussion icon when submission is not graded', ->
    expected = 'icon-discussion'
    actual = getIconClassName(@component)
    equal(actual, expected)

  test 'should render online-url icon when submission is not graded', ->
    component = buildComponentWithSubmission({}, 'online_url')
    equal(getIconClassName(component), 'icon-link')

  test 'should render text-url icon when submission is not graded', ->
    component = buildComponentWithSubmission({}, 'online_text_entry')
    equal(getIconClassName(component), 'icon-text')

  test 'should render online-upload icon when submission is not graded', ->
    component = buildComponentWithSubmission({}, 'online_upload')
    equal(getIconClassName(component), 'icon-document')

  test 'should render online-quiz icon when submission is not graded', ->
    component = buildComponentWithSubmission({}, 'online_quiz')
    equal(getIconClassName(component), 'icon-quiz')

  test 'should render media_recording icon when submission is not graded', ->
    component = buildComponentWithSubmission({}, 'media_recording')
    equal(getIconClassName(component), 'icon-media')

  test 'has "active" class when cell isActive', ->
    component = buildComponent(null, {activeCell: true})
    classList = component.refs.detailsDialog.props.className
    ok classList.indexOf('active') > -1

  test 'does not have "active" class when cell is not active', ->
    component = buildComponent()
    classList = component.refs.detailsDialog.props.className
    ok (classList.indexOf('active') == -1)

  test 'opens dialog when clicking the submissions details link', ->
    props =
      rowData:
        student:
          user:
            name: "Hello"
            id: "1"

    component = buildComponent(null, props)
    openDialogStub = @stub(component, 'openDialog', (->))
    detailsDialogLink = component.refs.detailsDialog
    Simulate.click(detailsDialogLink)
    ok openDialogStub.calledOnce
