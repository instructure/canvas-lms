/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import ExternalToolDialog from '../ExternalToolDialog'
import ApplyTheme from '@instructure/ui-themeable/lib/components/ApplyTheme'
import Transition from '@instructure/ui-motion/lib/components/Transition'
import {processContentItemsForEditor} from '../../deep_linking/ContentItemProcessor'
import {send} from '../../shared/rce/RceCommandShim'

jest.mock('../../deep_linking/ContentItemProcessor')
jest.mock('../../shared/rce/RceCommandShim')

const noop = () => {}

let container, submit, originalSubmit, originalScroll

async function waitForAssertion(cb) {
  try {
    cb()
  } catch (_) {
    await new Promise(resolve => setTimeout(resolve, 25))
    await waitForAssertion(cb)
  }
}

function fakeWindow() {
  return {
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    confirm: jest.fn().mockReturnValue(true),
    height: 1000,
    $: jest.fn().mockReturnValue({bind: noop, unbind: noop})
  }
}

function fakeEditor() {
  return {
    id: 'editor-id',
    selection: {
      getContent: jest.fn()
    },
    getContent: jest.fn()
  }
}

function fakeContentItem(text) {
  return {
    placementAdvice: {presentationDocumentTarget: 'embed'},
    text
  }
}

function fakeRCEReplaceContentItem(text) {
  return {
    placementAdvice: {
      presentationDocumentTarget: 'embed'
    },
    '@type': 'lti_replace',
    text
  }
}

function getInstance(_container, overrides) {
  return new Promise(resolve => {
    const props = {
      win: fakeWindow(),
      editor: fakeEditor(),
      contextAssetString: 'course_1',
      iframeAllowances: 'geolocation',
      resourceSelectionUrl: 'http://url/with/{{id}}',
      deepLinkingOrigin: 'deepOrigin',
      ...overrides,
      ref: resolve
    }
    ReactDOM.render(
      <ApplyTheme theme={{[Transition.theme]: {duration: '0ms'}}}>
        <ExternalToolDialog {...props} />
      </ApplyTheme>,
      _container
    )
  })
}

beforeEach(async () => {
  originalSubmit = HTMLFormElement.prototype.submit
  submit = jest.fn()
  HTMLFormElement.prototype.submit = submit
  originalScroll = window.scroll
  window.scroll = noop
  container = document.createElement('div')
  send.mockReset()
  processContentItemsForEditor.mockReset()
})

afterEach(() => {
  ReactDOM.unmountComponentAtNode(container)
  HTMLFormElement.prototype.submit = originalSubmit
  window.scroll = originalScroll
  container = undefined
})

describe('open', () => {
  test('launches external tool when opened', async () => {
    const instance = await getInstance(container)
    instance.open({name: 'foo', id: 1})
    expect(container.querySelector('form').action).toBe('http://url/with/1')
    expect(submit).toHaveBeenCalled()
  })

  it('submits current selection to tool', async () => {
    const editor = fakeEditor()
    const selection = 'selected text'
    editor.selection.getContent.mockReturnValue(selection)
    const instance = await getInstance(container, {editor})
    instance.open({name: 'foo', id: 1})
    expect(container.querySelector('input[name="selection"]').value).toBe(selection)
    expect(submit).toHaveBeenCalled()
  })

  it('submits current editor contents to tool', async () => {
    const editor = fakeEditor()
    const contents = 'editor contents'
    editor.getContent.mockReturnValue(contents)
    const instance = await getInstance(container, {editor})
    instance.open({name: 'foo', id: 1})
    expect(container.querySelector('input[name="editor_contents"]').value).toBe(contents)
    expect(submit).toHaveBeenCalled()
  })

  it('uses default resource selection url', async () => {
    const instance = await getInstance(container, {resourceSelectionUrl: undefined})
    instance.open({name: 'foo', id: 2})
    expect(container.querySelector('form').action).toBe(
      'http://localhost/courses/1/external_tools/2/resource_selection'
    )
  })

  it('uses button name as modal heading', async () => {
    const instance = await getInstance(container, {resourceSelectionUrl: null})
    instance.open({name: 'foo', id: 2})
    expect(document.querySelector('h2').textContent).toContain('foo')
  })

  it('sets up beforeunload handler', async () => {
    const win = fakeWindow()
    const instance = await getInstance(container, {win})
    instance.open({name: 'foo', id: 2})
    expect(win.addEventListener).toHaveBeenCalledWith('beforeunload', instance.handleBeforeUnload)
  })

  it('sets up deep linking handler', async () => {
    const win = fakeWindow()
    const instance = await getInstance(container, {win})
    instance.open({name: 'foo', id: 2})
    expect(win.addEventListener).toHaveBeenCalledWith('message', instance.handleDeepLinking)
  })

  it('sets up external content ready handler', async () => {
    const win = fakeWindow()
    const bind = jest.fn()
    win.$.mockReturnValue({bind})
    const instance = await getInstance(container, {win})
    instance.open({name: 'foo', id: 2})
    expect(win.$).toHaveBeenCalledWith(instance.props.win)
    expect(bind).toHaveBeenCalledWith('externalContentReady', instance.handleExternalContentReady)
  })

  describe('tray', () => {
    it('does not set height or width for iframe', async () => {
      const instance = await getInstance(container)
      instance.open({name: 'foo', id: 2, use_tray: true})
      const style = document.querySelector('iframe').style
      expect(style.height).toBe('')
      expect(style.width).toBe('')
    })
  })
})

