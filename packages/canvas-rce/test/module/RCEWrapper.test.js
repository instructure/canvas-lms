/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import assert from 'assert'
import jsdomify from 'jsdomify'
import sinon from 'sinon'
import Bridge from '../../src/bridge'
import * as indicateModule from '../../src/common/indicate'
import * as contentInsertion from '../../src/rce/contentInsertion'
import RCEWrapper from '../../src/rce/RCEWrapper'

const textareaId = 'myUniqId'

let React, fakeTinyMCE, editorCommandSpy, sd, editor

// ====================
//        HELPERS
// ====================

function requireReactDeps() {
  React = require('react')
  sd = require('skin-deep')
}

function createBasicElement(opts) {
  if (opts && opts.textareaId) {
    // so RCEWrapper.mceInstance() works
    fakeTinyMCE.editors[0].id = opts.textareaId
  }
  const props = {textareaId, tinymce: fakeTinyMCE, ...trayProps(), ...opts}
  return new RCEWrapper(props)
}

function createdMountedElement(additionalProps = {}) {
  const tree = sd.shallowRender(
    React.createElement(RCEWrapper, {
      defaultContent: 'an example string',
      textareaId,
      tinymce: fakeTinyMCE,
      editorOptions: {},
      ...trayProps(),
      ...additionalProps
    })
  )
  return tree
}

function trayProps() {
  return {
    trayProps: {
      contextType: 'course',
      contextId: '17'
    }
  }
}

