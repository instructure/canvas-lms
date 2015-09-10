define [
  'react'
  'jsx/gradebook/grid/components/assignmentGradeCell'
  'jquery'
], (React, AssignmentGradeCell) ->

  TestUtils = React.addons.TestUtils
  wrapper   = document.getElementById('fixtures')

  renderComponent = (data) ->
    componentFactory = React.createFactory(AssignmentGradeCell)
    React.render(componentFactory(data), wrapper)

  buildComponent = (props, additionalProps) ->
    cellData = props || {cellData: {id: '1', points_possible: 10}, renderer: $.noop}
    $.extend(cellData, additionalProps)
    renderComponent(cellData)

  buildComponentWithSubmission = (additionalProps, submissionType) ->
    cellData =
      cellData: {id: '1', points_possible: 100}
      submission:
        id: '1'
        submission_type: submissionType || 'discussion_topic'
        assignment_id: '1'
        workflow_state: 'submitted'
      renderer: $.noop
    $.extend(cellData, additionalProps)
    buildComponent(cellData)

  getIconClassName = (component) ->
    component.refs.icon.getDOMNode().className

  module 'ReactGradebook.assignmentGradeCellComponent',
    teardown: ->
      React.unmountComponentAtNode(wrapper)

  test 'should mount', ->
    ok(buildComponentWithSubmission().isMounted())

  test 'should render discussion icon when submission is not graded', ->
    component = buildComponentWithSubmission()
    equal(getIconClassName(component), 'icon-discussion')

  test 'should render online-url icon when submission is not graded', ->
    component = buildComponentWithSubmission({}, 'online_url')
    equal(getIconClassName(component), 'icon-link')

  test 'should render text-url icon when submission is not graded', ->
    component = buildComponentWithSubmission({}, 'online_text_entry')
    equal(getIconClassName(component), 'icon-text')

  test 'should render online-upload icon when submission is not grade', ->
    component = buildComponentWithSubmission({}, 'online_upload')
    equal(getIconClassName(component), 'icon-document')

  test 'should render online-quiz icon when submission is not grade', ->
    component = buildComponentWithSubmission({}, 'online_quiz')
    equal(getIconClassName(component), 'icon-quiz')

  test 'should render media_recording icon when submission is not grade', ->
    component = buildComponentWithSubmission({}, 'media_recording')
    equal(getIconClassName(component), 'icon-media')
