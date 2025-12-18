/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {fireEvent} from '@testing-library/react'
import {KBNavigator, handleShortcutKey} from '../KBNavigator'
import fakeENV from '@canvas/test-utils/fakeENV'
import {DragStateChangeDetail} from '../types'

const buildTeacherModule = (id: string, position: number, collapsed: boolean): HTMLElement => {
  const mod = `
  <div class="context_module ${collapsed ? 'collapsed' : 'expanded'}" data-module-id="${id}" data-position="${position}" tabindex="0">
    <div class="header">
      <span class="module_title" role="button" tabindex="0">Module ${id}</span>
      <button id="module-header-expand-toggle-${id}">Collapse "Module ${id}"</button>
      <button class="al-trigger" data-testid="module${id}-menu">Actions</button>
    </div>
    ${
      collapsed
        ? ''
        : `<div class="content">
      <ul class="context_module_items">
        <li class="context_module_item" data-item-id="${id}-1" data-position="1" tabindex="0">
          <span class="item_title">Item ${id}-1</span>
          <button class="al-trigger" data-testid="item${id}-1-menu">Actions</button>
        </li>
        <li class="context_module_item" data-item-id="${id}-2" data-position="2" tabindex="0">
          <span class="item_title">Item ${id}-2</span>
          <button class="al-trigger" data-testid="item${id}-2-menu">Actions</button>
        </li>
      </ul>
    </div>`
    }
  </div>`
  const div = document.createElement('div')
  div.innerHTML = mod
  return div.firstElementChild as HTMLElement
}

const buildStudentModule = (id: string, position: number, collapsed: boolean): HTMLElement => {
  const mod = `
  <div class="context_module ${collapsed ? 'collapsed' : 'expanded'}" data-module-id="${id}" data-position="${position}" tabindex="0">
    <div class="header">
      <span class="name">Module ${id}</span>
      <button id="module-header-expand-toggle-${id}">Collapse "Module ${id}"</button>
    </div>
    ${
      collapsed
        ? ''
        : `<div class="content">
      <ul class="context_module_items">
        <li class="context_module_item" data-item-id="${id}-1" data-position="1" tabindex="0">
          <span class="item_title">Item ${id}-1</span>
        </li>
        <li class="context_module_item" data-item-id="${id}-2" data-position="2" tabindex="0">
          <span class="item_title">Item ${id}-2</span>
        </li>
      </ul>
    </div>`
    }
  </div>`
  const div = document.createElement('div')
  div.innerHTML = mod
  return div.firstElementChild as HTMLElement
}

const getModuleList = (): HTMLElement => {
  return document.querySelector('.context_module_list') as HTMLElement
}

