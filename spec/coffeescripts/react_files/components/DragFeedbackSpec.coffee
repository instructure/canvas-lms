define [
  'jquery'
  'react'
  'compiled/models/File'
  'jsx/files/DragFeedback'
], ($, React, File, DragFeedback) ->
  TestUtils = React.addons.TestUtils
  DragFeedback = React.createFactory DragFeedback

  module 'DragFeedback',

  test 'DF: shows a badge with number of items being dragged', ->
    file = new File(name: 'Test File', thumbnail_url: 'blah')
    file2 = new File(name: 'Test File 2', thumbnail_url: 'blah')

    file.url = -> "some_url"
    file2.url = -> "some_url"
    dragFeedback = TestUtils.renderIntoDocument(DragFeedback(pageX: 1, pageY: 1, itemsToDrag: [file, file2]))

    equal dragFeedback.getDOMNode().getElementsByClassName('badge')[0].innerHTML, "2", "has two items"
    React.unmountComponentAtNode(dragFeedback)
