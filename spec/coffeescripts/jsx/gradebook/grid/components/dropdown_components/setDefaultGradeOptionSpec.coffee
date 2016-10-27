define [
  'react'
  'react-dom'
  'jsx/gradebook/grid/components/dropdown_components/setDefaultGradeOption',
  'compiled/gradebook2/SetDefaultGradeDialog'
], (React, ReactDOM, SetDefaultGradeOption, SetDefaultGradeDialog) ->

  wrapper = document.getElementById('fixtures')

  defaultProps = ->
    assignment: { id: '1', assignment_visibility: ['1', '2'] }
    enrollments: [
      { user: { id: '1' } },
      { user: { id: '2' } },
      { user: { id: '3' } }
    ]
    contextId: '1'

  renderComponent = ->
    props = defaultProps()
    componentFactory = React.createFactory(SetDefaultGradeOption)
    ReactDOM.render(componentFactory(props), wrapper)

  module 'SetDefaultGradeOption',
    setup: ->
      @component = renderComponent()
    teardown: ->
      $(".ui-dialog").remove()
      $("#set_default_grade_form").remove()
      $("noscript:empty").remove()
      $("div:empty:not([id])").remove()
      ReactDOM.unmountComponentAtNode wrapper

  test 'mounts on build', ->
    ok renderComponent().isMounted()

  test '#students returns the users from the enrollments', ->
    expected = [{ id: '1' }, { id: '2' }, { id: '3' }]
    actual = @component.students()
    propEqual actual, expected

  test '#studentsThatCanSeeAssignment returns users with assignment visibility', ->
    students = @component.students()
    assignment = @component.props.assignment

    expected = [{ id: '1' }, { id: '2' }]
    actual = @component.studentsThatCanSeeAssignment(students, assignment)
    propEqual actual, expected

  test '#openDialog returns a SetDefaultGradeDialog', ->
    dialog = @component.openDialog()
    ok dialog instanceof SetDefaultGradeDialog