describe('close', () => {
  it('closes the dialog', async () => {
    const instance = await getInstance(container)
    instance.open({name: 'foo', id: 1})
    instance.close()
    await waitForAssertion(() => {
      expect(document.querySelector('iframe')).toBeNull()
    })
  })

  it('removes beforeunload handler', async () => {
    const win = fakeWindow()
    const instance = await getInstance(container, {win})
    instance.open({name: 'foo', id: 2})
    instance.close()
    expect(win.removeEventListener).toHaveBeenCalledWith(
      'beforeunload',
      instance.handleBeforeUnload
    )
  })

  it('removes deep linking handler', async () => {
    const win = fakeWindow()
    const instance = await getInstance(container, {win})
    instance.open({name: 'foo', id: 2})
    instance.close()
    expect(win.removeEventListener).toHaveBeenCalledWith('message', instance.handleDeepLinking)
  })

  it('removes external content ready handler', async () => {
    const win = fakeWindow()
    const unbind = jest.fn()
    win.$.mockReturnValue({bind: noop, unbind})
    const instance = await getInstance(container, {win})
    instance.open({name: 'foo', id: 2})
    instance.handleClose()
    expect(win.$).toHaveBeenCalledWith(instance.props.win)
    expect(unbind).toHaveBeenCalledWith('externalContentReady')
  })
})

describe('handleClose', () => {
  it('does not close if not confirmed', async () => {
    const win = fakeWindow()
    win.confirm.mockReturnValue(false)
    const instance = await getInstance(container, {win})
    instance.open({name: 'foo', id: 1})
    instance.handleClose()
    await waitForAssertion(() => {
      expect(document.querySelector('iframe')).not.toBeNull()
    })
  })

  it('closes if confirmed', async () => {
    const instance = await getInstance(container)
    instance.open({name: 'foo', id: 1})
    instance.handleClose()
    await waitForAssertion(() => {
      expect(document.querySelector('iframe')).toBeNull()
    })
  })

  it('removes beforeunload handler', async () => {
    const win = fakeWindow()
    const instance = await getInstance(container, {win})
    instance.handleClose()
    instance.open({name: 'foo', id: 2})
    expect(win.removeEventListener).toHaveBeenCalledWith(
      'beforeunload',
      instance.handleBeforeUnload
    )
  })

  it('removes deep linking handler', async () => {
    const win = fakeWindow()
    const instance = await getInstance(container, {win})
    instance.open({name: 'foo', id: 2})
    instance.handleClose()
    expect(win.removeEventListener).toHaveBeenCalledWith('message', instance.handleDeepLinking)
  })

  it('removes external content ready handler', async () => {
    const win = fakeWindow()
    const unbind = jest.fn()
    win.$.mockReturnValue({bind: noop, unbind})
    const instance = await getInstance(container, {win})
    instance.open({name: 'foo', id: 2})
    instance.handleClose()
    expect(win.$).toHaveBeenCalledWith(instance.props.win)
    expect(unbind).toHaveBeenCalledWith('externalContentReady')
  })
})

describe('handleBeforeUnload', () => {
  it('sets event return value', async () => {
    const instance = await getInstance(container)
    const ev = {}
    instance.handleBeforeUnload(ev)
    expect(ev.returnValue).toContain('may not be saved')
  })
})

