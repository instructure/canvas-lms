define [
  'react'
  'jquery'
  'compiled/react_files/components/ProgressBar'
], (React, $, ProgressBar) ->

  module 'ProgressBar',
    setup: ->
    teardown: ->

  test 'sets width on progress bar', ->
    prog = React.renderComponent(ProgressBar(progress: 35), $('<div>').appendTo('body')[0])
    equal prog.refs.bar.getDOMNode().style.width, '35%'
    React.unmountComponentAtNode(prog.getDOMNode().parentNode)

  test 'shows indeterminate loader when progress is 100 but not yet complete', ->
    prog = React.renderComponent(ProgressBar(progress: 100), $('<div>').appendTo('body')[0])
    ok prog.refs.container.getDOMNode().className.match(/almost-done/)
    React.unmountComponentAtNode(prog.getDOMNode().parentNode)

  test 'style width value never reaches over 100%', ->
    prog = React.renderComponent(ProgressBar(progress: 200), $('<div>').appendTo('body')[0])
    equal prog.refs.bar.getDOMNode().style.width, '100%'
    React.unmountComponentAtNode(prog.getDOMNode().parentNode)

  module 'ProgressBar#barProgress',
    setup: ->
      @prog = React.renderComponent(ProgressBar(progress: 35), $('<div>').appendTo('body')[0])
    teardown: ->
      React.unmountComponentAtNode(@prog.getDOMNode().parentNode)

  test 'never returns more than 100 even if the progress is more', ->
    equal @prog.barProgress(200), 100, 'returns 100 if progress set in is over 100'
  test 'returns passed in value if less than 100', ->
    equal @prog.barProgress(45), 45, 'returns 45 if passed in value is 45'