describe('KBNavigator', () => {
  beforeAll(() => {
    fakeENV.setup({course_id: '123'})
  })

  afterAll(() => {
    fakeENV.teardown()
  })

  const navigator = new KBNavigator()
  beforeEach(() => {
    const mainContent = document.createElement('div')
    mainContent.id = 'content'
    mainContent.setAttribute('tabindex', '-1')
    document.body.appendChild(mainContent)
    const modlist = document.createElement('div')
    modlist.className = 'context_module_list'
    mainContent.appendChild(modlist)
    mainContent.addEventListener('keydown', handleShortcutKey)
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  // Helper function to create mock keyboard events
  const createMockEvent = (
    key: string,
    target: HTMLElement | Document,
    options: Partial<KeyboardEvent> = {},
  ): KeyboardEvent => {
    return {
      key,
      target,
      preventDefault: vi.fn(),
      stopPropagation: vi.fn(),
      ctrlKey: false,
      metaKey: false,
      altKey: false,
      ...options,
    } as unknown as KeyboardEvent
  }

  describe('getElemType', () => {
    beforeEach(() => {
      document.querySelector('.context_module_list')?.appendChild(buildTeacherModule('1', 1, false))
    })

    it('should identify context_module_item type', () => {
      const item = document.querySelector('[data-item-id="1-1"]') as HTMLElement
      const result = navigator.getElemType(item)
      expect(result.type).toBe('item')
      expect(result.elem).toBe(item)
    })

    it('should identify context_module type', () => {
      const module = document.querySelector('[data-module-id="1"]') as HTMLElement
      const result = navigator.getElemType(module)
      expect(result.type).toBe('module')
      expect(result.elem).toBe(module)
    })

    it('should identify context_module_list type', () => {
      const moduleList = getModuleList()
      const result = navigator.getElemType(moduleList)
      expect(result.type).toBe('modulelist')
      expect(result.elem).toBe(moduleList)
    })

    it('should return undefined for unknown types', () => {
      const div = document.createElement('div')
      const result = navigator.getElemType(div)
      expect(result.type).toBeUndefined()
      expect(result.elem).toBe(div)
    })
  })

  describe('getFocusableElem', () => {
    describe('as a teacher', () => {
      beforeEach(() => {
        document
          .querySelector('.context_module_list')
          ?.appendChild(buildTeacherModule('1', 1, false))
      })
      it('should return the title element for a module', () => {
        const module = document.querySelector('[data-module-id="1"]') as HTMLElement
        const title = navigator.getFocusableElem(module) as HTMLElement
        expect(title).toBe(module.querySelector('.module_title'))
        expect(title.textContent).toBe('Module 1')
      })

      it('should return the title element for an item', () => {
        const item = document.querySelector('[data-item-id="1-1"]') as HTMLElement
        const title = navigator.getFocusableElem(item)
        expect(title).toBe(item.querySelector('a, button'))
      })
    })

    describe('as a student', () => {
      beforeEach(() => {
        document
          .querySelector('.context_module_list')
          ?.appendChild(buildStudentModule('2', 2, false))
      })

      it('should return the expand/collapse button for a module', () => {
        const module = document.querySelector('[data-module-id="2"]') as HTMLElement
        const button = navigator.getFocusableElem(module) as HTMLButtonElement
        expect(button).not.toBeNull()
        expect(button.textContent).toBe('Collapse "Module 2"')
      })
    })
  })

  describe('handleShortcutKey', () => {
    beforeEach(() => {
      // collapsed, collapsed, expanded, expanded
      const moduleList = getModuleList()
      moduleList.appendChild(buildTeacherModule('1', 1, true))
      moduleList.appendChild(buildTeacherModule('2', 2, true))
      moduleList.appendChild(buildTeacherModule('3', 3, false))
      moduleList.appendChild(buildTeacherModule('4', 4, false))
    })

    describe('navigation', () => {
      it('should call handleDown on j key', () => {
        const spy = vi.spyOn(navigator, 'handleDown')
        const module1 = document.querySelector('[data-module-id="1"]') as HTMLElement
        module1.focus()
        const mockEvent = createMockEvent('j', module1)
        navigator.handleShortcutKey(mockEvent)
        expect(spy).toHaveBeenCalled()
      })

      it('should call handleDown on ArrowDown key', () => {
        const spy = vi.spyOn(navigator, 'handleDown')
        const module1 = document.querySelector('[data-module-id="1"]') as HTMLElement
        module1.focus()
        const mockEvent = createMockEvent('ArrowDown', module1)
        navigator.handleShortcutKey(mockEvent)
        expect(spy).toHaveBeenCalled()
      })

      it('should call handleUp on k key', () => {
        const spy = vi.spyOn(navigator, 'handleUp')
        const module1 = document.querySelector('[data-module-id="1"]') as HTMLElement
        module1.focus()
        const mockEvent = createMockEvent('k', module1)
        navigator.handleShortcutKey(mockEvent)
        expect(spy).toHaveBeenCalled()
      })

      it('should call handleUp on ArrowUp key', () => {
        const spy = vi.spyOn(navigator, 'handleUp')
        const module1 = document.querySelector('[data-module-id="1"]') as HTMLElement
        module1.focus()
        const mockEvent = createMockEvent('ArrowUp', module1)
        navigator.handleShortcutKey(mockEvent)
        expect(spy).toHaveBeenCalled()
      })

      it('should call handleHelp on ? key', () => {
        const spy = vi.spyOn(navigator, 'handleHelp')
        const module1 = document.querySelector('[data-module-id="1"]') as HTMLElement
        module1.focus()
        const mockEvent = createMockEvent('?', module1)
        navigator.handleShortcutKey(mockEvent)
        expect(spy).toHaveBeenCalled()
      })

      describe('down', () => {
        it('should move focus from the main content area to the first module', () => {
          const mainContent = document.querySelector('#content') as HTMLElement
          mainContent.focus()
          fireEvent.keyDown(mainContent, {key: 'j'})
          expect(document.activeElement).toBe(
            navigator.getFocusableElem(
              document.querySelector('[data-module-id="1"]') as HTMLElement,
            ),
          )
        })
        it('down should move focus from collapsed module to next module', () => {
          const module1 = document.querySelector('[data-module-id="1"]') as HTMLElement
          const module2 = document.querySelector('[data-module-id="2"]') as HTMLElement
          module1.focus()
          fireEvent.keyDown(module1, {key: 'j'})
          expect(document.activeElement).toBe(navigator.getFocusableElem(module2))
        })

        it('should move from expanded module to its first item', () => {
          const module2 = document.querySelector('[data-module-id="3"]') as HTMLElement
          const item1 = document.querySelector('[data-item-id="3-1"]') as HTMLElement
          module2.focus()
          fireEvent.keyDown(module2, {key: 'j'})
          expect(document.activeElement).toBe(navigator.getFocusableElem(item1))
        })

        it('should move from one item to the next', () => {
          const item1 = document.querySelector('[data-item-id="3-1"]') as HTMLElement
          const item2 = document.querySelector('[data-item-id="3-2"]') as HTMLElement
          const focusable1 = navigator.getFocusableElem(item1) as HTMLElement
          const focusable2 = navigator.getFocusableElem(item2) as HTMLElement
          focusable1.focus()
          fireEvent.keyDown(focusable1, {key: 'j'})
          expect(document.activeElement).toBe(focusable2)
        })

        it('should move from the last item to the next module', () => {
          const item2 = document.querySelector('[data-item-id="3-2"]') as HTMLElement
          const focusable2 = navigator.getFocusableElem(item2) as HTMLElement
          focusable2.focus()
          fireEvent.keyDown(focusable2, {key: 'j'})
          expect(document.activeElement).toBe(
            navigator.getFocusableElem(
              document.querySelector('[data-module-id="4"]') as HTMLElement,
            ),
          )
        })
      })

      describe('up', () => {
        it(`should move from a collapsed module to the previous collapses module`, () => {
          const module1 = document.querySelector('[data-module-id="1"]') as HTMLElement
          const module2 = document.querySelector('[data-module-id="2"]') as HTMLElement
          module2.focus()
          fireEvent.keyDown(module2, {key: 'k'})
          expect(document.activeElement).toBe(navigator.getFocusableElem(module1))
        })

        it(`move from the first item to its module`, () => {
          const module3 = document.querySelector('[data-module-id="3"]') as HTMLElement
          const item1 = document.querySelector('[data-item-id="3-1"]') as HTMLElement
          item1.focus()
          fireEvent.keyDown(item1, {key: 'k'})
          expect(document.activeElement).toBe(navigator.getFocusableElem(module3))
        })

        it('move from an item to the previous item', () => {
          const item2 = document.querySelector('[data-item-id="3-2"]') as HTMLElement
          const item1 = document.querySelector('[data-item-id="3-1"]') as HTMLElement
          item2.focus()
          fireEvent.keyDown(item2, {key: 'k'})
          expect(document.activeElement).toBe(navigator.getFocusableElem(item1))
        })

        it('move from a module to the last item in the previous expanded module', () => {
          const module4 = document.querySelector('[data-module-id="4"]') as HTMLElement
          const item2 = document.querySelector('[data-item-id="3-2"]') as HTMLElement
          const focusableModule4 = navigator.getFocusableElem(module4) as HTMLElement
          focusableModule4.focus()
          fireEvent.keyDown(focusableModule4, {key: 'k'})
          expect(document.activeElement).toBe(navigator.getFocusableElem(item2))
        })
      })

      it('should handle ? key press for help - no focus change', () => {
        const module1 = document.querySelector('[data-module-id="1"]') as HTMLElement
        module1.focus()
        const initialFocus = document.activeElement

        fireEvent.keyDown(module1, {key: '?', shiftKey: true})

        // Help action doesn't change focus
        expect(document.activeElement).toBe(initialFocus)
      })
    })

    describe('commands', () => {
      // Event listener and spy setup
      let eventSpy: any

      beforeEach(() => {
        eventSpy = vi.fn()
        document.addEventListener('module-action', eventSpy)
      })

      afterEach(() => {
        document.removeEventListener('module-action', eventSpy)
        vi.restoreAllMocks()
      })

      describe('e', () => {
        it('should dispatch edit command for a module', () => {
          const module1Title = document.querySelector(
            '[data-module-id="1"] .module_title',
          ) as HTMLElement
          module1Title.focus()

          fireEvent.keyDown(module1Title, {key: 'e'})

          expect(eventSpy).toHaveBeenCalled()
          const event = eventSpy.mock.calls[0][0]
          expect(event.detail).toEqual({
            action: 'edit',
            courseId: '123',
            moduleId: '1',
          })
        })

        it('should dispatch edit command for an item', () => {
          const itemKabobMenuButton = document.querySelector(
            '[data-item-id="3-1"] .al-trigger',
          ) as HTMLElement
          itemKabobMenuButton.focus()

          fireEvent.keyDown(itemKabobMenuButton, {key: 'e'})

          expect(eventSpy).toHaveBeenCalled()
          const event = eventSpy.mock.calls[0][0]
          expect(event.detail).toEqual({
            action: 'edit',
            courseId: '123',
            moduleId: '3',
            moduleItemId: '3-1',
          })
        })
      })

      describe('d', () => {
        it('should dispatch delete command for a module', () => {
          const moduleTitle = document.querySelector(
            '[data-module-id="1"] .module_title',
          ) as HTMLElement
          moduleTitle.focus()

          fireEvent.keyDown(moduleTitle, {key: 'd'})

          expect(eventSpy).toHaveBeenCalled()
          const event = eventSpy.mock.calls[0][0]
          expect(event.detail).toEqual({
            action: 'delete',
            courseId: '123',
            moduleId: '1',
          })
        })

        it('should dispatch remove command for an item', () => {
          const itemKabobMenuButton = document.querySelector(
            '[data-item-id="3-1"] .al-trigger',
          ) as HTMLElement
          itemKabobMenuButton.focus()

          fireEvent.keyDown(itemKabobMenuButton, {key: 'd'})

          expect(eventSpy).toHaveBeenCalled()
          const event = eventSpy.mock.calls[0][0]
          expect(event.detail).toEqual({
            action: 'remove',
            courseId: '123',
            moduleId: '3',
            moduleItemId: '3-1',
            setIsMenuOpen: undefined,
            onAfterSuccess: expect.any(Function),
          })
        })

        it('should focus the previous item after deleting an item', () => {
          const itemKabobMenuButton = document.querySelector(
            '[data-item-id="3-2"] .al-trigger',
          ) as HTMLElement
          itemKabobMenuButton.focus()
          fireEvent.keyDown(itemKabobMenuButton, {key: 'd'})

          // Extract and call the callback
          const event = eventSpy.mock.calls[0][0]
          const callback = event.detail.onAfterSuccess
          callback()

          expect(document.activeElement).toBe(
            navigator.getFocusableElem(
              document.querySelector('[data-item-id="3-1"]') as HTMLElement,
            ),
          )
        })

        it('should focus the parent module after deleting the first item', () => {
          const itemKabobMenuButton = document.querySelector(
            '[data-item-id="3-1"] .al-trigger',
          ) as HTMLElement
          itemKabobMenuButton.focus()
          fireEvent.keyDown(itemKabobMenuButton, {key: 'd'})

          // Extract and call the callback
          const event = eventSpy.mock.calls[0][0]
          const callback = event.detail.onAfterSuccess
          callback()

          expect(document.activeElement).toBe(
            navigator.getFocusableElem(
              document.querySelector('[data-module-id="3"]') as HTMLElement,
            ),
          )
        })
      })

      describe('i', () => {
        it('should dispatch indent command for an item', () => {
          const itemKabobMenuButton = document.querySelector(
            '[data-item-id="3-1"] .al-trigger',
          ) as HTMLElement
          itemKabobMenuButton.focus()

          fireEvent.keyDown(itemKabobMenuButton, {key: 'i'})

          expect(eventSpy).toHaveBeenCalled()
          const event = eventSpy.mock.calls[0][0]
          expect(event.detail).toEqual({
            action: 'indent',
            courseId: '123',
            moduleId: '3',
            moduleItemId: '3-1',
          })
        })

        it('should not dispatch indent command for a module', () => {
          const moduleTitle = document.querySelector(
            '[data-module-id="1"] .module_title',
          ) as HTMLElement
          moduleTitle.focus()

          fireEvent.keyDown(moduleTitle, {key: 'i'})

          expect(eventSpy).not.toHaveBeenCalled()
        })
      })

      describe('o', () => {
        it('should dispatch outdent command for an item', () => {
          const itemKabobMenuButton = document.querySelector(
            '[data-item-id="3-1"] .al-trigger',
          ) as HTMLElement
          itemKabobMenuButton.focus()

          fireEvent.keyDown(itemKabobMenuButton, {key: 'o'})

          expect(eventSpy).toHaveBeenCalled()
          const event = eventSpy.mock.calls[0][0]
          expect(event.detail).toEqual({
            action: 'outdent',
            courseId: '123',
            moduleId: '3',
            moduleItemId: '3-1',
          })
        })

        it('should not dispatch outdent command for a module', () => {
          const moduleTitle = document.querySelector(
            '[data-module-id="1"] .module_title',
          ) as HTMLElement
          moduleTitle.focus()

          fireEvent.keyDown(moduleTitle, {key: 'o'})

          expect(eventSpy).not.toHaveBeenCalled()
        })
      })

      describe('n', () => {
        it('should dispatch new command when focused on a module', () => {
          const moduleTitle = document.querySelector(
            '[data-module-id="1"] .module_title',
          ) as HTMLElement
          moduleTitle.focus()

          fireEvent.keyDown(moduleTitle, {key: 'n'})

          expect(eventSpy).toHaveBeenCalled()
          const event = eventSpy.mock.calls[0][0]
          expect(event.detail).toEqual({
            action: 'new',
            courseId: '123',
          })
        })

        it('should dispatch new command when focused on an item', () => {
          const itemKabobMenuButton = document.querySelector(
            '[data-item-id="3-1"] .al-trigger',
          ) as HTMLElement
          itemKabobMenuButton.focus()

          fireEvent.keyDown(itemKabobMenuButton, {key: 'n'})

          expect(eventSpy).toHaveBeenCalled()
          const event = eventSpy.mock.calls[0][0]
          expect(event.detail).toEqual({
            action: 'new',
            courseId: '123',
          })
        })
      })
    })
    describe('other cases', () => {
      afterEach(() => {
        document.dispatchEvent(
          new CustomEvent<DragStateChangeDetail>('drag-state-change', {
            detail: {isDragging: false},
          }),
        )
      })

      it('should handle ? key press for help - no focus change', () => {
        const module1 = document.querySelector('[data-module-id="1"]') as HTMLElement
        module1.focus()
        const initialFocus = document.activeElement

        fireEvent.keyDown(module1, {key: '?', shiftKey: true})

        // Help action doesn't change focus
        expect(document.activeElement).toBe(initialFocus)
      })

      it('should not handle unhandled keys - no focus change', () => {
        const module1 = document.querySelector('[data-module-id="1"]') as HTMLElement
        module1.focus()
        const initialFocus = document.activeElement

        fireEvent.keyDown(module1, {key: 'x'})

        // Unhandled keys don't change focus
        expect(document.activeElement).toBe(initialFocus)
      })

      it('should not handle keys when ctrl is pressed - no focus change', () => {
        const module1 = document.querySelector('[data-module-id="1"]') as HTMLElement
        module1.focus()
        const initialFocus = document.activeElement

        fireEvent.keyDown(module1, {key: 'ArrowDown', ctrlKey: true})

        // Ctrl+ArrowDown should be ignored
        expect(document.activeElement).toBe(initialFocus)
      })

      it('should not handle keys while dnd is in progress', () => {
        document.dispatchEvent(
          new CustomEvent<DragStateChangeDetail>('drag-state-change', {detail: {isDragging: true}}),
        )
        const module1 = document.querySelector('[data-module-id="1"]') as HTMLElement
        module1.focus()
        const initialFocus = document.activeElement

        fireEvent.keyDown(module1, {key: 'j'})

        // Unhandled keys don't change focus
        expect(document.activeElement).toBe(initialFocus)
      })
    })
  })
})
