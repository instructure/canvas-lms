define [
  'react'
  'underscore'
  'jsx/due_dates/DueDateRemoveRowLink'
], (React, _, DueDateRemoveRowLink) ->

  Simulate = React.addons.TestUtils.Simulate

  module 'DueDateRemoveRowLink',
    setup: ->
      @sandbox = sinon.sandbox.create()
      props =
        handleClick: ->

      @handleClick = @sandbox.stub(props, 'handleClick')
      @DueDateRemoveRowLink = React.render(DueDateRemoveRowLink(props), $('<div>').appendTo('body')[0])

    teardown: ->
      @sandbox.restore()
      React.unmountComponentAtNode(@DueDateRemoveRowLink.getDOMNode().parentNode)

  test 'renders', ->
    ok @DueDateRemoveRowLink.isMounted()

  test 'calls handleClick prop when clicked', ->
    Simulate.click(@DueDateRemoveRowLink.refs.removeRowIcon.getDOMNode())
    ok @handleClick.calledOnce
