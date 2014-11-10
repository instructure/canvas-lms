define [
  'react'
  'jquery'
  'compiled/react_files/components/FileRenameForm'
  'compiled/models/Folder'
], (React, $, FileRenameForm, Folder) ->

  Simulate = React.addons.TestUtils.Simulate

  module 'FileRenameForm',
    setup: ->
      props =
        fileOptions:
          file:
            id: 999
            name: 'original_name.txt'
          name: 'options_name.txt'
      @form = React.renderComponent(FileRenameForm(props), $('<div>').appendTo('body')[0])

    teardown: ->
      #TODO: oddness with the current modal implementation makes teardown not work
      #as the DOM has been mutated. Hopefully we can ease this pain with a react modal
      #React.unmountComponentAtNode(@form.getDOMNode().parentNode)

  test 'switches to editing file name state with button click', ->
    Simulate.click(@form.refs.renameBtn.getDOMNode())
    ok(@form.state.isEditing)
    ok(@form.refs.newName.getDOMNode())

  test 'isEditing displays options name by default', ->
    Simulate.click(@form.refs.renameBtn.getDOMNode())
    ok(@form.state.isEditing)
    equal(@form.refs.newName.getDOMNode().value, 'options_name.txt'  )

  test 'isEditing displays file name when no options name exists', ->
    @form.setProps(fileOptions: {file: {name: 'file_name.md'}})
    Simulate.click(@form.refs.renameBtn.getDOMNode())
    ok(@form.state.isEditing)
    equal(@form.refs.newName.getDOMNode().value, 'file_name.md')

  test 'can go back from isEditing to initial view with button click', ->
    Simulate.click(@form.refs.renameBtn.getDOMNode())
    ok(@form.state.isEditing)
    ok(@form.refs.newName.getDOMNode())
    Simulate.click(@form.refs.backBtn.getDOMNode())
    ok(!@form.state.isEditing)
    ok(@form.refs.replaceBtn.getDOMNode())

  test 'calls passed in props method to resolve conflict', ->
    expect(2)
    @form.setProps(
      fileOptions:
        file:
          name: 'file_name.md'
      onNameConflictResolved: (options) ->
        ok(options.name)
    )
    Simulate.click(@form.refs.renameBtn.getDOMNode())
    ok(@form.state.isEditing)
    Simulate.click(@form.refs.commitChangeBtn.getDOMNode())

  test 'onNameConflicResolved preserves expandZip option when renaming', ->
    expect(2)
    @form.setProps(
      fileOptions:
        file:
          name: 'file_name.md'
        expandZip: 'true'
      onNameConflictResolved: (options) ->
        equal(options.expandZip, 'true')
    )
    Simulate.click(@form.refs.renameBtn.getDOMNode())
    ok(@form.state.isEditing)
    Simulate.click(@form.refs.commitChangeBtn.getDOMNode())

  test 'onNameConflicResolved preserves expandZip option when replacing', ->
    expect(1)
    @form.setProps(
      fileOptions:
        file:
          name: 'file_name.md'
        expandZip: 'true'
      onNameConflictResolved: (options) ->
        equal(options.expandZip, 'true')
    )
    Simulate.click(@form.refs.replaceBtn.getDOMNode())
