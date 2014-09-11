define [
  'react'
  'jquery'
  'compiled/react_files/components/ProgressBar'
], (React, $, ProgressBar) ->

  module 'ProgressBar',
    setup: ->
      @prog = React.renderComponent(ProgressBar(progress: 35), $('<div>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@prog.getDOMNode().parentNode)

  test 'createWidthStyle returns object with correct percentage from progress', ->
    equal(@prog.createWidthStyle().width, '35%')

  test 'sets width on progress bar', ->
    equal @prog.refs.bar.getDOMNode().style.width, '35%'

  test 'shows indeterminate loader when progress is 100 but not yet complete', ->
    prog = React.renderComponent(ProgressBar(progress: 100), $('<div>').appendTo('body')[0])
    ok prog.refs.container.getDOMNode().className.match(/almost-done/)
    React.unmountComponentAtNode(prog.getDOMNode().parentNode)

