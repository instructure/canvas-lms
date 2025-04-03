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
import {render} from '@testing-library/react'
import FakeEditor from './FakeEditor'

import RCEWrapper from '../RCEWrapper'

const textareaId = 'myUniqId'
const canvasOrigin = 'https://canvas:3000'

let fakeTinyMCE, editorCommandSpy, editor, rce

// ====================
//        HELPERS
// ====================

function createBasicElement(opts) {
  editor = new FakeEditor({id: textareaId})
  fakeTinyMCE.get = () => editor
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
    {container},
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
})
