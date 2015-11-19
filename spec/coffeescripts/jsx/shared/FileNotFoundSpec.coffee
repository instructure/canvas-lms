define [
  'jquery',
  'react',
  'jsx/shared/FileNotFound'
], ($, React, FileNotFound) ->
  TestUtils = React.addons.TestUtils

  module 'FileNotFoundSpec',
    setup: ->
      @element = React.createElement(FileNotFound, {
        contextCode: 'fakeContextCode'
      });

  test 'it renders', ->
    rendered = TestUtils.renderIntoDocument(@element)
    ok rendered, 'the component rendered'

    React.unmountComponentAtNode(React.findDOMNode(rendered).parentNode)

