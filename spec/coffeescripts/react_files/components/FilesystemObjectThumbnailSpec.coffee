define [
  'react'
  'react-dom'
  'compiled/models/File'
  'compiled/models/Folder'
  'compiled/models/FilesystemObject'
  'jsx/files/FilesystemObjectThumbnail'
], (React, ReactDOM, File, Folder, FilesystemObject, FilesystemObjectThumbnail) ->

  TestUtils = React.addons.TestUtils

  module 'Filesystem Object Thumbnail: file',
    setup: ->
      file = new File(id: 65, thumbnail_url: "sweet_thumbnail_url")

      @fOT = React.createFactory(FilesystemObjectThumbnail)

      @clock = sinon.useFakeTimers()
      @thumbnail = TestUtils.renderIntoDocument(@fOT(model: file, className: "customClassname"))
      @clock.tick(20000)

    teardown: ->
      @clock.restore()
      ReactDOM.unmountComponentAtNode(@thumbnail.getDOMNode().parentNode)

  test "displays the thumbnail image", ->
    equal $(@thumbnail.getDOMNode()).attr("style"), "background-image:url('sweet_thumbnail_url');", "set background image to correct url"

  test "adds class name from props to the span", ->
    ok $(@thumbnail.getDOMNode()).hasClass("customClassname"), "finds the custom className"

  module 'Filesystem Object Thumbnail: folder',
    setup: ->
      folder = new Folder(id: 65)

      @fOT = React.createFactory(FilesystemObjectThumbnail)

      @clock = sinon.useFakeTimers()
      @thumbnail = TestUtils.renderIntoDocument(@fOT(model: folder, className: "customClassname"))
      @clock.tick(20000)

    teardown: ->
      @clock.restore()
      ReactDOM.unmountComponentAtNode(@thumbnail.getDOMNode().parentNode)

  test "adds mimeClass-Folder if it's a folder", ->
    ok $(@thumbnail.getDOMNode()).hasClass("mimeClass-folder"), "adds mimeClass for folder"

  test "adds on className to i tag if set in props", ->
    ok $(@thumbnail.getDOMNode()).hasClass("customClassname"), "finds the custom className"

  module 'Filesystem Object Thumbnail: other'

  test "adds on className to i tag if set in props", ->
    fso = new FilesystemObject(id: 65)
    fso.url = -> "foo"

    @fOT = React.createFactory(FilesystemObjectThumbnail)

    clock = sinon.useFakeTimers()
    thumbnail = TestUtils.renderIntoDocument(@fOT(model: fso, className: "customClassname"))
    clock.tick(20000)

    ok $(thumbnail.getDOMNode()).hasClass("customClassname"), "finds the custom className"

    clock.restore()
    ReactDOM.unmountComponentAtNode(thumbnail.getDOMNode().parentNode)

  module 'Filesystem Object Thumbnail: checkForThumbnail',
    setup: ->
      url = "/api/v1/files/65"
      @server = sinon.fakeServer.create()
      @server.respondWith url, [
        200
        'Content-Type': 'application/json'
        JSON.stringify {thumbnail_url: 'sweet_thumbnail_url'}
      ]

      file = new File(id: 65)

      @fOT = React.createFactory(FilesystemObjectThumbnail)

      @clock = sinon.useFakeTimers()
      @thumbnail = TestUtils.renderIntoDocument(@fOT(model: file))
      @clock.tick(20000)
      @server.respond()

    teardown: ->
      @server.restore()
      @clock.restore()
      ReactDOM.unmountComponentAtNode(@thumbnail.getDOMNode().parentNode)

  test "fetches thumbnail_url and puts it into state", ->
    @clock.tick(1000)
    ok @thumbnail.state.thumbnail_url is "sweet_thumbnail_url", "fetches and set thumbnail url into state"
