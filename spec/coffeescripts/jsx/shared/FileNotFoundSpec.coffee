define [
  'jquery',
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/shared/FileNotFound'
], ($, React, ReactDOM, TestUtils, FileNotFound) ->

  QUnit.module 'FileNotFoundSpec',
    setup: ->
      @element = React.createElement(FileNotFound, {
        contextCode: 'fakeContextCode'
      })

  test 'it renders', ->
    rendered = TestUtils.renderIntoDocument(@element)
    ok rendered, 'the component rendered'

    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(rendered).parentNode)

