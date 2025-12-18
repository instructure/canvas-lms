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

import {setupServer} from 'msw/node'
import {queryClient} from '@canvas/query'
import {handleDelete} from '../moduleActionHandlers'
import {
  handleOpeningModuleUpdateTray,
  handleOpeningEditItemModal,
} from '../modulePageActionHandlers'
import {dispatchCommandEvent} from '../dispatchCommandEvent'
import {updateIndent, handleRemove} from '../moduleItemActionHandlers'
import modulePageCommandEventHandlers from '../modulePageCommandEventHandlers'
import {MODULE_ITEMS, MODULE_ITEM_TITLES, MODULES} from '../../utils/constants'

// Mock the handlers
vi.mock('../moduleActionHandlers')
vi.mock('../modulePageActionHandlers')
vi.mock('../moduleItemActionHandlers')

const server = setupServer()

const courseId = '1'
const moduleId = '2'
const moduleItemId = '3'

const mockModulesData = {
  pages: [
    {
      modules: [
        {
          _id: moduleId,
          name: 'Test Module',
        },
      ],
    },
  ],
}

const mockItemsData = {
  moduleItems: [
    {
      _id: moduleItemId,
      id: moduleItemId,
      title: 'Test Item',
      indent: 1,
    },
  ],
}

const mockItemsDataPage2 = {
  moduleItems: [
    {
      _id: '4',
      id: '4',
      title: 'Test Item Page 2',
      indent: 0,
    },
  ],
}

const mockItemsDataSingleItem = {
  moduleItems: [
    {
      _id: '5',
      id: '5',
      title: 'Last Item on Page',
      indent: 0,
    },
  ],
}

queryClient.setQueryData([MODULE_ITEMS, moduleId, null], mockItemsData)
queryClient.setQueryData([MODULE_ITEMS, moduleId, btoa('10')], mockItemsDataPage2)
queryClient.setQueryData([MODULE_ITEMS, moduleId, btoa('20')], mockItemsDataSingleItem)

queryClient.setQueryData([MODULES, courseId], mockModulesData)

queryClient.setQueryData([MODULE_ITEM_TITLES, moduleId], mockItemsData)

