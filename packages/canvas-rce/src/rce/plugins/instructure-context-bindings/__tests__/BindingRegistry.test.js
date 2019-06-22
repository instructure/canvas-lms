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

import {fireEvent} from 'dom-testing-library'

import BindingRegistry from '../BindingRegistry'
import FakeEditor from './FakeEditor'

/*
 * To protect against unpredictable situations with TinyMCE, and perhaps some
 * race conditions with different contexts, tests exist below which are intended
 * to protect against behavior from one widget interfering with that of other
 * contexts. Realistically, this should never occur, as it would probably be bad
 * UX. But with TinyMCE, take nothing for granted.
 */

describe('RCE Plugins > Instructure Context Bindings > BindingRegistry', () => {
  /*
   * To protect against unknowns related to using a global binding registry, the
   * same instance of the BindingRegistry will be reused across specs, reset in
   * between.
   */
  const bindingRegistry = new BindingRegistry()

  let $auxContainers
  let $container
  let fakeEditors
  let globalOnError

  beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    globalOnError = jest.fn()

    fakeEditors = {}
    $auxContainers = []
    ;['a', 'b', 'c'].forEach(editorKey => {
      const fakeEditor = (fakeEditors[editorKey] = new FakeEditor($container))
      fakeEditor.setup()
      $auxContainers.push(fakeEditor.$auxContainer)

      bindingRegistry.addContextForm(fakeEditor, 'font-size', {
        commands: [{tooltip: 'Increase Size'}, {tooltip: 'Decrease Size'}],
        label: 'Font Size'
      })
      bindingRegistry.addContextForm(fakeEditor, 'link', {
        commands: [{tooltip: 'Add Link'}, {tooltip: 'Remove Link'}],
        label: 'Link'
      })

      bindingRegistry.linkEditor(fakeEditor)
    })
  })

  afterEach(() => {
    bindingRegistry.reset()
    Object.values(fakeEditors).forEach(fakeEditor => fakeEditor.teardown())
    $container.remove()

    window.onerror = null // not reset automatically by jest
  })

  function showFontSizeContext(editorKey) {
    return fakeEditors[editorKey].showContextForm('font-size')
  }

  function showLinkContext(editorKey) {
    return fakeEditors[editorKey].showContextForm('link')
  }

  function enterIntoContext(editorKey) {
    const event = new KeyboardEvent('keydown', {altKey: true, keyCode: 118})
    fakeEditors[editorKey].triggerEvent(event)
    return event
  }

  function escapeFromContext($contextContainer, selector) {
    const $element = $contextContainer.querySelector(selector)
    fireEvent.keyDown($element, {keyCode: 27})
    $contextContainer.remove()
  }

  describe('Alt+F7 to enter a context', () => {
    it('adds a Alt+F7 binding for the context', () => {
      const $contextContainer = showLinkContext('b')
      enterIntoContext('b')
      expect($contextContainer.contains(document.activeElement)).toEqual(true)
    })

    it('ignores bindings for unrelated contexts in different editors', () => {
      showLinkContext('a')
      const $contextContainer = showLinkContext('b')
      showLinkContext('c')
      enterIntoContext('b')
      expect($contextContainer.contains(document.activeElement)).toEqual(true)
    })

    describe('when the context has been closed', () => {
      beforeEach(() => {
        const $contextContainer = showLinkContext('b')
        enterIntoContext('b')
        escapeFromContext($contextContainer, 'input')
      })

      it('does not change focus', () => {
        const $activeElementBefore = document.activeElement
        enterIntoContext('b')
        expect(document.activeElement).toEqual($activeElementBefore)
      })

      it('does not throw an error', () => {
        enterIntoContext('b')
        expect(globalOnError).not.toHaveBeenCalled()
      })
    })

    describe('when no context has been created', () => {
      it('does not change focus', () => {
        const $activeElementBefore = document.activeElement
        enterIntoContext('b')
        expect(document.activeElement).toEqual($activeElementBefore)
      })

      it('does not throw an error', () => {
        enterIntoContext('b')
        expect(globalOnError).not.toHaveBeenCalled()
      })
    })
  })

  describe('when escaping a context', () => {
    it('collapses the selection in the editor', () => {
      const $contextContainer = showLinkContext('b')
      enterIntoContext('b')
      escapeFromContext($contextContainer, 'input')
      expect(fakeEditors.b.selection.collapse).toHaveBeenCalledTimes(1)
    })

    it('continues to function after the context has been closed and opened again', () => {
      let $contextContainer = showLinkContext('b')
      enterIntoContext('b')
      escapeFromContext($contextContainer, 'input')
      $contextContainer = showLinkContext('b')
      enterIntoContext('b')
      escapeFromContext($contextContainer, 'input')
      expect(fakeEditors.b.selection.collapse).toHaveBeenCalledTimes(2)
    })

    it('does not escape unrelated contexts in the same editor', () => {
      const $fontSizeContextContainer = showFontSizeContext('b')
      const $linkContextContainer = showLinkContext('b')
      enterIntoContext('b')
      escapeFromContext($linkContextContainer, 'input')
      expect($fontSizeContextContainer).toBeInTheDocument()
    })

    it('does not escape unrelated contexts in different editors', () => {
      const $contextContainerC = showLinkContext('c')
      const $contextContainerB = showLinkContext('b')
      enterIntoContext('b')
      escapeFromContext($contextContainerB, 'input')
      expect($contextContainerC).toBeInTheDocument()
    })
  })

  describe('unlinking editors', () => {
    it('removes the Alt+F7 bindings for the given editor', () => {
      const $contextContainer = showLinkContext('b')
      bindingRegistry.unlinkEditor(fakeEditors.b)
      enterIntoContext('b')
      expect($contextContainer.contains(document.activeElement)).toEqual(false)
    })

    it('does not remove Alt+F7 bindings for other editors', () => {
      const $contextContainer = showLinkContext('a')
      showLinkContext('b')
      bindingRegistry.unlinkEditor(fakeEditors.b)
      enterIntoContext('a')
      expect($contextContainer.contains(document.activeElement)).toEqual(true)
    })

    it('removes the Esc bindings for the given editor', () => {
      const $contextContainer = showLinkContext('b')
      enterIntoContext('b')
      bindingRegistry.unlinkEditor(fakeEditors.b)
      escapeFromContext($contextContainer, 'input')
      expect(fakeEditors.b.selection.collapse).not.toHaveBeenCalled()
    })

    it('does not remove the Esc bindings for other editors', () => {
      const $contextContainer = showLinkContext('a')
      showLinkContext('b')
      bindingRegistry.unlinkEditor(fakeEditors.b)
      enterIntoContext('a')
      escapeFromContext($contextContainer, 'input')
      expect(fakeEditors.a.selection.collapse).toHaveBeenCalledTimes(1)
    })

    it('does not throw an error when unlinking twice', () => {
      // Because you never know.
      bindingRegistry.unlinkEditor(fakeEditors.b)
      bindingRegistry.unlinkEditor(fakeEditors.b)
      expect(globalOnError).not.toHaveBeenCalled()
    })
  })
})
