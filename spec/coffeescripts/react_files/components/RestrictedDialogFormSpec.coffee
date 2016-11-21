define [
  '../mockFilesENV'
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jquery'
  'jsx/files/RestrictedDialogForm'
  'compiled/models/Folder'
], (mockFilesENV, React, ReactDOM, {Simulate}, $, RestrictedDialogForm, Folder) ->

  module 'RestrictedDialogForm Multiple Selected Items',
    setup: ->
      props =
        models: [new Folder(id: 1000, hidden: false), new Folder(id: 999, hidden: true)]

      @restrictedDialogForm = ReactDOM.render(React.createElement(RestrictedDialogForm, props), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(@restrictedDialogForm.getDOMNode().parentNode)
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

      @restrictedDialogForm = ReactDOM.render(React.createElement(RestrictedDialogForm, props), $('<div>').appendTo('#fixtures')[0])
    teardown: ->
      ReactDOM.unmountComponentAtNode(@restrictedDialogForm.getDOMNode().parentNode)
      $("#fixtures").empty()

  test 'calls save on the model with only hidden if calendarOption is false', ->
    stubbedSave = @spy(@restrictedDialogForm.props.models[0], 'save')
    Simulate.submit(@restrictedDialogForm.refs.dialogForm.getDOMNode())

    ok stubbedSave.calledWithMatch({}, {attrs: {hidden: true}}), 'Called save with single hidden true attribute'

  test 'calls save on the model with calendar should update hidden, unlock_at, lock_at and locked', 1, ->
    refs = @restrictedDialogForm.refs
    Simulate.change(refs.restrictedSelection.refs.permissionsInput.getDOMNode())
    @restrictedDialogForm.refs.restrictedSelection.setState selectedOption: 'date_range'

    startDate = new Date(2016, 5, 1)
    endDate = new Date(2016, 5, 4)
    $(refs.restrictedSelection.refs.unlock_at.getDOMNode()).data('unfudged-date', startDate)
    $(refs.restrictedSelection.refs.lock_at.getDOMNode()).data('unfudged-date', endDate)

    stubbedSave = @spy(@restrictedDialogForm.props.models[0], 'save')
    Simulate.submit(refs.dialogForm.getDOMNode())

    ok stubbedSave.calledWithMatch({}, {attrs: {hidden: false, lock_at: endDate, unlock_at: startDate, locked: false}}), 'Called save with lock_at, unlock_at and locked attributes'

  test 'accepts blank unlock_at date', ->
    refs = @restrictedDialogForm.refs
    Simulate.change(refs.restrictedSelection.refs.permissionsInput.getDOMNode())
    @restrictedDialogForm.refs.restrictedSelection.setState selectedOption: 'date_range'
    endDate = new Date(2016, 5, 4)
    $(refs.restrictedSelection.refs.unlock_at.getDOMNode()).data('unfudged-date', null)
    $(refs.restrictedSelection.refs.lock_at.getDOMNode()).data('unfudged-date', endDate)
    stubbedSave = @spy(@restrictedDialogForm.props.models[0], 'save')
    Simulate.submit(refs.dialogForm.getDOMNode())
    ok stubbedSave.calledWithMatch({}, {attrs: {hidden: false, lock_at: endDate, unlock_at: '', locked: false}}), 'Accepts blank unlock_at date'

  test 'accepts blank lock_at date', ->
    refs = @restrictedDialogForm.refs
    Simulate.change(refs.restrictedSelection.refs.permissionsInput.getDOMNode())
    @restrictedDialogForm.refs.restrictedSelection.setState selectedOption: 'date_range'
    startDate = new Date(2016, 5, 4)
    $(refs.restrictedSelection.refs.unlock_at.getDOMNode()).data('unfudged-date', startDate)
    $(refs.restrictedSelection.refs.lock_at.getDOMNode()).data('unfudged-date', null)
    stubbedSave = @spy(@restrictedDialogForm.props.models[0], 'save')
    Simulate.submit(refs.dialogForm.getDOMNode())
    ok stubbedSave.calledWithMatch({}, {attrs: {hidden: false, lock_at: '', unlock_at: startDate, locked: false}}), 'Accepts blank lock_at date'

  test 'rejects unlock_at date after lock_at date', ->
    refs = @restrictedDialogForm.refs
    Simulate.change(refs.restrictedSelection.refs.permissionsInput.getDOMNode())
    @restrictedDialogForm.refs.restrictedSelection.setState selectedOption: 'date_range'
    startDate = new Date(2016, 5, 4)
    endDate = new Date(2016, 5, 1)
    $(refs.restrictedSelection.refs.unlock_at.getDOMNode()).data('unfudged-date', startDate)
    $(refs.restrictedSelection.refs.lock_at.getDOMNode()).data('unfudged-date', endDate)
    stubbedSave = @spy(@restrictedDialogForm.props.models[0], 'save')
    Simulate.submit(refs.dialogForm.getDOMNode())
    equal stubbedSave.callCount, 0
