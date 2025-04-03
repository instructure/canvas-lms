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
      get: () => editor,
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
      expect(getAllByText(alertmsg1)).toHaveLength(1)
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
})
