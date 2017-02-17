define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'underscore'
  'jsx/due_dates/DueDateAddRowButton'
], (React, ReactDOM, {Simulate, SimulateNative}, _, DueDateAddRowButton) ->

  QUnit.module 'DueDateAddRowButton with true display prop',
    setup: ->
      props =
        display: true

      DueDateAddRowButtonElement = React.createElement(DueDateAddRowButton, props)
      @DueDateAddRowButton = ReactDOM.render(DueDateAddRowButtonElement, $('<div>').appendTo('body')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(@DueDateAddRowButton.getDOMNode().parentNode)

  test 'renders a button', ->
    ok @DueDateAddRowButton.isMounted()
    ok @DueDateAddRowButton.refs.addButton


  QUnit.module 'DueDateAddRowButton with false display prop',
    setup: ->
      props =
        display: false

      DueDateAddRowButtonElement = React.createElement(DueDateAddRowButton, props)
      @DueDateAddRowButton = ReactDOM.render(DueDateAddRowButtonElement, $('<div>').appendTo('body')[0])

    teardown: ->
      if @DueDateAddRowButton.getDOMNode()
        ReactDOM.unmountComponentAtNode(@DueDateAddRowButton.getDOMNode().parentNode)

  test 'does not render a button', ->
    ok @DueDateAddRowButton.isMounted()
    ok !@DueDateAddRowButton.refs.addButton
