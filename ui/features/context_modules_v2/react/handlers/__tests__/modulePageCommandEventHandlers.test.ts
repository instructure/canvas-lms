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

import {handleDelete} from '../moduleActionHandlers'
import {handleOpeningModuleUpdateTray} from '../modulePageActionHandlers'
import {dispatchCommandEvent} from '../modulePageCommandEventHandlers'

// Mock the handlers
jest.mock('../moduleActionHandlers')
jest.mock('../modulePageActionHandlers')

// Mock the query client methods
const mockGetQueryData = jest.fn()
const mockEnsureQueryData = jest.fn()

jest.mock('@canvas/query', () => ({
  queryClient: {
    getQueryData: (...args: any[]) => mockGetQueryData(...args),
    ensureQueryData: (...args: any[]) => mockEnsureQueryData(...args),
  },
}))

describe('modulePageCommandEventHandlers', () => {
  const courseId = '1'
  const moduleId = '2'

  afterEach(() => {
    jest.clearAllMocks()
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
      const dispatchSpy = jest.spyOn(document, 'dispatchEvent')
      const action = 'edit' as const

      dispatchCommandEvent(action, courseId, moduleId)

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

        // Mock the query client responses
        mockGetQueryData.mockReturnValue(mockModulesData)
        mockEnsureQueryData.mockResolvedValue([])

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

        expect(mockGetQueryData).toHaveBeenCalledWith(['modules', courseId])
        expect(mockEnsureQueryData).toHaveBeenCalled()
        expect(handleOpeningModuleUpdateTray).toHaveBeenCalledWith(
          mockModulesData,
          courseId,
          moduleId,
          'Test Module',
          'settings',
          [],
        )
      })

      it('calls handleDeleteModule when action is delete with moduleId', () => {
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
        const clickSpy = jest.spyOn(addModuleButton, 'click')

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
  })

  it('does nothing for unknown actions', () => {
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
