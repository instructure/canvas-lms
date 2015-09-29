define [
  'jsx/gradebook/grid/components/dropdown_components/messageStudentsWhoOption'
  'jsx/gradebook/grid/helpers/submissionsHelper'
  'jsx/gradebook/grid/helpers/messageStudentsWhoHelper'
  'timezone'
], (MessageStudentsWhoOption, SubmissionsHelper, MessageStudentsWhoHelper, tz) ->

  wrapper = document.getElementById('fixtures')

  renderComponent = ->
    assignment = { id: '1',  }
    props =
      title: 'Message Students Who...'
      assignment: assignment
      enrollments: [{ course_id: '1', user_id: '3', user: { id: '3', name: 'Dora' } }]
      submissions: {}
    componentFactory = React.createFactory(MessageStudentsWhoOption)
    React.render(componentFactory(props), wrapper)

  module 'MessageStudentsWhoOption',
    setup: ->
      @component = renderComponent()
    teardown: ->
      React.unmountComponentAtNode wrapper

  test 'mounts on build', ->
    ok renderComponent().isMounted()

  test 'openDialog calls MessageStudentsWhoHelper#settings with the correct arguments', ->
    @stub SubmissionsHelper, 'submissionsForAssignment', ->
      [{ user_id: '3', submitted_at: '2014-04-20T00:00:00Z' }]
    @stub window, 'messageStudents'
    settingsStub = @stub MessageStudentsWhoHelper, 'settings'
    @component.openDialog()
    ok settingsStub.calledOnce
    expectedStudents = [{ user_id: "3", submitted_at: tz.parse('2014-04-20T00:00:00Z'), name: "Dora" }]
    deepEqual settingsStub.args[0][0], @component.props.assignment
    deepEqual settingsStub.args[0][1], expectedStudents
