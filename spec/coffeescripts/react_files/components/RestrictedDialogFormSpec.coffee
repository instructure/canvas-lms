define [
  'react'
  'jquery'
  'jsx/files/RestrictedDialogForm'
  'compiled/models/Folder'
], (React, $, RestrictedDialogForm, Folder) ->

  Simulate = React.addons.TestUtils.Simulate

  module 'RestrictedDialogForm Multiple Selected Items',
    setup: ->
      props =
        models: [new Folder(id: 1000, hidden: false), new Folder(id: 999, hidden: true)]

      @restrictedDialogForm = React.render(RestrictedDialogForm(props), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      React.unmountComponentAtNode(@restrictedDialogForm.getDOMNode().parentNode)
      $("#fixtures").empty()

  test 'button is disabled but becomes enabled when you select an item', ->
    equal @restrictedDialogForm.refs.updateBtn.props.disabled, true, 'starts off as disabled'

    @restrictedDialogForm.refs.restrictedSelection.refs.publishInput.getDOMNode().checked = true
    Simulate.change(@restrictedDialogForm.refs.restrictedSelection.refs.publishInput.getDOMNode())

    equal @restrictedDialogForm.refs.updateBtn.props.disabled, false, 'is enabled after an option is selected'

  module 'RestrictedDialogForm#handleSubmit',
    setup: ->
      props =
        models: [new Folder(id: 999, hidden: true, lock_at: undefined, unlock_at: undefined)]

      @restrictedDialogForm = React.render(RestrictedDialogForm(props), $('<div>').appendTo('#fixtures')[0])
    teardown: ->
      React.unmountComponentAtNode(@restrictedDialogForm.getDOMNode().parentNode)
      $("#fixtures").empty()

  test 'calls save on the model with only hidden if calendarOption is false', ->
    stubbedSave = @spy(@restrictedDialogForm.props.models[0], 'save')
    Simulate.submit(@restrictedDialogForm.refs.dialogForm.getDOMNode())

    ok stubbedSave.calledWithMatch({}, {attrs: {hidden: true}}), 'Called save with single hidden true attribute'

  test 'calls save on the model with calendar should update hidden, unlock_at, lock_at and locked', 1, ->
    refs = @restrictedDialogForm.refs
    Simulate.change(refs.restrictedSelection.refs.permissionsInput.getDOMNode())
    @restrictedDialogForm.refs.restrictedSelection.setState selectedOption: 'date_range'

    $(refs.restrictedSelection.refs.unlock_at.getDOMNode()).data('unfudged-date', '123')
    $(refs.restrictedSelection.refs.lock_at.getDOMNode()).data('unfudged-date', '123')

    stubbedSave = @spy(@restrictedDialogForm.props.models[0], 'save')
    Simulate.submit(refs.dialogForm.getDOMNode())

    ok stubbedSave.calledWithMatch({}, {attrs: {hidden: false, lock_at: '123', unlock_at: '123', locked: false}}), 'Called save with lock_at, unlock_at and locked attributes'
