#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'compiled/views/tinymce/EquationEditorView',
  'tinymce_plugins/instructure_links/links',
  'compiled/views/tinymce/InsertUpdateImageView',
  'jsx/shared/rce/loadEventListeners',
  'jquery',
  'jqueryui/tabs',
  'INST'
], (EquationEditorView, Links, InsertUpdateImageView, loadEventListeners) ->
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
          getNode: (()=> {})
          getContent: (()=> {})
          moveToBookmark: (prevSelect)=>
            fakeEditor.bookmarkMoved = true
        }
        addCommand:(() => {}),
        addButton:(() => {})
      }

      @dispatchEvent = (name) =>
        event = document.createEvent('CustomEvent')
        eventData = {'ed': fakeEditor, 'selectNode': "<div></div>"}
        event.initCustomEvent("tinyRCE/#{name}", true, true, eventData)
        document.dispatchEvent(event)

    teardown: ->
      window.alert.restore && window.alert.restore()
      console.log.restore && console.log.restore()

  test 'initializes equation editor plugin', (assert) ->
    done = assert.async()
    loadEventListeners({equationCB: (view) =>
      ok(view instanceof EquationEditorView)
      equal(view.$editor.selector, '#someId')
      done()
    })
    @dispatchEvent('initEquation')

  test 'initializes links plugin and renders dialog', (assert) ->
    done = assert.async()
    @stub(Links)
    loadEventListeners({linksCB: () =>
      ok(Links.renderDialog.calledWithExactly(fakeEditor))
      done()
    })
    @dispatchEvent('initLinks')

  test 'builds new image view on RCE event', (assert) ->
    done = assert.async()
    assert.expect(1)
    loadEventListeners({imagePickerCB: (view)=>
      ok(view instanceof InsertUpdateImageView)
      done()
    })

    event = document.createEvent('CustomEvent')
    eventData = {'ed': fakeEditor, 'selectNode': "<div></div>"}
    event.initCustomEvent("tinyRCE/initImagePicker", true, true, eventData)
    document.dispatchEvent(event)

  test 'initializes equella plugin', (assert) ->
    done = assert.async()
    alertSpy = sinon.spy(window, "alert");
    assert.expect(1)
    loadEventListeners({equellaCB:()->
      ok alertSpy.calledWith("Equella is not properly configured for this account, please notify your system administrator.")
      done()
    })

    event = document.createEvent('CustomEvent')
    eventData = {'ed': fakeEditor, 'selectNode': "<div></div>"}
    event.initCustomEvent("tinyRCE/initEquella", true, true, eventData)
    document.dispatchEvent(event)

  test 'initializes external tools plugin', ->
    commandSpy = sinon.spy(fakeEditor, "addCommand")
    loadEventListeners()
    event = document.createEvent('CustomEvent')
    eventData = {'ed': fakeEditor, 'url': "someurl.com"}
    event.initCustomEvent("tinyRCE/initExternalTools", true, true, eventData)
    document.dispatchEvent(event)
    ok commandSpy.calledWith("instructureExternalButton__BUTTON_ID__")

  test 'initializes recording plugin', (assert) ->
    done = assert.async()
    logSpy = sinon.spy(console, "log")
    assert.expect(1)
    loadEventListeners({recordCB:()->
      ok logSpy.calledWith("Kaltura has not been enabled for this account")
      done()
    })

    event = document.createEvent('CustomEvent')
    eventData = {'ed': fakeEditor}
    event.initCustomEvent("tinyRCE/initRecord", true, true, eventData)
    document.dispatchEvent(event)
