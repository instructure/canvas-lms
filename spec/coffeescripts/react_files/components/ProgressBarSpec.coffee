define [
  'react'
  'jquery'
  'compiled/react_files/components/ProgressBar'
], (React, $, ProgressBar) ->

  module 'ProgressBar',
    setup: ->
    teardown: ->

  test 'sets width on progress bar', ->
    prog = React.render(ProgressBar(progress: 35), $('<div>').appendTo('body')[0])
    equal prog.refs.bar.getDOMNode().style.width, '35%'
    React.unmountComponentAtNode(prog.getDOMNode().parentNode)

  test 'shows indeterminate loader when progress is 100 but not yet complete', ->
    prog = React.render(ProgressBar(progress: 100), $('<div>').appendTo('body')[0])
    ok prog.refs.container.getDOMNode().className.match(/almost-done/)
    React.unmountComponentAtNode(prog.getDOMNode().parentNode)

  test 'style width value never reaches over 100%', ->
    prog = React.render(ProgressBar(progress: 200), $('<div>').appendTo('body')[0])
    equal prog.refs.bar.getDOMNode().style.width, '100%'
    React.unmountComponentAtNode(prog.getDOMNode().parentNode)
