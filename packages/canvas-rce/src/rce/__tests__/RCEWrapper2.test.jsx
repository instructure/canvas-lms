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

import React from 'react'
import {render, waitFor} from '@testing-library/react'
import FakeEditor from './FakeEditor'
import Bridge from '../../bridge'
import * as indicateModule from '../../common/indicate'
import * as contentInsertion from '../contentInsertion'

import RCEWrapper from '../RCEWrapper'
import {jsdomInnerText} from '../../util/__tests__/jsdomInnerText'

const textareaId = 'myUniqId'
const canvasOrigin = 'https://canvas:3000'

let fakeTinyMCE, editor, rce

function createBasicElement(opts) {
  editor = new FakeEditor({id: textareaId})
  fakeTinyMCE.get = () => editor

  const props = {textareaId, tinymce: fakeTinyMCE, ...trayProps(), ...defaultProps(), ...opts}
  rce = new RCEWrapper(props)
  rce.editor = editor // usually set in onInit which isn't called when not rendered
  return rce
}

function createMountedElement(additionalProps = {}) {
  const rceRef = React.createRef()
  const container = document.getElementById('container')
  const retval = render(
    <RCEWrapper
      ref={rceRef}
      defaultContent="an example string"
      textareaId={textareaId}
      tinymce={fakeTinyMCE}
      editorOptions={{}}
      liveRegion={() => document.getElementById('flash_screenreader_holder')}
      canUploadFiles={false}
      canvasOrigin={canvasOrigin}
      {...trayProps()}
      {...additionalProps}
    />,
    {container},
  )
  rce = rceRef.current
  editor = rce.mceInstance()
  jest.spyOn(rce, 'indicateEditor').mockReturnValue(undefined)
  return retval
}

function trayProps() {
  return {
    trayProps: {
      canUploadFiles: true,
      host: 'rcs.host',
      jwt: 'donotlookatme',
      contextType: 'course',
      contextId: '17',
      containingContext: {
        userId: '1',
        contextType: 'course',
        contextId: '17',
      },
    },
  }
}

// many of the tests call `new RCEWrapper`, so there's no React
// to provide the default props
function defaultProps() {
  return {
    textareaId,
    highContrastCSS: [],
    languages: [{id: 'en', label: 'English'}],
    autosave: {enabled: false},
    ltiTools: [],
    editorOptions: {},
    liveRegion: () => document.getElementById('flash_screenreader_holder'),
    features: {},
    canvasOrigin: 'http://canvas.docker',
  }
}