describe('handleExternalContentReady', () => {
  it('inserts content items in to the editor', async () => {
    const win = fakeWindow()
    const jqObj = {unbind: noop}
    win.$.mockReturnValue(jqObj)
    const instance = await getInstance(container, {win})
    const data = {
      contentItems: [fakeContentItem('foo'), fakeContentItem('bar')]
    }
    instance.handleExternalContentReady({}, data)
    expect(win.$).toHaveBeenCalledWith('#editor-id')
    expect(send).toHaveBeenCalledWith(jqObj, 'insert_code', 'foo')
    expect(send).toHaveBeenCalledWith(jqObj, 'insert_code', 'bar')
  })

  it('replaces content items in the editor', async () => {
    const win = fakeWindow()
    const jqObj = {
      unbind: noop
    }
    win.$.mockReturnValue(jqObj)
    const instance = await getInstance(container, {
      win
    })
    const data = {
      contentItems: [fakeRCEReplaceContentItem('foo')]
    }
    instance.handleExternalContentReady({}, data)
    expect(win.$).toHaveBeenCalledWith('#editor-id')
    expect(send).toHaveBeenCalledWith(jqObj, 'set_code', 'foo')
  })

  it('removes beforeunload handler', async () => {
    const win = fakeWindow()
    const instance = await getInstance(container, {win})
    instance.handleExternalContentReady({}, {contentItems: []})
    expect(win.removeEventListener).toHaveBeenCalledWith(
      'beforeunload',
      instance.handleBeforeUnload
    )
  })

  it('removes deep linking handler', async () => {
    const win = fakeWindow()
    const instance = await getInstance(container, {win})
    instance.handleExternalContentReady({}, {contentItems: []})
    expect(win.removeEventListener).toHaveBeenCalledWith('message', instance.handleDeepLinking)
  })

  it('removes external content ready handler', async () => {
    const win = fakeWindow()
    const unbind = jest.fn()
    win.$.mockReturnValue({bind: noop, unbind})
    const instance = await getInstance(container, {win})
    instance.handleExternalContentReady({}, {contentItems: []})
    expect(win.$).toHaveBeenCalledWith(instance.props.win)
    expect(unbind).toHaveBeenCalledWith('externalContentReady')
  })

  it('closes the dialog', async () => {
    const instance = await getInstance(container)
    instance.open({name: 'foo', id: 1})
    instance.handleExternalContentReady({}, {contentItems: []})
    await waitForAssertion(() => {
      expect(document.querySelector('iframe')).toBeNull()
    })
  })
})

describe('handleDeepLinking', () => {
  it('ignores other origins', async () => {
    const instance = await getInstance(container)
    const ev = {origin: 'otherOrigin'}
    instance.handleDeepLinking(ev)
    expect(processContentItemsForEditor).not.toHaveBeenCalled()
  })

  it('processes content items for correct origin', async () => {
    const editor = fakeEditor()
    const instance = await getInstance(container, {editor})
    const ev = {origin: 'deepOrigin'}
    instance.handleDeepLinking(ev)
    expect(processContentItemsForEditor).toHaveBeenCalledWith(ev, editor, instance)
  })
})

describe('alerts', () => {
  it('has screenreader-only for both by default', async () => {
    const instance = await getInstance(container)
    instance.open({name: 'foo', id: 1})
    expect(instance.beforeInfoAlertRef.className).toContain('screenreader-only')
    expect(instance.afterInfoAlertRef.className).toContain('screenreader-only')
  })

  it('removes screenreader-only from before alert on focus', async () => {
    const instance = await getInstance(container)
    instance.open({name: 'foo', id: 1})
    const ev = {target: instance.beforeInfoAlertRef}
    instance.handleInfoAlertFocus(ev)
    expect(instance.beforeInfoAlertRef.className).not.toContain('screenreader-only')
    expect(instance.afterInfoAlertRef.className).toContain('screenreader-only')
    instance.handleInfoAlertBlur()
    expect(instance.beforeInfoAlertRef.className).toContain('screenreader-only')
  })

  it('removes screenreader-only from after alert on focus', async () => {
    const instance = await getInstance(container)
    instance.open({name: 'foo', id: 1})
    const ev = {target: instance.afterInfoAlertRef}
    instance.handleInfoAlertFocus(ev)
    expect(instance.beforeInfoAlertRef.className).toContain('screenreader-only')
    expect(instance.afterInfoAlertRef.className).not.toContain('screenreader-only')
    instance.handleInfoAlertBlur()
    expect(instance.afterInfoAlertRef.className).toContain('screenreader-only')
  })
})
