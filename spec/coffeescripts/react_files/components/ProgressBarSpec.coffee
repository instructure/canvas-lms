define [
  'react'
  'react-dom'
  'jquery'
  'jsx/shared/ProgressBar'
], (React, ReactDOM, $, ProgressBar) ->

  QUnit.module 'ProgressBar',
    setup: ->
    teardown: ->
      $("#fixtures").empty()

  test 'sets width on progress bar', ->
    prog = ReactDOM.render(React.createElement(ProgressBar, {progress: 35}), $('<div>').appendTo('#fixtures')[0])
    equal prog.refs.bar.getDOMNode().style.width, '35%'
    ReactDOM.unmountComponentAtNode(prog.getDOMNode().parentNode)

  test 'shows indeterminate loader when progress is 100 but not yet complete', ->
    prog = ReactDOM.render(React.createElement(ProgressBar, {progress: 100}), $('<div>').appendTo('#fixtures')[0])
    ok prog.refs.container.getDOMNode().className.match(/almost-done/)
    ReactDOM.unmountComponentAtNode(prog.getDOMNode().parentNode)

  test 'style width value never reaches over 100%', ->
    prog = ReactDOM.render(React.createElement(ProgressBar, {progress: 200}), $('<div>').appendTo('#fixtures')[0])
    equal prog.refs.bar.getDOMNode().style.width, '100%'
    ReactDOM.unmountComponentAtNode(prog.getDOMNode().parentNode)
