define [
  'react'
  'react-dom'
  'underscore'
  'jsx/due_dates/DueDateRemoveRowLink'
], (React, ReactDOM, _, DueDateRemoveRowLink) ->

  Simulate = React.addons.TestUtils.Simulate

  module 'DueDateRemoveRowLink',
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
