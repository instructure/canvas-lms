define [
  'jquery'
  'react'
  'react-dom'
  'compiled/models/File'
  'jsx/files/DragFeedback'
], ($, React, ReactDOM, File, DragFeedback) ->
  TestUtils = React.addons.TestUtils

  module 'DragFeedback'

  test 'DF: shows a badge with number of items being dragged', ->
    file = new File(id: 1, name: 'Test File', thumbnail_url: 'blah')
    file2 = new File(id: 2, name: 'Test File 2', thumbnail_url: 'blah')

    file.url = -> "some_url"
    file2.url = -> "some_url"
    dragFeedback = TestUtils.renderIntoDocument(React.createElement(DragFeedback, pageX: 1, pageY: 1, itemsToDrag: [file, file2]))

    equal dragFeedback.getDOMNode().getElementsByClassName('badge')[0].innerHTML, "2", "has two items"
    ReactDOM.unmountComponentAtNode(dragFeedback.getDOMNode().parentNode)
