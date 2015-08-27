define [
  'jsx/gradebook/grid/components/dropdown_components/assignmentHeaderDropdownOptions'
  'underscore'
  'jsx/gradebook/grid/constants'
  'helpers/fakeENV'
], (DropdownOptions, _, GradebookConstants, fakeENV) ->

  wrapper = document.getElementById('fixtures')

  generateProps = (props) ->
    defaultAssignmentAttributes =
      id: 1
      html_url: 'https://example.instructure.com/courses/1/assignments/1'
      submission_types: ['online_upload']
      has_submitted_submissions: true
      submissions_downloads: 1
      speedgrader_url: '/courses/1/gradebook/speed_grader?assignment_id=1'
      muted: false
    assignmentAttributes = _.defaults(props || {}, defaultAssignmentAttributes)
    { assignment: assignmentAttributes, idAttribute: 'assignmentOptions', enrollments: [] }

  renderComponent = (data) ->
    componentFactory = React.createFactory(DropdownOptions)
    React.render(componentFactory(data), wrapper)

  buildComponent = (props) ->
    renderComponent(generateProps(props))

  module 'AssignmentHeaderDropdownOptions -- speedgrader enabled',
    setup: ->
      fakeENV.setup({ GRADEBOOK_OPTIONS: { context_id: '1', speed_grader_enabled: true } })
      GradebookConstants.refresh()
    teardown: ->
      React.unmountComponentAtNode wrapper
      fakeENV.teardown()

  test 'includes a "Download Submissions" option if there are downloadable submissions', ->
    component = buildComponent()
    ok component.refs.downloadSubmissions

  test 'does not include a "Download Submissions" option if there no downloadable submisisons', ->
    component = buildComponent({ submisison_types: ['none'], has_submitted_submissions: false })
    notOk component.refs.downloadSubmissions

  test 'includes a "Re-Upload Submissions" option if there is at least one submission download', ->
    component = buildComponent()
    ok component.refs.reuploadSubmissions

  test 'does not include a "Re-Upload Submissions" option if there are no submission downloads', ->
    component = buildComponent({ submissions_downloads: 0 })
    notOk component.refs.reuploadSubmissions

  test 'includes a "Speedgrader" option if speedgrader is enabled', ->
    component = buildComponent()
    ok component.refs.openSpeedgrader

  module 'AssignmentHeaderDropdownOptions -- speedgrader disabled',
    setup: ->
      fakeENV.setup({ GRADEBOOK_OPTIONS: { context_id: '1', speed_grader_enabled: false } })
      GradebookConstants.refresh()
    teardown: ->
      React.unmountComponentAtNode wrapper
      fakeENV.teardown()

  test 'does not include a "Speedgrader" option if speedgrader is disabled', ->
    component = buildComponent()
    notOk component.refs.openSpeedgrader
