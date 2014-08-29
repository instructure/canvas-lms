define [
  'react'
  'jquery'
  'compiled/react_files/components/RestrictedDialogForm'
  'compiled/models/Folder'
], (React, $, RestrictedDialogForm, Folder) ->

  Simulate = React.addons.TestUtils.Simulate

  module 'RestrictedDialogForm',
    setup: ->
      props =
        model: new Folder(id: 999)

      @restrictedDialogForm = React.renderComponent(RestrictedDialogForm(props), $('<div>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@restrictedDialogForm.getDOMNode().parentNode)

  test 'initialStateProperties', ->
    ok @restrictedDialogForm.state.hasOwnProperty('calendarOption')

  test '', ->
    ok @restrictedDialogForm.state.hasOwnProperty('calendarOption')

  module 'RestrictedDialogForm#initialCalendarOption',
    setup: ->
    teardown: ->

  test 'return false if models hidden property is true', ->
    props =
      model: new Folder(id: 999, hidden: true, lock_at: 'abc', unlock_at: 'abc')
    restrictedDialogForm = React.renderComponent(RestrictedDialogForm(props), $('<div>').appendTo('body')[0])

    ok !restrictedDialogForm.initialCalendarOption(), "should return false"

    React.unmountComponentAtNode(restrictedDialogForm.getDOMNode().parentNode)

  test 'return true if hidden is false and lock_at/unlock_at have something', ->
    props =
      model: new Folder(id: 999, hidden: false, lock_at: 'abc', unlock_at: 'abc')
    
    restrictedDialogForm = React.renderComponent(RestrictedDialogForm(props), $('<div>').appendTo('body')[0])
    ok restrictedDialogForm.initialCalendarOption(), "should return true"

    React.unmountComponentAtNode(restrictedDialogForm.getDOMNode().parentNode)

  test 'return false if lock_at/unlock_at and hidden are false', ->
    props =
      model: new Folder(id: 999, hidden: false, lock_at: undefined, unlock_at: undefined)
    
    restrictedDialogForm = React.renderComponent(RestrictedDialogForm(props), $('<div>').appendTo('body')[0])
    ok !restrictedDialogForm.initialCalendarOption(), "should return false"

    React.unmountComponentAtNode(restrictedDialogForm.getDOMNode().parentNode)

  module 'RestrictedDialogForm#handleSubmit',
    setup: ->
      props =
        model: new Folder(id: 999, hidden: true, lock_at: undefined, unlock_at: undefined)

      @restrictedDialogForm = React.renderComponent(RestrictedDialogForm(props), $('<div>').appendTo('body')[0])
    teardown: ->
      React.unmountComponentAtNode(@restrictedDialogForm.getDOMNode().parentNode)

  test 'calls save on the model with only hidden if calendarOption is false', ->
    sinon.spy(@restrictedDialogForm.props.model, 'save')
    Simulate.submit(@restrictedDialogForm.refs.dialogForm.getDOMNode())

    ok @restrictedDialogForm.props.model.save.calledWithMatch({}, {attrs: {hidden: true}}), 'Called save with single hidden true attribute'
    @restrictedDialogForm.props.model.save.restore()

  test 'calls save on the model with calendar should update hidden, unlock_at, lock_at and locked', 1, ->
    refs = @restrictedDialogForm.refs
    Simulate.change(refs.showCalendarInput.getDOMNode())

    refs.availableFromInput.getDOMNode().value = '123'
    refs.availableUntilInput.getDOMNode().value = '123'

    sinon.spy(@restrictedDialogForm.props.model, 'save')
    Simulate.submit(refs.dialogForm.getDOMNode())

    ok @restrictedDialogForm.props.model.save.calledWithMatch({}, {attrs: {hidden: false, lock_at: '123', unlock_at: '123', locked: false}}), 'Called save with single hidden true attribute'
    @restrictedDialogForm.props.model.save.restore()
