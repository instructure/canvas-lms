define [
  'compiled/views/tinymce/InsertUpdateImageView',
  'jsx/shared/rce/loadEventListeners',
  'jquery',
  'jqueryui/tabs'
], (InsertUpdateImageView, loadEventListeners) ->
  fakeEditor = undefined

  module 'loadEventListeners',
    setup: ->
      fakeEditor = {
        id: "someId",
        bookmarkMoved: false,
        focus: (()=>),
        dom: {
          createHTML: (()=> return "<a href='#'>stub link html</a>")
        },
        selection: {
          getBookmark: (()=> {})
          moveToBookmark: (prevSelect)=>
            fakeEditor.bookmarkMoved = true
        }
      }
    teardown: ->

  asyncTest 'builds new image view on RCE event', ->
    expect(1)
    loadEventListeners((view)=>
      start()
      ok(view instanceof InsertUpdateImageView)
    )

    event = document.createEvent('CustomEvent')
    eventData = {'ed': fakeEditor, 'selectNode': "<div></div>"}
    event.initCustomEvent("tinyRCE/initImagePicker", true, true, eventData)
    document.dispatchEvent(event)
