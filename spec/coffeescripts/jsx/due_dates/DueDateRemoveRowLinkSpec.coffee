define [
  'react'
  'underscore'
  'jsx/due_dates/DueDateRemoveRowLink'
], (React, _, DueDateRemoveRowLink) ->

  Simulate = React.addons.TestUtils.Simulate

  module 'DueDateRemoveRowLink',
    setup: ->
      props =
        handleClick: ->

      @handleClick = @stub(props, 'handleClick')
      DueDateRemoveRowLinkElement = React.createElement(DueDateRemoveRowLink, props)
      @DueDateRemoveRowLink = React.render(DueDateRemoveRowLinkElement, $('<div>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@DueDateRemoveRowLink.getDOMNode().parentNode)

  test 'renders', ->
    ok @DueDateRemoveRowLink.isMounted()

  test 'calls handleClick prop when clicked', ->
    Simulate.click(@DueDateRemoveRowLink.refs.removeRowIcon.getDOMNode())
    ok @handleClick.calledOnce