describe('modulePageCommandEventHandlers', () => {
  beforeAll(() => {
    server.listen()
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  beforeEach(() => {
    // Mock DOM elements
    document.body.innerHTML = `
      <div id="context-modules-header-add-module-button"></div>
      <div data-module-id="${moduleId}" data-module-name="Test Module"></div>
    `
  })

  describe('dispatchCommandEvent', () => {
    it('dispatches a module-action event with the correct detail', () => {
      const dispatchSpy = vi.spyOn(document, 'dispatchEvent')
      const action = 'edit' as const

      dispatchCommandEvent({action, courseId, moduleId})

      expect(dispatchSpy).toHaveBeenCalled()
      const event = dispatchSpy.mock.calls[0][0] as CustomEvent
      expect(event.type).toBe('module-action')
      expect(event.detail).toEqual({
        action,
        courseId,
        moduleId,
      })
    })
  })

  describe('handleModuleAction', () => {
    describe('module actions', () => {
      it('calls handleEditModule when action is edit with moduleId and no moduleItemId', async () => {
        const event = new CustomEvent('module-action', {
          detail: {
            action: 'edit',
            courseId,
            moduleId,
          },
        })

        document.dispatchEvent(event)

        // Allow any pending promises to resolve
        await new Promise(process.nextTick)

        expect(handleOpeningModuleUpdateTray).toHaveBeenCalledWith(
          mockModulesData,
          courseId,
          moduleId,
          'Test Module',
          'settings',
          mockItemsData,
        )
      })

      it('calls handleOpeningEditItemModal when action is edit with moduleId and moduleItemId', async () => {
        const event = new CustomEvent('module-action', {
          detail: {
            action: 'edit',
            courseId,
            moduleId,
            moduleItemId,
          },
        })

        document.dispatchEvent(event)

        // Allow any pending promises to resolve
        await new Promise(process.nextTick)

        expect(handleOpeningEditItemModal).toHaveBeenCalledWith(courseId, moduleId, moduleItemId)
      })

      it.skip('calls handleDeleteModule when action is delete with moduleId', () => {
        const event = new CustomEvent('module-action', {
          detail: {
            action: 'delete',
            courseId,
            moduleId,
          },
        })

        document.dispatchEvent(event)

        expect(handleDelete).toHaveBeenCalledWith(
          moduleId,
          'Test Module',
          expect.anything(), // queryClient
          courseId,
        )
      })

      it('calls handleNewModule when action is new', () => {
        const addModuleButton = document.querySelector(
          '#context-modules-header-add-module-button',
        ) as HTMLElement
        const clickSpy = vi.spyOn(addModuleButton, 'click')

        const event = new CustomEvent('module-action', {
          detail: {
            action: 'new',
            courseId,
          },
        })

        document.dispatchEvent(event)

        expect(clickSpy).toHaveBeenCalled()
      })
    })

    describe('module item actions', () => {
      it('calls upateIndent when action is indent', () => {
        const event = new CustomEvent('module-action', {
          detail: {
            action: 'indent',
            courseId,
            moduleId,
            moduleItemId,
          },
        })

        document.dispatchEvent(event)

        expect(updateIndent).toHaveBeenCalledWith(
          moduleItemId,
          moduleId,
          2,
          courseId,
          expect.anything(), // queryClient
        )
      })

      it('calls upateIndent when action is outdent', () => {
        const event = new CustomEvent('module-action', {
          detail: {
            action: 'outdent',
            courseId,
            moduleId,
            moduleItemId,
          },
        })

        document.dispatchEvent(event)

        expect(updateIndent).toHaveBeenCalledWith(
          moduleItemId,
          moduleId,
          0,
          courseId,
          expect.anything(), // queryClient
        )
      })

      it('calls handleRemove when action is remove', () => {
        const setIsMenuOpen = vi.fn()
        const onAfterSuccess = vi.fn()

        const event = new CustomEvent('module-action', {
          detail: {
            action: 'remove',
            courseId,
            moduleId,
            moduleItemId,
            setIsMenuOpen,
            onAfterSuccess,
          },
        })

        document.dispatchEvent(event)

        expect(handleRemove).toHaveBeenCalledWith(
          moduleId,
          moduleItemId,
          'Test Item',
          expect.anything(), // queryClient
          courseId,
          setIsMenuOpen,
          expect.any(Function), // enhanced callback
        )
      })

      it('handles remove action for item on page 2', () => {
        const setIsMenuOpen = vi.fn()
        const onAfterSuccess = vi.fn()

        const event = new CustomEvent('module-action', {
          detail: {
            action: 'remove',
            courseId,
            moduleId,
            moduleItemId: '4', // Item on page 2
            setIsMenuOpen,
            onAfterSuccess,
          },
        })

        document.dispatchEvent(event)

        expect(handleRemove).toHaveBeenCalledWith(
          moduleId,
          '4',
          'Test Item Page 2',
          expect.anything(), // queryClient
          courseId,
          setIsMenuOpen,
          expect.any(Function), // enhanced callback
        )
      })

      it('dispatches page navigation event when removing last item from non-first page', () => {
        const dispatchSpy = vi.spyOn(document, 'dispatchEvent')
        const setIsMenuOpen = vi.fn()
        const onAfterSuccess = vi.fn()

        const event = new CustomEvent('module-action', {
          detail: {
            action: 'remove',
            courseId,
            moduleId,
            moduleItemId: '5', // Last item on page 3
            setIsMenuOpen,
            onAfterSuccess,
          },
        })

        document.dispatchEvent(event)

        // Get the enhanced callback that was passed to handleRemove
        const handleRemoveCall = (handleRemove as any).mock.calls.find(
          (call: unknown[]) => call[1] === '5',
        )
        expect(handleRemoveCall).toBeDefined()
        const enhancedCallback = handleRemoveCall[6]

        // Clear previous dispatch calls
        dispatchSpy.mockClear()

        // Simulate successful removal by calling the enhanced callback
        enhancedCallback()

        // Should dispatch page navigation event
        expect(dispatchSpy).toHaveBeenCalledWith(
          expect.objectContaining({
            type: 'module-page-navigation',
            detail: {
              moduleId,
              pageNumber: 2, // Should go back to page 2 (from page 3)
            },
          }),
        )

        // Should also call original callback
        expect(onAfterSuccess).toHaveBeenCalled()
      })

      it('does not dispatch page navigation when removing item from first page', () => {
        const dispatchSpy = vi.spyOn(document, 'dispatchEvent')
        const onAfterSuccess = vi.fn()

        const event = new CustomEvent('module-action', {
          detail: {
            action: 'remove',
            courseId,
            moduleId,
            moduleItemId, // Item on first page
            onAfterSuccess,
          },
        })

        document.dispatchEvent(event)

        // Get the enhanced callback
        const handleRemoveCall = (handleRemove as any).mock.calls.find(
          (call: unknown[]) => call[1] === moduleItemId,
        )
        const enhancedCallback = handleRemoveCall[6]

        dispatchSpy.mockClear()

        // Simulate successful removal
        enhancedCallback()

        // Should not dispatch page navigation event (first page)
        const navigationEvents = dispatchSpy.mock.calls.filter(
          call => call[0].type === 'module-page-navigation',
        )
        expect(navigationEvents).toHaveLength(0)

        // Should still call original callback
        expect(onAfterSuccess).toHaveBeenCalled()
      })
    })
  })

  describe('getModuleItemFromCache', () => {
    it('finds module item from first page', () => {
      const result = modulePageCommandEventHandlers.getModuleItemFromCache(moduleId, moduleItemId)

      expect(result).toBeDefined()
      expect(result?.moduleItem._id).toBe(moduleItemId)
      expect(result?.moduleItem.title).toBe('Test Item')
      expect(result?.queryKey).toEqual([MODULE_ITEMS, moduleId, null])
    })

    it('finds module item from second page', () => {
      const result = modulePageCommandEventHandlers.getModuleItemFromCache(moduleId, '4')

      expect(result).toBeDefined()
      expect(result?.moduleItem._id).toBe('4')
      expect(result?.moduleItem.title).toBe('Test Item Page 2')
      expect(result?.queryKey).toEqual([MODULE_ITEMS, moduleId, btoa('10')])
    })

    it('finds module item from third page', () => {
      const result = modulePageCommandEventHandlers.getModuleItemFromCache(moduleId, '5')

      expect(result).toBeDefined()
      expect(result?.moduleItem._id).toBe('5')
      expect(result?.moduleItem.title).toBe('Last Item on Page')
      expect(result?.queryKey).toEqual([MODULE_ITEMS, moduleId, btoa('20')])
    })

    it('returns undefined for non-existent module item', () => {
      const result = modulePageCommandEventHandlers.getModuleItemFromCache(moduleId, 'non-existent')

      expect(result).toBeUndefined()
    })

    it('returns undefined for non-existent module', () => {
      const result = modulePageCommandEventHandlers.getModuleItemFromCache(
        'non-existent',
        moduleItemId,
      )

      expect(result).toBeUndefined()
    })
  })

  it.skip('does nothing for unknown actions', () => {
    const event = new CustomEvent('module-action', {
      detail: {
        action: 'unknown',
        courseId,
        moduleId,
      },
    })

    document.dispatchEvent(event)

    expect(handleDelete).not.toHaveBeenCalled()
    expect(handleOpeningModuleUpdateTray).not.toHaveBeenCalled()
  })
})