describe('RCEWrapper', () => {
  // ====================
  //   SETUP & TEARDOWN
  // ====================
  beforeEach(() => {
    document.body.innerHTML = `
     <div id="flash_screenreader_holder" role="alert"/>
      <div id="app">
        <textarea id="${textareaId}"></textarea>
        <div id="container" style="width:500px;height:500px;" />
      </div>
    `
    document.documentElement.dir = 'ltr'

    fakeTinyMCE = {
      triggerSave: () => 'called',
      execCommand: () => 'command executed',
      // plugins
      create: () => {},
      PluginManager: {
        add: () => {},
      },
      plugins: {
        AccessibilityChecker: {},
      },
      get: () => editor,
    }
    global.tinymce = fakeTinyMCE
  })

  afterEach(function () {
    document.body.innerHTML = ''
    jest.restoreAllMocks()
  })

  describe('getting and setting content', () => {
    beforeEach(() => {
      createMountedElement()
    })

    it('sets code properly', () => {
      const expected = 'new content'
      jest.spyOn(rce.mceInstance(), 'setContent')
      rce.setCode(expected)
      expect(rce.mceInstance().setContent).toHaveBeenCalledWith(expected)
    })

    it('gets code properly', () => {
      rce.setCode('this is the conent')
      expect(rce.mceInstance().getContent()).toEqual(rce.getCode())
    })

    it('inserts code properly with embedded content title', () => {
      const code = '<div title="embedded content">i am new content</div>'
      jest.spyOn(contentInsertion, 'insertContent').mockImplementation(() => {})
      rce.insertCode(code)
      expect(contentInsertion.insertContent).toHaveBeenCalledWith(rce.mceInstance(), code)
    })

    it('inserts links', () => {
      const link = {}
      jest.spyOn(contentInsertion, 'insertLink').mockImplementation(() => {})
      rce.insertLink(link)
      expect(contentInsertion.insertLink).toHaveBeenCalledWith(
        rce.mceInstance(),
        link,
        canvasOrigin,
      )
    })

    it('inserts math equations', async () => {
      const tex = 'y = x^2'
      jest.spyOn(contentInsertion, 'insertEquation').mockImplementation(() => {})
      await rce.insertMathEquation(tex)
      expect(contentInsertion.insertEquation).toHaveBeenCalledWith(rce.mceInstance(), tex)
    })

    describe('checkReadyToGetCode', () => {
      it('returns true if there are no elements with data-placeholder-for attributes', () => {
        expect(rce.checkReadyToGetCode(() => {})).toEqual(true)
      })

      it('calls promptFunc if there is an element with data-placeholder-for attribute', () => {
        const placeholder = document.createElement('img')
        placeholder.setAttribute('data-placeholder-for', 'image1')
        editor.dom.doc.body.appendChild(placeholder)
        const spy = jest.fn()
        rce.checkReadyToGetCode(spy)
        expect(spy).toHaveBeenCalledWith(
          'Content is still being uploaded, if you continue it will not be embedded properly.',
        )
      })

      it('returns true if promptFunc returns true', () => {
        const placeholder = document.createElement('img')
        placeholder.setAttribute('data-placeholder-for', 'image1')
        editor.dom.doc.body.appendChild(placeholder)
        const stub = jest.fn().mockReturnValue(true)
        expect(rce.checkReadyToGetCode(stub)).toEqual(true)
      })

      it('returns false if promptFunc returns false', () => {
        const placeholder = document.createElement('img')
        placeholder.setAttribute('data-placeholder-for', 'image1')
        editor.dom.doc.body.appendChild(placeholder)
        const stub = jest.fn().mockReturnValue(false)
        expect(rce.checkReadyToGetCode(stub)).toEqual(false)
      })
    })

    describe('insertImagePlaceholder', () => {
      // Full testing of placehodlers can be found in loadingPlaceholder.test.ts

      it('can insert a placeholder', async () => {
        const square =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFElEQVR42mNk+A+ERADGUYX0VQgAXAYT9xTSUocAAAAASUVORK5CYII='
        const props = {
          name: 'square.png',
          domObject: {
            preview: square,
          },
          contentType: 'image/png',
          displayAs: 'link',
        }

        await rce.insertImagePlaceholder(props)

        const placeholderElem = rce.editor.dom.doc.querySelector(
          '*[data-placeholder-for=square\\.png]',
        )

        expect(jsdomInnerText(placeholderElem)).toContain('square.png')
      })
    })

    describe('removePlaceholders', () => {
      it('removes placeholders that match the given name', () => {
        const placeholder = document.createElement('img')
        placeholder.setAttribute('data-placeholder-for', 'image1')
        editor.dom.doc.body.appendChild(placeholder)
        rce.removePlaceholders('image1')
        expect(editor.dom.doc.querySelector(`[data-placeholder-for="image1"]`)).toBeNull()
      })

      it('does not remove placeholders that do not match the given name', () => {
        const placeholder = document.createElement('img')
        placeholder.setAttribute('data-placeholder-for', 'image1')
        const placeholder2 = document.createElement('img')
        placeholder2.setAttribute('data-placeholder-for', 'image2')
        editor.dom.doc.body.appendChild(placeholder2)
        rce.removePlaceholders('image1')
        expect(editor.dom.doc.querySelector(`[data-placeholder-for="image1"]`)).toBeNull()
        expect(editor.dom.doc.querySelector(`[data-placeholder-for="image2"]`)).toBeTruthy()
      })
    })

    describe('insert image', () => {
      it('works when no element is returned from content insertion', () => {
        jest.spyOn(contentInsertion, 'insertImage').mockImplementation(() => null)
        expect(() => rce.insertImage({})).not.toThrow()
      })

      it("removes TinyMCE's caret &nbsp; when element is returned from content insertion", () => {
        const container = document.createElement('div')
        container.innerHTML = '<div><img src="image.jpg" alt="test" />&nbsp;</div>'
        const element = container.querySelector('img')
        const removeSpy = jest.spyOn(element.nextSibling, 'remove')
        jest.spyOn(contentInsertion, 'insertImage').mockImplementation(() => element)
        rce.insertImage({})
        expect(removeSpy).toHaveBeenCalled()
      })
    })

    describe('insert media', () => {
      let insertedSpy

      beforeEach(() => {
        insertedSpy = jest.spyOn(rce, 'contentInserted')
      })

      it('inserts video', () => {
        jest.spyOn(contentInsertion, 'insertVideo').mockReturnValue('<iframe/>')
        rce.insertVideo({})
        expect(insertedSpy).toHaveBeenCalledWith('<iframe/>')
      })

      it('inserts audio', () => {
        jest.spyOn(contentInsertion, 'insertAudio').mockReturnValue('<iframe/>')
        rce.insertAudio({})
        expect(insertedSpy).toHaveBeenCalledWith('<iframe/>')
      })

      it('inserts embed code', () => {
        rce.insertEmbedCode('embed me!')
        expect(insertedSpy).toHaveBeenCalled()
      })
    })

    describe('indicator', () => {
      it('does not indicate() if editor is hidden', () => {
        const indicateDefaultStub = jest.spyOn(indicateModule, 'default')
        rce.mceInstance().hide()
        rce.indicateEditor(null)
        expect(indicateDefaultStub).not.toHaveBeenCalled()
      })

      it('waits until images are loaded to indicate', () => {
        const image = {complete: false}
        jest.spyOn(rce, 'indicateEditor')
        jest.spyOn(contentInsertion, 'insertImage').mockReturnValue(image)
        rce.insertImage(image)
        expect(rce.indicateEditor).not.toHaveBeenCalled()
        image.onload()
        expect(rce.indicateEditor).toHaveBeenCalled()
      })
    })

    describe('broken images', () => {
      it('calls checkImageLoadError when complete', async () => {
        const image = {complete: true}
        jest.spyOn(rce, 'checkImageLoadError')
        jest.spyOn(contentInsertion, 'insertImage').mockReturnValue(image)
        const result = rce.insertImage(image)
        expect(rce.checkImageLoadError).toHaveBeenCalled()

        return result.loadingPromise
      })

      it('sets an onerror handler when not complete', async () => {
        const image = {complete: false}
        jest.spyOn(rce, 'checkImageLoadError')
        jest.spyOn(contentInsertion, 'insertImage').mockReturnValue(image)
        const result = rce.insertImage(image)
        expect(typeof image.onerror).toEqual('function')
        image.onerror()
        expect(rce.checkImageLoadError).toHaveBeenCalled()

        // We need to handle the rejection by the loadingPromise, otherwise it'll cause issues in future tests
        return result.loadingPromise.catch(() => {})
      })

      describe('checkImageLoadError', () => {
        it('does not error if called without an element', () => {
          expect(() => rce.checkImageLoadError()).not.toThrow()
        })

        it('does not error if called without a non-image element', () => {
          const div = {tagName: 'DIV'}
          expect(() => rce.checkImageLoadError(div)).not.toThrow()
        })

        it('checks onload for images not done loading', async () => {
          const fakeElement = {
            complete: false,
            tagName: 'IMG',
            naturalWidth: 0,
            style: {},
          }

          rce.checkImageLoadError(fakeElement)
          expect(Object.keys(fakeElement.style)).toHaveLength(0)
          fakeElement.complete = true
          fakeElement.onload()
          await waitFor(() => {
            expect(fakeElement.style.border).toEqual('1px solid #000')
            expect(fakeElement.style.padding).toEqual('2px')
          })
        })

        it('sets the proper styles when the naturalWidth is 0', async () => {
          const fakeElement = {
            complete: true,
            tagName: 'IMG',
            naturalWidth: 0,
            style: {},
          }
          rce.checkImageLoadError(fakeElement)
          await waitFor(() => {
            expect(fakeElement.style.border).toEqual('1px solid #000')
            expect(fakeElement.style.padding).toEqual('2px')
          })
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
        insert_code: 'insertCode',
      }
      Object.keys(aliases).forEach(k => {
        const v = aliases[k]
        expect(element[v]).not.toBeNull()
        expect(element[k]).not.toBeNull()
      })
    })
  })

  describe('is_dirty()', () => {
    beforeEach(() => {
      createMountedElement()
    })

    it('is true if not hidden and defaultContent is not equal to getContent()', () => {
      expect(rce.is_dirty()).toBeFalsy()
      rce.setCode('different')
      expect(rce.is_dirty()).toBeTruthy()
    })

    it('is false if not hidden and defaultContent is equal to getContent()', () => {
      editor.hidden = false
      expect(rce.is_dirty()).toBeFalsy()
    })

    it('is true if hidden and defaultContent is not equal to textarea value', () => {
      editor.hidden = true
      document.getElementById(textareaId).value = 'different'
      expect(rce.is_dirty()).toBeTruthy()
    })

    it('is false if hidden and defaultContent is equal to textarea value', () => {
      editor.hidden = true
      expect(document.getElementById(textareaId).value).toEqual(editor.getContent())
      expect(rce.is_dirty()).toBeFalsy()
    })
  })

  describe('onFocus', () => {
    beforeEach(() => {
      jest.spyOn(Bridge, 'focusEditor')
    })

    it('calls Bridge.focusEditor with editor', () => {
      const editor_ = createBasicElement()
      editor_.handleFocus()
      expect(Bridge.focusEditor).toHaveBeenCalledWith(editor_)
    })

    it('calls props.onFocus with editor if exists', () => {
      const editor_ = createBasicElement({onFocus: jest.fn()})
      editor_.handleFocus()
      expect(editor_.props.onFocus).toHaveBeenCalledWith(editor_)
    })
  })

  describe('getResourceIdentifiers', () => {
    it('returns resourceType and resourceId', () => {
      createMountedElement({resourceType: 'assignment.body', resourceId: '156'})
      expect(rce.getResourceIdentifiers().resourceType).toEqual('assignment.body')
      expect(rce.getResourceIdentifiers().resourceId).toEqual('156')
    })
  })

  describe('onRemove', () => {
    beforeEach(() => {
      jest.spyOn(Bridge, 'detachEditor')
    })

    it('calls Bridge.detachEditor with editor', () => {
      const editor_ = createBasicElement()
      editor_.onRemove()
      expect(Bridge.detachEditor).toHaveBeenCalledWith(editor_)
    })

    it('calls props.onRemove with editor_ if exists', () => {
      const editor_ = createBasicElement({onRemove: jest.fn()})
      editor_.onRemove()
      expect(editor_.props.onRemove).toHaveBeenCalledWith(editor_)
    })
  })
})