describe('RCEWrapper', () => {
  // ====================
  //   SETUP & TEARDOWN
  // ====================

  beforeEach(() => {
    jsdomify.create(`
      <!DOCTYPE html><html><head></head><body>
      <div id="app">
        <textarea id="${textareaId}" />
      </div>
      </body></html>
    `)
    // must create react after jsdom setup
    requireReactDeps()
    editorCommandSpy = sinon.spy()
    editor = {
      content: 'I got called with: ',
      id: textareaId,
      dom: {
        getParent: () => {
          return null
        },
        decode: input => {
          return input
        },
        doc: document.createElement('div')
      },
      selection: {
        getEnd: () => {
          return 0
        },
        getNode: () => {
          return null
        },
        getContent: () => {
          return ''
        }
      },
      insertContent: contentToInsert => {
        editor.content += contentToInsert
      },
      getContainer: () => {
        return {}
      },
      setContent: sinon.spy(c => (editor.content = c)),
      getContent: () => editor.content,
      hidden: false,
      isHidden: () => {
        return editor.hidden
      },
      execCommand: editorCommandSpy,
      serializer: {serialize: sinon.stub()},
      ui: {registry: {addIcon: () => {}}}
    }

    fakeTinyMCE = {
      triggerSave: () => 'called',
      execCommand: () => 'command executed',
      editors: [editor]
    }

    sinon.spy(editor, 'insertContent')
  })

  afterEach(() => {
    jsdomify.destroy()
  })

  // ====================
  //        TESTS
  // ====================

  describe('static methods', () => {
    describe('getByEditor', () => {
      it('gets instances by rendered tinymce object reference', () => {
        const editor = {
          ui: {registry: {addIcon: () => {}}}
        }
        const wrapper = new RCEWrapper({tinymce: fakeTinyMCE, ...trayProps()})
        const options = wrapper.wrapOptions({})
        options.setup(editor)
        assert.equal(RCEWrapper.getByEditor(editor), wrapper)
      })
    })
  })

  describe('tinyMCE instance interactions', () => {
    let element

    beforeEach(() => {
      element = createBasicElement()
    })

    it('syncs content during toggle if coming back from hidden instance', () => {
      element = createdMountedElement().getMountedInstance()
      editor.hidden = true
      document.getElementById(textareaId).value = 'Some Input HTML'
      element.toggle()
      assert.equal(element.getCode(), 'Some Input HTML')
    })

    it('calls focus on its tinyMCE instance', () => {
      element = createBasicElement({textareaId: 'myOtherUniqId'})
      element.focus()
      assert(editorCommandSpy.withArgs('mceFocus', false, 'myOtherUniqId', undefined).called)
    })

    it('resets the doc of the editor on removal', () => {
      element.destroy()
      assert(editorCommandSpy.calledWith('mceNewDocument'))
    })

    it('calls handleUnmount when destroyed', () => {
      const handleUnmount = sinon.spy()
      element = createBasicElement({handleUnmount})
      element.destroy()
      sinon.assert.called(handleUnmount)
    })

    it('doesnt reset the doc for other commands', () => {
      element.toggle()
      assert(!editorCommandSpy.calledWith('mceNewDocument'))
    })

    it('proxies hidden checks to editor', () => {
      assert.equal(element.isHidden(), false)
    })
  })

  describe('calling methods dynamically', () => {
    it('pipes arguments to specified method', () => {
      const element = createBasicElement()
      sinon.stub(element, 'set_code')
      element.call('set_code', 'new content')
      assert(element.set_code.calledWith('new content'))
    })

    it("handles 'exists?'", () => {
      const element = createBasicElement()
      sinon.stub(element, 'set_code')
      assert(element.call('exists?'))
    })
  })

  describe('getting and setting content', () => {
    let instance

    beforeEach(() => {
      instance = createdMountedElement().getMountedInstance()
      // no rce ref since it is a shallow render
      instance.refs = {}
      instance.refs.rce = {forceUpdate: () => 'no op'}
      instance.indicator = () => {}
    })

    afterEach(() => {
      editor.content = 'I got called with: '
    })

    it('sets code properly', () => {
      const expected = 'new content'
      instance.setCode(expected)
      sinon.assert.calledWith(editor.setContent, expected)
    })

    it('gets code properly', () => {
      assert.equal(editor.getContent(), instance.getCode())
    })
    it('inserts code properly', () => {
      const code = {}
      sinon.stub(contentInsertion, 'insertContent')
      instance.insertCode(code)
      assert.ok(contentInsertion.insertContent.calledWith(editor, code))
      contentInsertion.insertContent.restore()
    })

    it('inserts links', () => {
      const link = {}
      sinon.stub(contentInsertion, 'insertLink')
      instance.insertLink(link)
      assert.ok(contentInsertion.insertLink.calledWith(editor, link))
      contentInsertion.insertLink.restore()
    })

    describe('checkReadyToGetCode', () => {
      afterEach(() => {
        editor.dom.doc = document.createElement('div') // reset
      })
      it('returns true if there are no elements with data-placeholder-for attributes', () => {
        assert.ok(instance.checkReadyToGetCode(() => {}))
      })

      it('calls promptFunc if there is an element with data-placeholder-for attribute', () => {
        const placeholder = document.createElement('img')
        placeholder.setAttribute('data-placeholder-for', 'image1')
        editor.dom.doc.appendChild(placeholder)
        const spy = sinon.spy()
        instance.checkReadyToGetCode(spy)
        sinon.assert.calledWith(
          spy,
          'Content is still being uploaded, if you continue it will not be embedded properly.'
        )
      })

      it('returns true if promptFunc returns true', () => {
        const placeholder = document.createElement('img')
        placeholder.setAttribute('data-placeholder-for', 'image1')
        editor.dom.doc.appendChild(placeholder)
        const stub = sinon.stub().returns(true)
        assert.ok(instance.checkReadyToGetCode(stub))
      })

      it('returns false if promptFunc returns false', () => {
        const placeholder = document.createElement('img')
        placeholder.setAttribute('data-placeholder-for', 'image1')
        editor.dom.doc.appendChild(placeholder)
        const stub = sinon.stub().returns(false)
        assert.ok(!instance.checkReadyToGetCode(stub))
      })
    })

    describe('insertImagePlaceholder', () => {
      let globalImage
      let contentInsertionStub
      function mockImage(props) {
        // jsdom doesn't support Image
        // mock enough for RCEWrapper.insertImagePlaceholder
        globalImage = global.Image
        global.Image = function() {
          return {
            src: null,
            width: '10',
            height: '10',
            ...props
          }
        }
      }
      function restoreImage() {
        global.Image = globalImage
      }
      beforeEach(() => {
        contentInsertionStub = sinon.stub(contentInsertion, 'insertContent')
      })
      afterEach(() => {
        contentInsertion.insertContent.restore()
      })

      it('inserts a placeholder image with the proper metadata', () => {
        mockImage()
        const greenSquare =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFElEQVR42mNk+A+ERADGUYX0VQgAXAYT9xTSUocAAAAASUVORK5CYII='
        const props = {
          name: 'green_square',
          domObject: {
            preview: greenSquare
          },
          contentType: 'image/png'
        }

        const imageMarkup = `
    <div
      data-placeholder-for="green_square"
      style="width: 10px; height: 10px; border: solid 1px #8B969E; background: #c2c2c2; display:inline-block; padding:5px 0 0 5px"
    >Loading...</div>`
        instance.insertImagePlaceholder(props)
        sinon.assert.calledWith(contentInsertionStub, editor, imageMarkup)
        restoreImage()
      })

      it('resizes the placeholder image for a large, landscape image', () => {
        mockImage({width: 640, height: 200})
        const greenSquare =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFElEQVR42mNk+A+ERADGUYX0VQgAXAYT9xTSUocAAAAASUVORK5CYII='
        const props = {
          name: 'green_square',
          domObject: {
            preview: greenSquare
          },
          contentType: 'image/png'
        }

        const imageMarkup = `
    <div
      data-placeholder-for="green_square"
      style="width: 320px; height: 100px; border: solid 1px #8B969E; background: #c2c2c2; display:inline-block; padding:5px 0 0 5px"
    >Loading...</div>`
        instance.insertImagePlaceholder(props)
        sinon.assert.calledWith(contentInsertionStub, editor, imageMarkup)
        restoreImage()
      })

      it('resizes the placeholder image for a large, portrait image', () => {
        mockImage({width: 200, height: 640})
        const greenSquare =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFElEQVR42mNk+A+ERADGUYX0VQgAXAYT9xTSUocAAAAASUVORK5CYII='
        const props = {
          name: 'green_square',
          domObject: {
            preview: greenSquare
          },
          contentType: 'image/png'
        }

        const imageMarkup = `
    <div
      data-placeholder-for="green_square"
      style="width: 100px; height: 320px; border: solid 1px #8B969E; background: #c2c2c2; display:inline-block; padding:5px 0 0 5px"
    >Loading...</div>`
        instance.insertImagePlaceholder(props)
        sinon.assert.calledWith(contentInsertionStub, editor, imageMarkup)
        restoreImage()
      })

      it('inserts a text file placeholder image with the proper metadata', () => {
        const props = {
          name: 'file.txt',
          domObject: {},
          contentType: 'text/plain'
        }

        const imageMarkup = `
    <div
      data-placeholder-for="file.txt"
      style="width: 8rem; height: 1rem; border: solid 1px #8B969E; background: #c2c2c2; display:inline-block; padding:5px 0 0 5px"
    >Loading...</div>`
        instance.insertImagePlaceholder(props)
        sinon.assert.calledWith(contentInsertionStub, editor, imageMarkup)
      })

      it('inserts a video file placeholder image with the proper metadata', () => {
        const props = {
          name: 'file.mov',
          domObject: {},
          contentType: 'video/quicktime'
        }
        const imageMarkup = `
    <div
      data-placeholder-for="file.mov"
      style="width: 400px; height: 225px; border: solid 1px #8B969E; background: #c2c2c2; display:inline-block; padding:5px 0 0 5px"
    >Loading...</div>`
        instance.insertImagePlaceholder(props)
        sinon.assert.calledWith(contentInsertionStub, editor, imageMarkup)
      })

      it('inserts an audio file placeholder image with the proper metadata', () => {
        const props = {
          name: 'file.mp3',
          domObject: {},
          contentType: 'audio/mp3'
        }
        const imageMarkup = `
    <div
      data-placeholder-for="file.mp3"
      style="width: 300px; height: 2.813rem; border: solid 1px #8B969E; background: #c2c2c2; display:inline-block; padding:5px 0 0 5px"
    >Loading...</div>`
        instance.insertImagePlaceholder(props)
        sinon.assert.calledWith(contentInsertionStub, editor, imageMarkup)
      })
    })

    describe('removePlaceholders', () => {
      it('removes placeholders that match the given name', () => {
        const placeholder = document.createElement('img')
        placeholder.setAttribute('data-placeholder-for', 'image1')
        editor.dom.doc.appendChild(placeholder)
        instance.removePlaceholders('image1')
        assert.ok(!editor.dom.doc.querySelector(`[data-placeholder-for="image1"]`))
      })

      it('does not remove placeholders that do not match the given name', () => {
        const placeholder = document.createElement('img')
        placeholder.setAttribute('data-placeholder-for', 'image1')
        const placeholder2 = document.createElement('img')
        placeholder2.setAttribute('data-placeholder-for', 'image2')
        editor.dom.doc.appendChild(placeholder2)
        instance.removePlaceholders('image1')
        assert.ok(!editor.dom.doc.querySelector(`[data-placeholder-for="image1"]`))
        assert.ok(editor.dom.doc.querySelector(`[data-placeholder-for="image2"]`))
      })
    })

    describe('insert image', () => {
      it('works when no element is returned from content insertion', () => {
        sinon.stub(contentInsertion, 'insertImage').returns(null)
        instance.insertImage({})
        contentInsertion.insertImage.restore()
      })
    })

    describe('insert media', () => {
      let insertedSpy

      beforeEach(() => {
        insertedSpy = sinon.spy(instance, 'contentInserted')
      })

      afterEach(() => {
        instance.contentInserted.restore()
      })

      it('inserts video', () => {
        sinon.stub(contentInsertion, 'insertVideo').returns('<iframe/>')
        instance.insertVideo({})
        assert.equal(insertedSpy.getCall(0).args[0], '<iframe/>')
      })

      it('inserts audio', () => {
        sinon.stub(contentInsertion, 'insertAudio').returns('<iframe/>')
        instance.insertAudio({})
        assert.equal(insertedSpy.getCall(0).args[0], '<iframe/>')
      })

      it('inserts embed code', () => {
        sinon.stub(contentInsertion, 'insertContent')
        instance.insertEmbedCode('embed me!')
        assert(insertedSpy.called)
      })
    })

    describe('indicator', () => {
      it('does not indicate() if editor is hidden', () => {
        const indicateDefaultStub = sinon.stub(indicateModule, 'default')
        editor.hidden = true
        sinon.stub(instance, 'mceInstance')
        instance.mceInstance.returns(editor)
        instance.indicateEditor(null)
        assert.ok(indicateDefaultStub.neverCalledWith())
        indicateModule.default.restore()
      })

      it('waits until images are loaded to indicate', () => {
        const image = {complete: false}
        sinon.spy(instance, 'indicateEditor')
        sinon.stub(contentInsertion, 'insertImage').returns(image)
        instance.insertImage(image)
        assert.ok(instance.indicateEditor.notCalled)
        image.onload()
        assert.ok(instance.indicateEditor.called)
        contentInsertion.insertImage.restore()
      })
    })

    describe('broken images', () => {
      it('calls checkImageLoadError when complete', () => {
        const image = {complete: true}
        sinon.spy(instance, 'checkImageLoadError')
        sinon.stub(contentInsertion, 'insertImage').returns(image)
        instance.insertImage(image)
        assert.ok(instance.checkImageLoadError.called)
        instance.checkImageLoadError.restore()
        contentInsertion.insertImage.restore()
      })

      it('sets an onerror handler when not complete', () => {
        const image = {complete: false}
        sinon.spy(instance, 'checkImageLoadError')
        sinon.stub(contentInsertion, 'insertImage').returns(image)
        instance.insertImage(image)
        assert.ok(typeof image.onerror === 'function')
        image.onerror()
        assert.ok(instance.checkImageLoadError.called)
        instance.checkImageLoadError.restore()
        contentInsertion.insertImage.restore()
      })

      describe('checkImageLoadError', () => {
        it('does not error if called without an element', () => {
          instance.checkImageLoadError()
        })

        it('does not error if called without a non-image element', () => {
          const div = {tagName: 'DIV'}
          instance.checkImageLoadError(div)
        })

        it('checks onload for images not done loading', done => {
          const fakeElement = {
            complete: false,
            tagName: 'IMG',
            naturalWidth: 0,
            style: {}
          }
          instance.checkImageLoadError(fakeElement)
          assert.equal(Object.keys(fakeElement.style).length, 0)
          fakeElement.complete = true
          fakeElement.onload()
          setTimeout(() => {
            try {
              assert.ok(fakeElement.style.border === '1px solid #000')
              assert.ok(fakeElement.style.padding === '2px')
              done()
            } catch (err) {
              done(err)
            }
          }, 0)
        })

        it('sets the proper styles when the naturalWidth is 0', done => {
          const fakeElement = {
            complete: true,
            tagName: 'IMG',
            naturalWidth: 0,
            style: {}
          }
          instance.checkImageLoadError(fakeElement)
          setTimeout(() => {
            try {
              assert.ok(fakeElement.style.border === '1px solid #000')
              assert.ok(fakeElement.style.padding === '2px')
              done()
            } catch (err) {
              done(err)
            }
          }, 0)
        })
      })
    })
  })

  describe('alias functions', () => {
    it('sets aliases properly', () => {
      const element = createBasicElement()
      const aliases = {
        set_code: 'setCode',
        get_code: 'getCode',
        insert_code: 'insertCode'
      }
      Object.keys(aliases).forEach(k => {
        const v = aliases[k]
        assert(element[v], element[k])
      })
    })
  })

  describe('is_dirty()', () => {
    it('is true if not hidden and defaultContent is not equal to getConent()', () => {
      const c = createBasicElement({defaultContent: 'different'})
      editor.hidden = false
      assert(c.is_dirty())
    })

    it('is false if not hidden and defaultContent is equal to getConent()', () => {
      editor.serializer.serialize.returns(editor.content)
      const c = createBasicElement()
      editor.hidden = false
      assert(!c.is_dirty())
    })

    it('is true if hidden and defaultContent is not equal to textarea value', () => {
      const c = createBasicElement({textareaId, defaultContent: 'default'})
      editor.hidden = true
      document.getElementById(textareaId).value = 'different'
      assert(c.is_dirty())
    })

    it('is false if hidden and defaultContent is equal to textarea value', () => {
      const defaultContent = 'default content'
      editor.serializer.serialize.returns(defaultContent)
      const c = createBasicElement({textareaId, defaultContent})
      editor.hidden = true
      document.getElementById(textareaId).value = defaultContent
      assert(!c.is_dirty())
    })

    it('compares content with defaultContent serialized by editor serializer', () => {
      editor.serializer.serialize.returns(editor.content)
      const defaultContent = 'foo'
      const c = createBasicElement({defaultContent})
      editor.hidden = false
      assert(!c.is_dirty())
      sinon.assert.calledWithExactly(
        editor.serializer.serialize,
        sinon.match(
          el => el.innerHTML === defaultContent,
          `div with "${defaultContent}" as inner html`
        ),
        {getInner: true}
      )
    })
  })

  describe('onFocus', () => {
    beforeEach(() => {
      sinon.stub(Bridge, 'focusEditor')
    })

    afterEach(() => {
      Bridge.focusEditor.restore()
    })

    it('calls Bridge.focusEditor with editor', () => {
      const editor = createBasicElement()
      editor.handleFocus()
      sinon.assert.calledWith(Bridge.focusEditor, editor)
    })

    it('calls props.onFocus with editor if exists', () => {
      const editor = createBasicElement({onFocus: sinon.spy()})
      editor.handleFocus()
      sinon.assert.calledWith(editor.props.onFocus, editor)
    })
  })

  describe('onRemove', () => {
    beforeEach(() => {
      sinon.stub(Bridge, 'detachEditor')
    })

    afterEach(() => {
      Bridge.detachEditor.restore()
    })

    it('calls Bridge.detachEditor with editor', () => {
      const editor = createBasicElement()
      editor.onRemove()
      sinon.assert.calledWith(Bridge.detachEditor, editor)
    })

    it('calls props.onRemove with editor if exists', () => {
      const editor = createBasicElement({onRemove: sinon.spy()})
      editor.onRemove()
      sinon.assert.calledWith(editor.props.onRemove, editor)
    })
  })

  describe('setup option', () => {
    let editorOptions

    beforeEach(() => {
      editorOptions = {
        setup: sinon.spy(),
        other: {}
      }
    })

    it('registers editor to allow getting wrapper by editor', () => {
      const editor = {ui: {registry: {addIcon: () => {}}}}
      const tree = createdMountedElement({editorOptions})
      tree.subTree('Editor').props.init.setup(editor)
      assert.equal(RCEWrapper.getByEditor(editor), tree.getMountedInstance())
    })

    it('it calls original setup from editorOptions', () => {
      const editor = {ui: {registry: {addIcon: () => {}}}}
      const spy = editorOptions.setup
      const tree = createdMountedElement({editorOptions})
      tree.subTree('Editor').props.init.setup(editor)
      sinon.assert.calledWithExactly(spy, editor)
    })

    it('does not throw if options does not have a setup function', () => {
      delete editorOptions.setup
      createdMountedElement({editorOptions})
    })

    it('passes other options through unchanged', () => {
      const tree = createdMountedElement({editorOptions})
      tree.subTree('Editor').props.init.setup(editor)
      assert.equal(tree.subTree('Editor').props.init.other, editorOptions.other)
    })
  })

  describe('textarea', () => {
    let instance, elem

    function stubEventListeners(elem) {
      sinon.stub(elem, 'addEventListener')
      sinon.stub(elem, 'removeEventListener')
    }

    beforeEach(() => {
      instance = createBasicElement()
      elem = document.getElementById(textareaId)
      stubEventListeners(elem)
    })

    describe('handleTextareaChange', () => {
      it('updates the editor content if editor is hidden', () => {
        const value = 'foo'
        elem.value = value
        editor.hidden = true
        instance.handleTextareaChange()
        sinon.assert.calledWith(editor.setContent, value)
      })

      it('does not update the editor if editor is not hidden', () => {
        editor.hidden = false
        instance.handleTextareaChange()
        sinon.assert.notCalled(editor.setContent)
      })
    })
  })

  describe('alert area', () => {
    afterEach(() => {
      jsdomify.destroy()
    })

    it('adds an alert and attaches an id when addAlert is called', () => {
      const tree = createdMountedElement()
      const rce = tree.getMountedInstance()
      rce.resetAlertId()
      rce.addAlert({
        text: 'Something went wrong uploading, check your connection and try again.',
        variant: 'error'
      })
      assert.ok(rce.state.messages[0].id === 0)
      const alertArea = tree.dive(['AlertMessageArea'])
      const alerts = alertArea.everySubTree('Alert')
      assert.ok(alerts.length === 1)
    })

    it('adds multiple alerts', () => {
      const tree = createdMountedElement()
      const rce = tree.getMountedInstance()
      rce.resetAlertId()
      rce.addAlert({
        text: 'Something went wrong uploading, check your connection and try again.',
        variant: 'error'
      })
      rce.addAlert({
        text: 'Something went wrong uploading 2, check your connection and try again.',
        variant: 'error'
      })
      rce.addAlert({
        text: 'Something went wrong uploading 3, check your connection and try again.',
        variant: 'error'
      })
      const alertArea = tree.dive(['AlertMessageArea'])
      const alerts = alertArea.everySubTree('Alert')
      assert.ok(alerts.length === 3)
    })

    it('does not add alerts with the exact same text', () => {
      const tree = createdMountedElement()
      const rce = tree.getMountedInstance()
      rce.resetAlertId()
      rce.addAlert({
        text: 'Something went wrong uploading, check your connection and try again.',
        variant: 'error'
      })
      rce.addAlert({
        text: 'Something went wrong uploading, check your connection and try again.',
        variant: 'error'
      })
      rce.addAlert({
        text: 'Something went wrong uploading, check your connection and try again.',
        variant: 'error'
      })
      const alertArea = tree.dive(['AlertMessageArea'])
      const alerts = alertArea.everySubTree('Alert')
      assert.ok(alerts.length === 1)
    })

    it('removes an alert when removeAlert is called', () => {
      const tree = createdMountedElement()
      const rce = tree.getMountedInstance()
      rce.resetAlertId()
      rce.addAlert({
        text: 'First',
        variant: 'error'
      })
      rce.addAlert({
        text: 'Second',
        variant: 'error'
      })
      rce.addAlert({
        text: 'Third',
        variant: 'error'
      })
      rce.removeAlert(1)
      const alertArea = tree.dive(['AlertMessageArea'])
      const alerts = alertArea.everySubTree('Alert')
      assert.ok(alerts.length === 2)
    })
  })
})
