define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jquery'
  'jsx/files/RestrictedRadioButtons'
  'compiled/models/Folder'
], (React, ReactDOM, {Simulate}, $, RestrictedRadioButtons, Folder) ->

  module 'RestrictedRadioButtons',
    setup: ->
      props =
        models: [new Folder(id: 999)]
        radioStateChange: sinon.stub()

      @RestrictedRadioButtons = ReactDOM.render(React.createElement(RestrictedRadioButtons, props), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(@RestrictedRadioButtons.getDOMNode().parentNode)
      $("#fixtures").empty()

  test 'renders a publish input field', ->
    ok @RestrictedRadioButtons.refs.publishInput, "should have a publish input field"

  test 'renders an unpublish input field', ->
    ok @RestrictedRadioButtons.refs.unpublishInput, "should have an unpublish input field"

  test 'renders a permissions input field', ->
    Simulate.change(@RestrictedRadioButtons.refs.permissionsInput.getDOMNode())
    ok @RestrictedRadioButtons.refs.permissionsInput, "should have an permissions input field"

  test 'renders a calendar option input field', ->
    Simulate.change(@RestrictedRadioButtons.refs.permissionsInput.getDOMNode())
    ok @RestrictedRadioButtons.refs.dateRange, "should have a dateRange input field"

  module 'RestrictedRadioButtons Multiple Selected Items',
    setup: ->
      props =
        models: [new Folder(id: 1000, hidden: false), new Folder(id: 999, hidden: true)]
        radioStateChange: sinon.stub()

      @RestrictedRadioButtons = ReactDOM.render(React.createElement(RestrictedRadioButtons, props), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(@RestrictedRadioButtons.getDOMNode().parentNode)
      $("#fixtures").empty()

  test 'defaults to having nothing selected when non common items are selected', ->
    equal @RestrictedRadioButtons.refs.publishInput.getDOMNode().checked, false, 'not selected'
    equal @RestrictedRadioButtons.refs.unpublishInput.getDOMNode().checked, false, 'not selected'
    equal @RestrictedRadioButtons.refs.permissionsInput.getDOMNode().checked, false, 'not selected'

  test 'selecting the restricted access option default checks the hiddenInput option', ->
    @RestrictedRadioButtons.refs.permissionsInput.getDOMNode().checked = true
    Simulate.change(@RestrictedRadioButtons.refs.permissionsInput.getDOMNode())

    equal @RestrictedRadioButtons.refs.link_only.props.checked, true, 'default checks hiddenInput'

  module 'RestrictedRadioButtons#extractFormValues',
    setup: ->
      props =
        models: [new Folder(id: 999)]
        radioStateChange: sinon.stub()

      @restrictedRadioButtons = ReactDOM.render(React.createElement(RestrictedRadioButtons, props), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(@restrictedRadioButtons.getDOMNode().parentNode)
      $("#fixtures").empty()

  test 'returns the correct object to publish an item', ->
    @restrictedRadioButtons.refs.publishInput.getDOMNode().checked = true
    Simulate.change(@restrictedRadioButtons.refs.publishInput .getDOMNode())

    expectedObject =
      'hidden': false
      'unlock_at': ''
      'lock_at': ''
      'locked' : false

    deepEqual @restrictedRadioButtons.extractFormValues(), expectedObject, "returns the correct object"

  test 'returns the correct object to unpublish an item', ->
    @restrictedRadioButtons.refs.unpublishInput.getDOMNode().checked = true
    Simulate.change(@restrictedRadioButtons.refs.unpublishInput .getDOMNode())

    expectedObject =
      'hidden': false
      'unlock_at': ''
      'lock_at': ''
      'locked' : true

    deepEqual @restrictedRadioButtons.extractFormValues(), expectedObject, "returns the correct object"

  test 'returns the correct object to hide an item', ->
    @restrictedRadioButtons.refs.permissionsInput.getDOMNode().checked = true
    Simulate.change(@restrictedRadioButtons.refs.permissionsInput.getDOMNode())

    expectedObject =
      'hidden': true
      'unlock_at': ''
      'lock_at': ''
      'locked' : false

    deepEqual @restrictedRadioButtons.extractFormValues(), expectedObject, "returns the correct object"

  test 'returns the correct object to restrict an item based on dates', ->
    Simulate.change(@restrictedRadioButtons.refs.permissionsInput.getDOMNode())
    Simulate.change(@restrictedRadioButtons.refs.dateRange.getDOMNode())
    @restrictedRadioButtons.refs.dateRange.getDOMNode().checked = true

    $(@restrictedRadioButtons.refs.unlock_at.getDOMNode()).data('unfudged-date', 'something else')
    $(@restrictedRadioButtons.refs.lock_at.getDOMNode()).data('unfudged-date', 'something')

    expectedObject =
      'hidden': false
      'unlock_at': 'something else'
      'lock_at': 'something'
      'locked' : false

    deepEqual @restrictedRadioButtons.extractFormValues(), expectedObject, "returns the correct object"

  module 'RestrictedRadioButtons Multiple Items',
    setup: ->
      props =
        models: [new Folder(id: 999, hidden: true, lock_at: undefined, unlock_at: undefined), new Folder(id: 1000, hidden: true, lock_at: undefined, unlock_at: undefined)]
        radioStateChange: sinon.stub()

      @restrictedRadioButtons = ReactDOM.render(React.createElement(RestrictedRadioButtons, props), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(@restrictedRadioButtons.getDOMNode().parentNode)
      $("#fixtures").empty()

  test 'commonly selected items will open the same defaulted options', ->
    equal @restrictedRadioButtons.refs.permissionsInput.props.checked, true, 'permissionsInput is checked for all of the selected items'
    equal @restrictedRadioButtons.refs.link_only.props.checked, true, 'link_only is checked for all of the selected items'
