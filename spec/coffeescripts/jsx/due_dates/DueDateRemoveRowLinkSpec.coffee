define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'underscore'
  'jsx/due_dates/DueDateRemoveRowLink'
], (React, ReactDOM, {Simulate}, _, DueDateRemoveRowLink) ->

  QUnit.module 'DueDateRemoveRowLink',
    setup: ->
      props =
        handleClick: ->

      @handleClick = @stub(props, 'handleClick')
      DueDateRemoveRowLinkElement = React.createElement(DueDateRemoveRowLink, props)
      @DueDateRemoveRowLink = ReactDOM.render(DueDateRemoveRowLinkElement, $('<div>').appendTo('body')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(@DueDateRemoveRowLink.getDOMNode().parentNode)

  test 'renders', ->
    ok @DueDateRemoveRowLink.isMounted()

  test 'calls handleClick prop when clicked', ->
    Simulate.click(@DueDateRemoveRowLink.refs.removeRowIcon.getDOMNode())
    ok @handleClick.calledOnce
