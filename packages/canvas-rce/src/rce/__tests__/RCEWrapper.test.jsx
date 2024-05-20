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

import RCEWrapper, {
  mergeMenu,
  mergeMenuItems,
  mergePlugins,
  mergeToolbar,
  parsePluginsToExclude,
} from '../RCEWrapper'
import {jsdomInnerText} from '../../util/__tests__/jsdomInnerText'

const textareaId = 'myUniqId'
const canvasOrigin = 'https://canvas:3000'

let fakeTinyMCE, editorCommandSpy, editor, rce

// ====================
//        HELPERS
// ====================

function createBasicElement(opts) {
  editor = new FakeEditor({id: textareaId})
  fakeTinyMCE.editors[0] = editor
  editorCommandSpy = jest.spyOn(editor, 'execCommand')

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
    {container}
  )
  rce = rceRef.current
  editor = rce.mceInstance()
  jest.spyOn(rce, 'indicateEditor').mockReturnValue(undefined)
  editorCommandSpy = jest.spyOn(rce.mceInstance(), 'execCommand')
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
      editors: [editor],
    }
    global.tinymce = fakeTinyMCE
  })

  afterEach(function () {
    document.body.innerHTML = ''
    jest.restoreAllMocks()
  })

  // ====================
  //        TESTS
  // ====================

  describe('static methods', () => {
    describe('getByEditor', () => {
      it('gets instances by rendered tinymce object reference', () => {
        const editor_ = {
          ui: {registry: {addIcon: () => {}}},
        }
        const wrapper = new RCEWrapper({tinymce: fakeTinyMCE, ...trayProps(), ...defaultProps()})
        const options = wrapper.wrapOptions({})
        options.setup(editor_)
        expect(RCEWrapper.getByEditor(editor_)).toBe(wrapper)
      })
    })
  })

  describe('tinyMCE instance interactions', () => {
    let element
    beforeEach(() => {
      element = createBasicElement()
    })

    it('syncs content during toggle if coming back from hidden instance', () => {
      editor.hidden = true
      document.getElementById(textareaId).value = 'Some Input HTML'
      element.toggleView()
      expect(element.getCode()).toEqual('Some Input HTML')
    })

    it('emits "ViewChange" on view changes', () => {
      const fireSpy = jest.fn()

      element.mceInstance().fire = fireSpy
      element.toggleView()

      expect(fireSpy).toHaveBeenCalledWith('ViewChange', expect.anything())
    })

    it('calls focus on its tinyMCE instance', () => {
      element = createBasicElement({textareaId: 'myOtherUniqId'})
      element.focus()
      expect(editorCommandSpy).toHaveBeenCalledWith('mceFocus', false)
    })

    it('calls handleUnmount when destroyed', () => {
      const handleUnmount = jest.fn()
      element = createBasicElement({handleUnmount})
      element.destroy()
      expect(handleUnmount).toHaveBeenCalled()
    })

    it("doesn't reset the doc for other commands", () => {
      element.toggleView()
      expect(editorCommandSpy).not.toHaveBeenCalledWith('mceNewDocument', expect.anything())
    })

    it('proxies hidden checks to editor', () => {
      expect(element.isHidden()).toBeFalsy()
    })
  })

  describe('calling methods dynamically', () => {
    it('pipes arguments to specified method', () => {
      const element = createBasicElement()
      jest.spyOn(element, 'set_code')
      element.call('set_code', 'new content')
      expect(element.set_code).toHaveBeenCalledWith('new content')
    })

    it("handles 'exists?'", () => {
      const element = createBasicElement()
      jest.spyOn(element, 'set_code')
      expect(element.call('exists?')).toBeTruthy()
    })
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

    it('inserts code properly', () => {
      const code = '<div>i am new content</div>'
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
        canvasOrigin
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
          'Content is still being uploaded, if you continue it will not be embedded properly.'
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
          '*[data-placeholder-for=square\\.png]'
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
          expect(Object.keys(fakeElement.style).length).toEqual(0)
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

  describe('setup option', () => {
    let editorOptions

    beforeEach(() => {
      editorOptions = {
        setup: jest.fn(),
        other: {},
      }
    })

    it('registers editor to allow getting wrapper by editor', () => {
      createMountedElement({editorOptions})
      const rce1 = rce
      createMountedElement({editorOptions}, {textareaId: 'rce1'})
      const rce2 = rce

      expect(RCEWrapper.getByEditor(rce1.mceInstance())).toBe(rce1)
      expect(RCEWrapper.getByEditor(rce2.mceInstance())).toBe(rce2)
    })

    it('it calls original setup from editorOptions', () => {
      createMountedElement({editorOptions})
      expect(editorOptions.setup).toHaveBeenCalledWith(rce.mceInstance())
    })

    it('does not throw if options does not have a setup function', () => {
      delete editorOptions.setup
      expect(() => createMountedElement({editorOptions})).not.toThrow()
    })

    it('passes other options through unchanged', () => {
      createMountedElement({editorOptions})
      expect(rce.mceInstance().props.init.other).toBe(editorOptions.other)
    })
  })

  describe('textarea', () => {
    let instance, elem

    function stubEventListeners(elm) {
      jest.spyOn(elm, 'addEventListener').mockImplementation(() => {})
      jest.spyOn(elm, 'removeEventListener').mockImplementation(() => {})
    }

    beforeEach(() => {
      instance = createBasicElement()
      elem = document.getElementById(textareaId)
      stubEventListeners(elem)
      jest.spyOn(instance, 'doAutoSave').mockImplementation(() => {})
      jest.spyOn(editor, 'setContent')
    })

    describe('handleTextareaChange', () => {
      it('updates the editor content if editor is hidden', () => {
        const value = 'foo'
        elem.value = value
        editor.hidden = true
        instance.handleTextareaChange()
        expect(editor.setContent).toHaveBeenCalledWith(value)
        expect(instance.doAutoSave).toHaveBeenCalled()
      })

      it('does not update the editor if editor is not hidden', () => {
        editor.hidden = false
        instance.handleTextareaChange()
        expect(editor.setContent).not.toHaveBeenCalled()
        expect(instance.doAutoSave).not.toHaveBeenCalled()
      })
    })
  })

  describe('alert area', () => {
    it('adds an alert when addAlert is called', () => {
      const alertmsg = 'Something went wrong uploading, check your connection and try again.'
      const {getByText} = createMountedElement()
      rce.addAlert({
        text: alertmsg,
        variant: 'error',
      })
      expect(getByText(alertmsg)).toBeInTheDocument()
    })

    it('adds multiple alerts', () => {
      const alertmsg1 = 'Something went wrong uploading, check your connection and try again.'
      const alertmsg2 = 'Something went wrong uploading 2, check your connection and try again.'
      const alertmsg3 = 'Something went wrong uploading 3, check your connection and try again.'
      const {getByText} = createMountedElement()
      rce.resetAlertId()
      rce.addAlert({
        text: alertmsg1,
        variant: 'error',
      })
      rce.addAlert({
        text: alertmsg2,
        variant: 'error',
      })
      rce.addAlert({
        text: alertmsg3,
        variant: 'error',
      })
      expect(getByText(alertmsg1)).toBeInTheDocument()
      expect(getByText(alertmsg2)).toBeInTheDocument()
      expect(getByText(alertmsg3)).toBeInTheDocument()
    })

    it('does not add alerts with the exact same text', () => {
      const alertmsg1 = 'Something went wrong uploading, check your connection and try again.'
      const {getAllByText} = createMountedElement()
      rce.resetAlertId()
      rce.addAlert({
        text: alertmsg1,
        variant: 'error',
      })
      rce.addAlert({
        text: alertmsg1,
        variant: 'error',
      })
      rce.addAlert({
        text: alertmsg1,
        variant: 'error',
      })
      expect(getAllByText(alertmsg1).length).toEqual(1)
    })

    it('removes an alert when removeAlert is called', () => {
      const {queryByText} = createMountedElement()
      rce.resetAlertId()
      rce.addAlert({
        text: 'First',
        variant: 'error',
      })
      rce.addAlert({
        text: 'Second',
        variant: 'error',
      })
      rce.addAlert({
        text: 'Third',
        variant: 'error',
      })
      expect(queryByText('First')).toBeInTheDocument()
      expect(queryByText('Second')).toBeInTheDocument()
      expect(queryByText('Third')).toBeInTheDocument()
      rce.removeAlert(1)
      expect(queryByText('First')).toBeInTheDocument()
      expect(queryByText('Second')).toBeNull()
      expect(queryByText('Third')).toBeInTheDocument()
    })
  })

  describe('wrapOptions', () => {
    it('includes instructure_record in plugins if not instRecordDisabled', () => {
      const wrapper = createBasicElement({instRecordDisabled: false})
      const options = wrapper.wrapOptions({})
      expect(options.plugins.indexOf('instructure_record')).toBeGreaterThan(0)
    })

    it('instructure_record not in plugins if instRecordDisabled is set', () => {
      const wrapper = createBasicElement({instRecordDisabled: true})
      const options = wrapper.wrapOptions({})
      expect(options.plugins.indexOf('instructure_record')).toEqual(-1)
    })
  })

  describe('Extending the toolbar and menus', () => {
    const sleazyDeepCopy = a => JSON.parse(JSON.stringify(a))

    describe('mergeMenuItems', () => {
      it('returns input if no custom commands are provided', () => {
        const a = 'foo bar | baz'
        const c = mergeMenuItems(a)
        expect(c).toStrictEqual(a)
      })

      it('merges 2 lists of commands', () => {
        const a = 'foo bar | baz'
        const b = 'fizz buzz'
        const c = mergeMenuItems(a, b)
        expect(c).toStrictEqual('foo bar | baz | fizz buzz')
      })

      it('respects the | grouping separator', () => {
        const a = 'foo bar | baz'
        const b = 'fizz | buzz'
        const c = mergeMenuItems(a, b)
        expect(c).toStrictEqual('foo bar | baz | fizz | buzz')
      })

      it('removes duplicates and strips trailing |', () => {
        const a = 'foo bar | baz'
        const b = 'fizz buzz | baz'
        const c = mergeMenuItems(a, b)
        expect(c).toStrictEqual('foo bar | baz | fizz buzz')
      })

      it('removes duplicates and strips leading |', () => {
        const a = 'foo bar | baz'
        const b = 'baz | fizz buzz '
        const c = mergeMenuItems(a, b)
        expect(c).toStrictEqual('foo bar | baz | fizz buzz')
      })
    })

    describe('mergeMenus', () => {
      let standardMenu
      beforeEach(() => {
        standardMenu = {
          format: {
            items: 'bold italic underline | removeformat',
            title: 'Format',
          },
          insert: {
            items: 'instructure_links | inserttable instructure_media_embed | hr',
            title: 'Insert',
          },
          tools: {
            items: 'instructure_wordcount',
            title: 'Tools',
          },
        }
      })
      it('returns input if no custom menus are provided', () => {
        const a = sleazyDeepCopy(standardMenu)
        expect(mergeMenu(a)).toStrictEqual(standardMenu)
      })

      it('merges items into an existing menu', () => {
        const a = sleazyDeepCopy(standardMenu)
        const b = {
          tools: {
            items: 'foo bar',
          },
        }
        const result = sleazyDeepCopy(standardMenu)
        result.tools.items = 'instructure_wordcount | foo bar'
        expect(mergeMenu(a, b)).toStrictEqual(result)
      })

      it('adds a new menu', () => {
        const a = sleazyDeepCopy(standardMenu)
        const b = {
          new_menu: {
            title: 'New Menu',
            items: 'foo bar',
          },
        }
        const result = sleazyDeepCopy(standardMenu)
        result.new_menu = {
          items: 'foo bar',
          title: 'New Menu',
        }
        expect(mergeMenu(a, b)).toStrictEqual(result)
      })

      it('merges items _and_ adds a new menu', () => {
        const a = sleazyDeepCopy(standardMenu)
        const b = {
          tools: {
            items: 'foo bar',
          },
          new_menu: {
            title: 'New Menu',
            items: 'foo bar',
          },
        }
        const result = sleazyDeepCopy(standardMenu)
        result.tools.items = 'instructure_wordcount | foo bar'
        result.new_menu = {
          items: 'foo bar',
          title: 'New Menu',
        }
        expect(mergeMenu(a, b)).toStrictEqual(result)
      })
    })

    describe('mergeToolbar', () => {
      let standardToolbar
      beforeEach(() => {
        standardToolbar = [
          {
            items: ['fontsizeselect', 'formatselect'],
            name: 'Styles',
          },
          {
            items: ['bold', 'italic', 'underline'],
            name: 'Formatting',
          },
        ]
      })

      it('returns input if no custom toolbars are provided', () => {
        const a = sleazyDeepCopy(standardToolbar)
        expect(mergeToolbar(a)).toStrictEqual(standardToolbar)
      })

      it('merges items into the toolbar', () => {
        const a = sleazyDeepCopy(standardToolbar)
        const b = [
          {
            name: 'Formatting',
            items: ['foo', 'bar'],
          },
        ]
        const result = sleazyDeepCopy(standardToolbar)
        result[1].items = ['bold', 'italic', 'underline', 'foo', 'bar']
        expect(mergeToolbar(a, b)).toStrictEqual(result)
      })

      it('adds a new toolbar if necessary', () => {
        const a = sleazyDeepCopy(standardToolbar)
        const b = [
          {
            name: 'I Am New',
            items: ['foo', 'bar'],
          },
        ]
        const result = sleazyDeepCopy(standardToolbar)
        result[2] = {
          items: ['foo', 'bar'],
          name: 'I Am New',
        }
        expect(mergeToolbar(a, b)).toStrictEqual(result)
      })

      it('merges toolbars and adds a new one', () => {
        const a = sleazyDeepCopy(standardToolbar)
        const b = [
          {
            name: 'Formatting',
            items: ['foo', 'bar'],
          },
          {
            name: 'I Am New',
            items: ['foo', 'bar'],
          },
        ]
        const result = sleazyDeepCopy(standardToolbar)
        result[1].items = ['bold', 'italic', 'underline', 'foo', 'bar']
        result[2] = {
          items: ['foo', 'bar'],
          name: 'I Am New',
        }
        expect(mergeToolbar(a, b)).toStrictEqual(result)
      })
    })

    describe('mergePlugins', () => {
      let standardPlugins
      beforeEach(() => {
        standardPlugins = ['foo', 'bar', 'baz']
      })

      it('returns input if no custom or excluded plugins are provided', () => {
        const standard = sleazyDeepCopy(standardPlugins)
        expect(mergePlugins(standard)).toStrictEqual(standard)
      })

      it('merges items into the plugins', () => {
        const standard = sleazyDeepCopy(standardPlugins)
        const custom = ['fizz', 'buzz']
        const result = standardPlugins.concat(custom)
        expect(mergePlugins(standard, custom)).toStrictEqual(result)
      })

      it('removes duplicates', () => {
        const standard = sleazyDeepCopy(standardPlugins)
        const custom = ['foo', 'fizz']
        const result = standardPlugins.concat(['fizz'])
        expect(mergePlugins(standard, custom)).toStrictEqual(result)
      })

      it('removes plugins marked to exlude', () => {
        const standard = sleazyDeepCopy(standardPlugins)
        const custom = ['foo', 'fizz']
        const exclusions = ['fizz', 'baz']
        const result = ['foo', 'bar']
        expect(mergePlugins(standard, custom, exclusions)).toStrictEqual(result)
      })
    })

    describe('configures menus', () => {
      it('includes instructure_media in plugins if not instRecordDisabled', () => {
        const instance = createBasicElement({instRecordDisabled: false})
        expect(instance.tinymceInitOptions.plugins.includes('instructure_record')).toBeTruthy()
      })

      it('removes instructure_media from plugins if instRecordDisabled is set', () => {
        const instance = createBasicElement({instRecordDisabled: true})
        expect(instance.tinymceInitOptions.plugins.includes('instructure_record')).toBeFalsy()
      })
    })

    describe('parsePluginsToExclude', () => {
      it('returns cleaned versions of plugins prefixed with a hyphen', () => {
        const plugins = ['-abc', 'def', '-ghi', 'jkl']
        const result = ['abc', 'ghi']
        expect(parsePluginsToExclude(plugins)).toStrictEqual(result)
      })
    })
  })

  describe('lti tools for toolbar', () => {
    it('extracts favorites', () => {
      const element = createBasicElement({
        ltiTools: [
          {
            canvas_icon_class: null,
            description: 'the thing',
            favorite: true,
            height: 160,
            id: 1,
            name: 'A Tool',
            width: 340,
          },
          {
            canvas_icon_class: null,
            description: 'another thing',
            favorite: false,
            height: 600,
            id: 2,
            name: 'Not a favorite tool',
            width: 560,
          },
          {
            canvas_icon_class: null,
            description: 'another thing',
            favorite: true,
            height: 600,
            id: 3,
            name: 'Another Tool',
            width: 560,
          },
          {
            canvas_icon_class: null,
            description: 'yet another thing',
            favorite: true,
            height: 600,
            id: 4,
            name: 'Yet Another Tool',
            width: 560,
          },
        ],
      })

      expect(element.ltiToolFavorites).toStrictEqual([
        'instructure_external_button_1',
        'instructure_external_button_3',
      ])
    })

    it('extracts always_on tools', () => {
      const element = createBasicElement({
        ltiTools: [
          {
            canvas_icon_class: null,
            description: 'first',
            favorite: false,
            height: 160,
            width: 340,
            id: 1,
            name: 'An Always On Tool',
            always_on: true,
          },
          {
            canvas_icon_class: null,
            description: 'the thing',
            favorite: true,
            height: 160,
            id: 2,
            name: 'A Tool',
            width: 340,
            always_on: false,
          },
          {
            canvas_icon_class: null,
            description: 'other thing',
            favorite: true,
            height: 160,
            id: 3,
            name: 'A Tool',
            always_on: true,
          },
        ],
      })

      // The order here is important, as the always on tools should be at the beginning!
      expect(element.ltiToolFavorites).toStrictEqual([
        'instructure_external_button_1',
        'instructure_external_button_3',
        'instructure_external_button_2',
      ])
    })
  })

  describe('limit the number or RCEs fully rendered on page load', () => {
    let ReactDOM

    function renderAnotherRCE(callback, additionalProps = {}) {
      ReactDOM.render(
        <RCEWrapper
          textareaId={textareaId}
          tinymce={fakeTinyMCE}
          editorOptions={{}}
          liveRegion={() => document.getElementById('flash_screenreader_holder')}
          canUploadFiles={false}
          canvasOrigin={canvasOrigin}
          {...trayProps()}
          {...additionalProps}
        />,
        document.getElementById('here'),
        callback
      )
    }
    beforeAll(() => {
      ReactDOM = require('react-dom')

      if (!('IntersectionObserver' in window)) {
        window.IntersectionObserver = function () {
          return {
            observe: () => {},
            disconnect: () => {},
          }
        }
      }
    })
    beforeEach(() => {
      document.getElementById('app').innerHTML = `
      <div class='rce-wrapper'>faux rendered rce</div>
      <div class='rce-wrapper'>faux rendered rce</div>
      <div id="here"/>
    `
    })

    it('renders them all if no max is set', done => {
      renderAnotherRCE(() => {
        expect(document.querySelectorAll('.rce-wrapper').length).toEqual(3)
        done()
      })
    })

    it('renders them all if maxInitRenderedRCEs is <0', done => {
      renderAnotherRCE(
        () => {
          expect(document.querySelectorAll('.rce-wrapper').length).toEqual(3)
          done()
        },
        {maxInitRenderedRCEs: -1}
      )
    })

    it('limits them to maxInitRenderedRCEs value', done => {
      renderAnotherRCE(
        () => {
          expect(document.querySelectorAll('.rce-wrapper').length).toEqual(2)
          done()
        },
        {maxInitRenderedRCEs: 2}
      )
    })

    it('copes with missing IntersectionObserver', done => {
      delete window.IntersectionObserver

      renderAnotherRCE(
        () => {
          expect(document.querySelectorAll('.rce-wrapper').length).toEqual(3)
          done()
        },
        {maxInitRenderedRCEs: 2}
      )
    })
  })

  describe('feature flags', () => {
    describe('rce_transform_loaded_content', () => {
      const encodeHTML = html => {
        const e = document.createElement('div')
        e.textContent = html
        return e.innerHTML
      }
      const exampleUrlsWithoutOrigin = [
        // basic example
        '/some/path',

        // basic example with query
        '/some/path?query=string&another=string',

        // basic example with query and hash
        '/some/path?query=string#hash',

        // This contains characters from different languages, in the path, query, and hash
        '/somewhere%20neat/%E6%9F%90%E5%A4%84/%E0%A4%95%E0%A4%B9%E0%A5%80%E0%A4%82?%D0%BA%D0%BB%D1%8E%D1%87=%D1%86%D0%B5%D0%BD%D0%B8%D1%82%D1%8C&eochair+eile=#Um%20lugar%20especial%20na%20p%C3%A1gina',
      ]

      // Note: template strings aren't used here because these values are whitespace-sensitive
      const contentWithAbsoluteUrls = exampleUrlsWithoutOrigin
        .map(it => encodeHTML(it))
        .flatMap(urlWithoutOrigin => [
          `<img src="http://example.com${urlWithoutOrigin}">`,
          `<iframe src="http://example.com${urlWithoutOrigin}"></iframe>`,
          `<img src="http://example2.com${urlWithoutOrigin}">`,
          `<iframe src="http://example2.com${urlWithoutOrigin}"></iframe>`,
        ])
        .join(``)

      const contentWithRelativeUrls = exampleUrlsWithoutOrigin
        .map(it => encodeHTML(it))
        .flatMap(urlWithoutOrigin => [
          `<img src="${urlWithoutOrigin}">`,
          `<iframe src="${urlWithoutOrigin}"></iframe>`,
          `<img src="http://example2.com${urlWithoutOrigin}">`,
          `<iframe src="http://example2.com${urlWithoutOrigin}"></iframe>`,
        ])
        .join(``)

      it('handles false', () => {
        createMountedElement({
          canvasOrigin: 'http://example.com/',
          defaultContent: contentWithAbsoluteUrls,

          features: {
            rce_transform_loaded_content: false,
          },
        })
        expect(rce.editor.getContent()).toBe(contentWithAbsoluteUrls)
      })

      it('handles true', () => {
        createMountedElement({
          canvasOrigin: 'http://example.com/',
          defaultContent: contentWithAbsoluteUrls,
          features: {
            rce_transform_loaded_content: true,
          },
        })
        expect(rce.editor.getContent()).toBe(contentWithRelativeUrls)
      })
    })
  })
})
