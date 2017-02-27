define [
  'compiled/views/tinymce/InsertUpdateImageView',
  'jsx/shared/rce/loadEventListeners',
  'jquery',
  'jqueryui/tabs',
  'INST'
], (InsertUpdateImageView, loadEventListeners) ->
  fakeEditor = undefined

  QUnit.module 'loadEventListeners',
    setup: ->
      window.INST.maxVisibleEditorButtons = 10
      window.INST.editorButtons = [
        { id:"__BUTTON_ID__" }
      ]

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
        addCommand:(() => {}),
        addButton:(() => {})
      }

    teardown: ->
      window.alert.restore && window.alert.restore()
      console.log.restore && console.log.restore()

  asyncTest 'builds new image view on RCE event', ->
    expect(1)
    loadEventListeners({imagePickerCB: (view)=>
      start()
      ok(view instanceof InsertUpdateImageView)
    })

    event = document.createEvent('CustomEvent')
    eventData = {'ed': fakeEditor, 'selectNode': "<div></div>"}
    event.initCustomEvent("tinyRCE/initImagePicker", true, true, eventData)
    document.dispatchEvent(event)

  asyncTest 'initializes equella plugin', ->
    alertSpy = sinon.spy(window, "alert");
    expect(1)
    loadEventListeners({equellaCB:()->
      start()
      ok alertSpy.calledWith("Equella is not properly configured for this account, please notify your system administrator.")
    })

    event = document.createEvent('CustomEvent')
    eventData = {'ed': fakeEditor, 'selectNode': "<div></div>"}
    event.initCustomEvent("tinyRCE/initEquella", true, true, eventData)
    document.dispatchEvent(event)

  asyncTest 'initializes external tools plugin', ->
    commandSpy = sinon.spy(fakeEditor, "addCommand")
    expect(1)
    loadEventListeners({externalToolCB:()->
      start()
      ok commandSpy.calledWith("instructureExternalButton__BUTTON_ID__")
    })

    event = document.createEvent('CustomEvent')
    eventData = {'ed': fakeEditor, 'url': "someurl.com"}
    event.initCustomEvent("tinyRCE/initExternalTools", true, true, eventData)
    document.dispatchEvent(event)

  asyncTest 'initializes recording plugin', ->
    logSpy = sinon.spy(console, "log")
    expect(1)
    loadEventListeners({recordCB:()->
      start()
      ok logSpy.calledWith("Kaltura has not been enabled for this account")
    })

    event = document.createEvent('CustomEvent')
    eventData = {'ed': fakeEditor}
    event.initCustomEvent("tinyRCE/initRecord", true, true, eventData)
    document.dispatchEvent(event)
