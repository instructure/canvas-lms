define [
  'jquery'
  'react'
  'react-dom'
  'compiled/models/File'
  'jsx/files/DialogPreview'
  'jsx/files/FilesystemObjectThumbnail'
], ($, React, ReactDOM, File, DialogPreview, FilesystemObjectThumbnail) ->
  TestUtils = React.addons.TestUtils

  module 'DialogPreview',
    setup: ->
    teardown: ->

  test 'DP: single item rendered with FilesystemObjectThumbnail', ->
    file = new File(name: 'Test File', thumbnail_url: 'blah')
    file.url = -> "some_url"
    fsObjStub = @stub(FilesystemObjectThumbnail.prototype, 'render').returns(React.createElement('div'))
    dialogPreview = TestUtils.renderIntoDocument(React.createElement(DialogPreview, itemsToShow: [file]))

    ok fsObjStub.calledOnce
    ReactDOM.unmountComponentAtNode(dialogPreview.getDOMNode().parentNode)

  test 'DP: multiple file items rendered in i elements', ->
    url = -> "some_url"
    file = new File(name: 'Test File', thumbnail_url: 'blah')
    file2 = new File(name: 'Test File', thumbnail_url: 'blah')

    file.url = url
    file2.url = url

    dialogPreview = TestUtils.renderIntoDocument(React.createElement(DialogPreview, itemsToShow: [file, file2]))

    equal dialogPreview.getDOMNode().getElementsByTagName('i').length, 2, "there are two files rendered"

    ReactDOM.unmountComponentAtNode(dialogPreview.getDOMNode().parentNode)
