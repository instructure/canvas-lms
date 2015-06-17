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
        models: [new Folder(id: 999)]

      @restrictedDialogForm = React.render(RestrictedDialogForm(props), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      React.unmountComponentAtNode(@restrictedDialogForm.getDOMNode().parentNode)
      $("#fixtures").empty()

  test 'renders a publish input field', ->
    ok @restrictedDialogForm.refs.publishInput, "should have a publish input field"

  test 'renders an unpublish input field', ->
    ok @restrictedDialogForm.refs.unpublishInput, "should have an unpublish input field"

  test 'renders a permissions input field', ->
    Simulate.change(@restrictedDialogForm.refs.permissionsInput.getDOMNode())
    ok @restrictedDialogForm.refs.permissionsInput, "should have an permissions input field"

  test 'renders a calendar option input field', ->
    Simulate.change(@restrictedDialogForm.refs.permissionsInput.getDOMNode())
    ok @restrictedDialogForm.refs.dateRange, "should have a dateRange input field"

  module 'RestrictedDialogForm Multiple Selected Items',
    setup: ->
      props =
        models: [new Folder(id: 1000, hidden: false), new Folder(id: 999, hidden: true)]

      @restrictedDialogForm = React.render(RestrictedDialogForm(props), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      React.unmountComponentAtNode(@restrictedDialogForm.getDOMNode().parentNode)
      $("#fixtures").empty()

  test 'defaults to having nothing selected when non common items are selected', ->
    equal @restrictedDialogForm.refs.publishInput.getDOMNode().checked, false, 'not selected'
    equal @restrictedDialogForm.refs.unpublishInput.getDOMNode().checked, false, 'not selected'
    equal @restrictedDialogForm.refs.dateRange.getDOMNode().checked, false, 'not selected'

  test 'button is disabled but becomes enabled when you select an item', ->
    equal @restrictedDialogForm.refs.updateBtn.props.disabled, true, 'starts off as disabled'

    @restrictedDialogForm.refs.publishInput.getDOMNode().checked = true
    Simulate.change(@restrictedDialogForm.refs.publishInput .getDOMNode())

    equal @restrictedDialogForm.refs.updateBtn.props.disabled, false, 'is enabled after an option is selected'

  test 'selecting the restricted access option default checks the hiddenInput option', ->
    @restrictedDialogForm.refs.permissionsInput.getDOMNode().checked = true
    Simulate.change(@restrictedDialogForm.refs.permissionsInput.getDOMNode())

    equal @restrictedDialogForm.refs.link_only.props.checked, true, 'default checks hiddenInput'

  module 'RestrictedDialogForm#extractFormValues',
    setup: ->
      props =
        models: [new Folder(id: 999)]

      @restrictedDialogForm = React.render(RestrictedDialogForm(props), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      React.unmountComponentAtNode(@restrictedDialogForm.getDOMNode().parentNode)
      $("#fixtures").empty()

  test 'returns the correct object to publish an item', ->
    @restrictedDialogForm.refs.publishInput.getDOMNode().checked = true
    Simulate.change(@restrictedDialogForm.refs.publishInput .getDOMNode())

    expectedObject =
      'hidden': false
      'unlock_at': ''
      'lock_at': ''
      'locked' : false

    deepEqual @restrictedDialogForm.extractFormValues(), expectedObject, "returns the correct object"

  test 'returns the correct object to unpublish an item', ->
    @restrictedDialogForm.refs.unpublishInput.getDOMNode().checked = true
    Simulate.change(@restrictedDialogForm.refs.unpublishInput .getDOMNode())

    expectedObject =
      'hidden': false
      'unlock_at': ''
      'lock_at': ''
      'locked' : true

    deepEqual @restrictedDialogForm.extractFormValues(), expectedObject, "returns the correct object"

  test 'returns the correct object to hide an item', ->
    @restrictedDialogForm.refs.permissionsInput.getDOMNode().checked = true
    Simulate.change(@restrictedDialogForm.refs.permissionsInput.getDOMNode())

    expectedObject =
      'hidden': true
      'unlock_at': ''
      'lock_at': ''
      'locked' : false

    deepEqual @restrictedDialogForm.extractFormValues(), expectedObject, "returns the correct object"

  test 'returns the correct object to restrict an item based on dates', ->
    Simulate.change(@restrictedDialogForm.refs.permissionsInput.getDOMNode())
    Simulate.change(@restrictedDialogForm.refs.dateRange.getDOMNode())
    @restrictedDialogForm.refs.dateRange.getDOMNode().checked = true

    $(@restrictedDialogForm.refs.unlock_at.getDOMNode()).data('unfudged-date', 'something else')
    $(@restrictedDialogForm.refs.lock_at.getDOMNode()).data('unfudged-date', 'something')

    expectedObject =
      'hidden': false
      'unlock_at': 'something else'
      'lock_at': 'something'
      'locked' : false

    deepEqual @restrictedDialogForm.extractFormValues(), expectedObject, "returns the correct object"

  module 'RestrictedDialogForm#initialCalendarOption',
    setup: ->
    teardown: ->

  module 'RestrictedDialogForm#handleSubmit',
    setup: ->
      props =
        models: [new Folder(id: 999, hidden: true, lock_at: undefined, unlock_at: undefined)]

      @restrictedDialogForm = React.render(RestrictedDialogForm(props), $('<div>').appendTo('#fixtures')[0])
    teardown: ->
      React.unmountComponentAtNode(@restrictedDialogForm.getDOMNode().parentNode)
      $("#fixtures").empty()

  test 'calls save on the model with only hidden if calendarOption is false', ->
    @spy(@restrictedDialogForm.props.models[0], 'save')
    Simulate.submit(@restrictedDialogForm.refs.dialogForm.getDOMNode())

    ok @restrictedDialogForm.props.models[0].save.calledWithMatch({}, {attrs: {hidden: true}}), 'Called save with single hidden true attribute'

  test 'calls save on the model with calendar should update hidden, unlock_at, lock_at and locked', 1, ->
    refs = @restrictedDialogForm.refs
    Simulate.change(refs.permissionsInput.getDOMNode())
    @restrictedDialogForm.setState selectedOption: 'date_range'

    $(refs.unlock_at.getDOMNode()).data('unfudged-date', '123')
    $(refs.lock_at.getDOMNode()).data('unfudged-date', '123')

    stubbedSave = @spy(@restrictedDialogForm.props.models[0], 'save')
    Simulate.submit(refs.dialogForm.getDOMNode())

    ok @restrictedDialogForm.props.models[0].save.calledWithMatch({}, {attrs: {hidden: false, lock_at: '123', unlock_at: '123', locked: false}}), 'Called save with single hidden true attribute'

  module 'RestrictedDialogForm Multiple Items',
    setup: ->
      props =
        models: [new Folder(id: 999, hidden: true, lock_at: undefined, unlock_at: undefined), new Folder(id: 1000, hidden: true, lock_at: undefined, unlock_at: undefined)]
      @restrictedDialogForm = React.render(RestrictedDialogForm(props), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      React.unmountComponentAtNode(@restrictedDialogForm.getDOMNode().parentNode)
      $("#fixtures").empty()

  test 'commonly selected items will open the same defaulted options', ->
    equal @restrictedDialogForm.refs.permissionsInput.props.checked, true, 'permissionsInput is checked for all of the selected items'
    equal @restrictedDialogForm.refs.link_only.props.checked, true, 'link_only is checked for all of the selected items'
