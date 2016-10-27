define [
  'react'
  'react-dom'
  'underscore'
  'jsx/gradebook/grid/components/column_types/teacherNote'
  'react-modal'
  'helpers/fakeENV'
  'jsx/gradebook/grid/constants'
  'compiled/gradebook2/GradebookHelpers'
], (React, ReactDOM, _, TeacherNote, Modal, fakeENV, GradebookConstants,
  GradebookHelpers) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper   = document.getElementById('fixtures')

  renderComponent = ->
    props =
      note: 'Great work!'
      userId: '1'
      studentName: 'Dora Explora'
      columnId: '1'

    componentFactory = React.createFactory(TeacherNote)
    ReactDOM.render(componentFactory(props), wrapper)

  module 'ReactGradebook.teacherNoteComponent',
    setup: ->
      fakeENV.setup()
      ENV.GRADEBOOK_OPTIONS =
        teacher_notes: { id: '1' }
        custom_column_datum_url: 'http://fakeurl.com/api/v1/courses/1/custom_gradebook_columns/:id/data/:user_id'
      GradebookConstants.refresh()
      Modal.setAppElement(wrapper)
    teardown: ->
      ReactDOM.unmountComponentAtNode(wrapper)
      fakeENV.teardown()

  test 'mounts', ->
    ok renderComponent().isMounted()

  test 'clicking on the cell causes the modal to show up', ->
    component = renderComponent()
    notOk component.state.showModal
    Simulate.click(component.refs.noteCell.getDOMNode())

    ok component.state.showModal

  test 'hiding the modal sets the content back to the original note', ->
    component = renderComponent()
    component.setState(showModal: true, content: 'Some fancy new note!')
    deepEqual component.state.content, 'Some fancy new note!'
    component.hideModal()

    deepEqual component.state.content, 'Great work!'

  test 'the modal shows the student name if Show Student Names is selected', ->
    component = renderComponent()
    component.showModal()
    notOk component.state.toolbarOptions.hideStudentNames
    title = component.refs.studentName.props.children

    deepEqual title, 'Notes for Dora Explora'

  test 'the modal hides the student name if Hide Student Names is selected', ->
    component = renderComponent()
    component.setState(showModal: true, toolbarOptions: { hideStudentNames: true })
    ok component.state.toolbarOptions.hideStudentNames
    title = component.refs.studentName.props.children

    deepEqual title, 'Notes for student (name hidden)'

  test '#updateContent shows an error message if the new content greater than the max allowed length', ->
    component = renderComponent()
    flashError = @stub($, 'flashError')
    newNote = 'a'.repeat(GradebookConstants.MAX_NOTE_LENGTH + 1)
    fakeEvent = { target: { value: newNote } }
    component.updateContent(fakeEvent)

    ok flashError.called
    deepEqual component.state.content, 'Great work!'

  test '#updateContent does not show an error message if the new content is exactly the max allowed length', ->
    component = renderComponent()
    flashError = @stub($, 'flashError')
    newNote = 'a'.repeat(GradebookConstants.MAX_NOTE_LENGTH)
    fakeEvent = { target: { value: newNote } }
    component.updateContent(fakeEvent)

    notOk flashError.called
    deepEqual component.state.content, newNote

  test '#updateContent does not show an error message if the new content is too long, but an error is already showing', ->
    component = renderComponent()
    flashError = @stub($, 'flashError')
    @stub(GradebookHelpers, 'noErrorsOnPage', -> false)
    newNote = 'a'.repeat(GradebookConstants.MAX_NOTE_LENGTH + 1)
    fakeEvent = { target: { value: newNote } }
    component.updateContent(fakeEvent)

    ok flashError.notCalled
    deepEqual component.state.content, 'Great work!'

  test '#handleSubmit makes a PUT request with the new note data', ->
    component = renderComponent()
    newNote = 'Excellent new note.'
    component.setState(content: newNote)
    ajaxJSON = @stub($, 'ajaxJSON')
    component.handleSubmit()

    deepEqual ajaxJSON.args[0][0], 'http://fakeurl.com/api/v1/courses/1/custom_gradebook_columns/1/data/1'
    deepEqual ajaxJSON.args[0][1], 'PUT'
    deepEqual ajaxJSON.args[0][2]['column_data[content]'], newNote
