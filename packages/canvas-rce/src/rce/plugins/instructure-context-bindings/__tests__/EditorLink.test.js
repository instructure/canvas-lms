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

import EditorLink from '../EditorLink'
import FakeEditor from './FakeEditor'

describe('RCE Plugins > Instructure Context Bindings > EditorLink', () => {
  let $auxContainers
  let $container
  let editorLinks
  let fakeEditors
  let globalOnError

  beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    globalOnError = jest.fn()

    fakeEditors = {}
    editorLinks = {}
    $auxContainers = []
    ;['a', 'b', 'c'].forEach(editorKey => {
      const fakeEditor = (fakeEditors[editorKey] = new FakeEditor($container))
      editorLinks[editorKey] = new EditorLink(fakeEditors[editorKey])

      fakeEditor.setup()
      $auxContainers.push(fakeEditor.$auxContainer)

      fakeEditor.registerContextForm('font-size', {
        commands: [{tooltip: 'Increase Size'}, {tooltip: 'Decrease Size'}],
        label: 'Font Size'
      })
      fakeEditor.registerContextForm('link', {
        commands: [{tooltip: 'Add Link'}, {tooltip: 'Remove Link'}],
        label: 'Link'
      })
    })
  })

  afterEach(() => {
    Object.values(editorLinks).forEach(editorLink => editorLink.remove())
    Object.values(fakeEditors).forEach(fakeEditor => fakeEditor.teardown())
    $container.remove()

    window.onerror = null // not reset automatically by jest
  })

  async function waitForMutationObserver() {
    await new Promise(resolve => setTimeout(resolve, MutationObserver._period))
  }

  function showLinkContext(editorKey) {
    const $contextContainer = fakeEditors[editorKey].showContextForm('link')
    editorLinks[editorKey].addBinding('Link', $auxContainers)
    return $contextContainer
  }

  function altF7InContext($contextContainer, selector) {
    const $element = $contextContainer.querySelector(selector)
    fireEvent.keyDown($element, {altKey: true, keyCode: 118})
  }

  function escapeFromContext($contextContainer, selector) {
    const $element = $contextContainer.querySelector(selector)
    fireEvent.keyDown($element, {keyCode: 27})
    $contextContainer.remove()
  }

  it('has no aux container upon initialization', () => {
    expect(editorLinks.b.$auxContainer).toBeNull()
  })

  describe('#addBinding()', () => {
    it('binds the aux container to the editor link', () => {
      fakeEditors.b.showContextForm('link')
      editorLinks.b.addBinding('Link', $auxContainers)
      expect(editorLinks.b.$auxContainer).toEqual(fakeEditors.b.$auxContainer)
    })

    it('uses the given label to bind the container', () => {
      fakeEditors.b.showContextForm('font-size')
      fakeEditors.b.showContextForm('link')
      editorLinks.b.addBinding('Font Size', $auxContainers)
      editorLinks.b.addBinding('Link', $auxContainers)
      expect(editorLinks.b.$auxContainer).toEqual(fakeEditors.b.$auxContainer)
    })

    it('ignores contexts which have not yet been shown', () => {
      editorLinks.b.addBinding('Link', $auxContainers)
      expect(editorLinks.b.$auxContainer).toBeNull()
    })

    it('ignores unknown contexts', () => {
      fakeEditors.b.showContextForm('link')
      expect(() => editorLinks.b.addBinding('unknown', $auxContainers)).not.toThrow()
    })

    it('has no effect when given no aux containers', () => {
      fakeEditors.b.showContextForm('link')
      editorLinks.b.addBinding('Link', [])
      expect(editorLinks.b.$auxContainer).toBeNull()
    })
  })

  describe('context container bindings', () => {
    describe('keydown listener', () => {
      it('collapses the editor selection when "Escape" is pressed from a form input', () => {
        const $contextContainer = showLinkContext('b')
        escapeFromContext($contextContainer, 'input')
        expect(fakeEditors.b.selection.collapse).toHaveBeenCalledTimes(1)
      })

      it('collapses the editor selection when "Escape" is pressed from a form button', () => {
        const $contextContainer = showLinkContext('b')
        escapeFromContext($contextContainer, 'button')
        expect(fakeEditors.b.selection.collapse).toHaveBeenCalledTimes(1)
      })

      it('focuses on the editor when "Alt+F7" is pressed from a form input', () => {
        const $contextContainer = showLinkContext('b')
        altF7InContext($contextContainer, 'input')
        expect(fakeEditors.b.focus).toHaveBeenCalledTimes(1)
      })

      it('focuses on the editor when "Alt+F7" is pressed from a form button', () => {
        const $contextContainer = showLinkContext('b')
        altF7InContext($contextContainer, 'button')
        expect(fakeEditors.b.focus).toHaveBeenCalledTimes(1)
      })

      it('is removed when the binding is removed', () => {
        const $contextContainer = showLinkContext('b')
        editorLinks.b.remove()
        escapeFromContext($contextContainer, 'button')
        expect(fakeEditors.b.selection.collapse).not.toHaveBeenCalled()
      })

      it('is re-added when a binding is re-added', () => {
        const $contextContainer = showLinkContext('b')
        editorLinks.b.remove()
        editorLinks.b.addBinding('Link', $auxContainers)
        escapeFromContext($contextContainer, 'input')
        expect(fakeEditors.b.selection.collapse).toHaveBeenCalledTimes(1)
      })
    })
  })

  describe('aux container mutations', () => {
    it('removes bindings for a context when its container is removed', async () => {
      const $contextContainer = showLinkContext('b')
      await waitForMutationObserver()
      $contextContainer.remove()
      await waitForMutationObserver()
      escapeFromContext($contextContainer, 'input')
      expect(fakeEditors.b.selection.collapse).not.toHaveBeenCalled()
    })

    it('does not remove bindings for a context when elements are removed from its container', async () => {
      const $contextContainer = showLinkContext('b')
      const $element = document.createElement('div')
      $contextContainer.appendChild($element)
      await waitForMutationObserver()
      $element.remove()
      await waitForMutationObserver()
      escapeFromContext($contextContainer, 'input')
      expect(fakeEditors.b.selection.collapse).toHaveBeenCalledTimes(1)
    })

    it('does not throw an error when a container is removed for a context without bindings', async () => {
      const $contextContainer = fakeEditors.b.showContextForm('link')
      await waitForMutationObserver()
      $contextContainer.remove()
      await waitForMutationObserver()
      expect(globalOnError).not.toHaveBeenCalled()
    })

    it('does not throw an error when an unrelated element is removed from the aux container', async () => {
      showLinkContext('b')
      const $element = document.createElement('div')
      fakeEditors.b.$auxContainer.appendChild($element)
      await waitForMutationObserver()
      $element.remove()
      await waitForMutationObserver()
      expect(globalOnError).not.toHaveBeenCalled()
    })
  })

  describe('#remove()', () => {
    it('does not throw an error when the context was never used', () => {
      expect(() => editorLinks.b.remove()).not.toThrow()
    })
  })
})
