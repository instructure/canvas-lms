define [
  'jquery'
  'react'
  'react-dom'
  'jsx/shared/FileNotFound'
], ($, React, ReactDOM, FileNotFound) ->
  TestUtils = React.addons.TestUtils

  module 'FileNotFoundSpec',
    setup: ->
      @element = React.createElement(FileNotFound, {
        contextCode: 'fakeContextCode'
      })

  test 'it renders', ->
    rendered = TestUtils.renderIntoDocument(@element)
    ok rendered, 'the component rendered'

    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(rendered).parentNode)

