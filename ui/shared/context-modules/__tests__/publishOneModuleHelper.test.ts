/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {findByText, getAllByText, waitFor} from '@testing-library/dom'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {updateModuleItem} from '../jquery/utils'
import publishOneModuleHelperModule from '../utils/publishOneModuleHelper'
import {initBody, makeModuleWithItems} from './testHelpers'
import type {KeyedModuleItems} from '../react/types'

const server = setupServer()

// tests fail if I don't mock the showAllOrLess module
// This has something to do with '../jquery/utils' importing
// the showAllOrLess module, but the imported function is never called
// so I don't know why this is necessary. it does make the tests pass.
jest.mock('../utils/showAllOrLess', () => ({
  addShowAllOrLess: jest.fn(),
}))

jest.mock('@canvas/relock-modules-dialog', () => {
  return jest.fn().mockImplementation(() => ({
    renderIfNeeded: jest.fn().mockImplementation(json => {
      if (json.relock_warning) {
        const dialog = document.createElement('div')
        dialog.className = 'relock-modules-dialog'
        document.body.appendChild(dialog)
      }
    }),
  }))
})

const {
  batchUpdateOneModuleApiCall,
  disableContextModulesPublishMenu,
  fetchModuleItemPublishedState,
  renderContextModulesPublishIcon,
  publishModule,
  unpublishModule,
  getAllModuleItems,
  updateModuleItemsPublishedStates,
  updateModuleItemPublishedState,
} = {
  ...publishOneModuleHelperModule,
}

jest.mock('../jquery/utils', () => {
  const originalModule = jest.requireActual('../jquery/utils')
  return {
    __esmodule: true,
    ...originalModule,
    updateModuleItem: jest.fn(),
  }
})

const updatePublishMenuDisabledState = jest.fn()

describe('publishOneModuleHelper', () => {
  beforeAll(() => {
    server.listen()
    // @ts-expect-error
    window.modules = {
      updatePublishMenuDisabledState,
      initModuleManagement: () => Promise.resolve(),
    }
  })

  afterAll(() => server.close())

  beforeEach(() => {
    server.use(
      http.put('/api/v1/courses/:courseId/modules/:moduleId', () => {
        return HttpResponse.json({published: true})
      }),
      http.get('/api/v1/courses/:courseId/modules/:moduleId/items', () => {
        return HttpResponse.json([
          {id: '117', published: true},
          {id: '119', published: true},
        ])
      }),
    )
    initBody()
  })

  afterEach(() => {
    server.resetHandlers()
    jest.clearAllMocks()
    document.body.innerHTML = ''
  })

  describe('publishModule', () => {
    let spy: jest.SpyInstance
    beforeEach(() => {
      spy = jest.spyOn(publishOneModuleHelperModule, 'batchUpdateOneModuleApiCall')
      makeModuleWithItems(1, [117, 119], false)
    })
    afterEach(() => {
      spy.mockRestore()
    })
    it('calls batchUpdateOneModuleApiCall with the correct argumets', async () => {
      const spy = jest.spyOn(publishOneModuleHelperModule, 'batchUpdateOneModuleApiCall')
      const courseId = 1
      const moduleId = 1
      let skipItems = false
      const onPublishComplete = () => {}
      const setIsPublishing = () => {}
      const moduleIsPublished = false
      publishModule({
        courseId,
        moduleId,
        skipItems,
        onPublishComplete,
        setIsPublishing,
        moduleIsPublished,
      })
      expect(spy).toHaveBeenCalledWith(
        courseId,
        moduleId,
        true,
        skipItems,
        'Publishing module and items',
        'Module and items published',
        onPublishComplete,
        setIsPublishing,
        moduleIsPublished,
      )
      spy.mockClear()
      skipItems = true
      publishModule({
        courseId,
        moduleId,
        skipItems,
        onPublishComplete,
        setIsPublishing,
        moduleIsPublished,
      })
      expect(spy).toHaveBeenCalledWith(
        courseId,
        moduleId,
        true,
        skipItems,
        'Publishing module',
        'Module published',
        onPublishComplete,
        setIsPublishing,
        moduleIsPublished,
      )
    })
  })

  describe('unpublishModule', () => {
    let spy: jest.SpyInstance
    beforeEach(() => {
      spy = jest.spyOn(publishOneModuleHelperModule, 'batchUpdateOneModuleApiCall')
      makeModuleWithItems(1, [117, 119], false)
    })
    afterEach(() => {
      spy.mockRestore()
    })
    it('calls batchUpdateOneModuleApiCall with the correct argumets', async () => {
      const courseId = 1
      const moduleId = 1
      const skipItems = false
      const onPublishComplete = () => {}
      const setIsPublishing = () => {}
      const moduleIsPublished = false
      unpublishModule({
        courseId,
        moduleId,
        skipItems,
        onPublishComplete,
        setIsPublishing,
        moduleIsPublished,
      })
      expect(spy).toHaveBeenCalledWith(
        courseId,
        moduleId,
        false,
        skipItems,
        'Unpublishing module and items',
        'Module and items unpublished',
        onPublishComplete,
        setIsPublishing,
        moduleIsPublished,
      )
    })
  })

  describe('batchUpdateOneModuleApiCall', () => {
    let spy: jest.SpyInstance | null = null
    const spy2: jest.SpyInstance | null = null
    beforeEach(() => {
      makeModuleWithItems(1, [117, 119], false)
      makeModuleWithItems(2, [217, 219], true)
    })
    afterEach(() => {
      spy?.mockRestore()
      // @ts-expect-error
      spy2?.mockRestore()
    })

    it('PUTS the batch request then GETs the updated results', async () => {
      let putCalled = false
      let getCalled = false

      server.use(
        http.put('/api/v1/courses/1/modules/2', async ({request}) => {
          const body = await request.json()
          expect(body).toEqual({
            module: {
              published: false,
              skip_content_tags: true,
            },
          })
          putCalled = true
          return HttpResponse.json({published: true})
        }),
        http.get('/api/v1/courses/1/modules/2/items', () => {
          getCalled = true
          return HttpResponse.json([
            {id: '117', published: true},
            {id: '119', published: true},
          ])
        }),
      )

      await batchUpdateOneModuleApiCall(1, 2, false, true, 'loading message', 'success message')

      expect(putCalled).toBe(true)
      expect(getCalled).toBe(true)
    })

    it('disables the "Publish All" button while running', async () => {
      spy = jest.spyOn(publishOneModuleHelperModule, 'disableContextModulesPublishMenu')
      await batchUpdateOneModuleApiCall(1, 2, false, true, 'loading message', 'success message')
      expect(spy).toHaveBeenCalledTimes(2)
      expect(spy).toHaveBeenCalledWith(true)
      expect(spy).toHaveBeenCalledWith(false)
    })

    it('renders the modules publish button', async () => {
      spy = jest.spyOn(publishOneModuleHelperModule, 'renderContextModulesPublishIcon')
      await batchUpdateOneModuleApiCall(1, 2, false, true, 'loading message', 'success message')
      expect(spy).toHaveBeenCalledTimes(2)
      expect(spy).toHaveBeenCalledWith(1, 2, true, true, 'loading message')
      expect(spy).toHaveBeenCalledWith(1, 2, true, false, 'loading message')
    })

    it('updates the module items when skipping item update', async () => {
      spy = jest.spyOn(publishOneModuleHelperModule, 'updateModuleItemsPublishedStates')
      await batchUpdateOneModuleApiCall(1, 2, false, true, 'loading message', 'success message')
      await waitFor(() => {
        expect(spy).toHaveBeenCalledTimes(1)
        expect(spy).toHaveBeenCalledWith(2, undefined, true)
      })
    })

    it('updates the module items when publishing item update', async () => {
      spy = jest.spyOn(publishOneModuleHelperModule, 'fetchModuleItemPublishedState')
      await batchUpdateOneModuleApiCall(1, 2, false, false, 'loading message', 'success message')
      expect(spy).toHaveBeenCalledTimes(1)
      expect(spy).toHaveBeenCalledWith(1, 2)
    })

    it('shows an alert if not all items were published', async () => {
      server.use(
        http.put('/api/v1/courses/1/modules/2', () => {
          return HttpResponse.json({published: true, publish_warning: true})
        }),
      )

      await batchUpdateOneModuleApiCall(1, 2, false, true, 'loading message', 'success message')
      await waitFor(() => {
        expect(
          getAllByText(document.body, 'Some module items could not be published'),
        ).toHaveLength(2)
      })
    })

    it('shows an alert if the publish failed', async () => {
      server.use(
        http.put('/api/v1/courses/1/modules/1', () => {
          return HttpResponse.error()
        }),
      )

      await batchUpdateOneModuleApiCall(1, 1, true, true, 'loading message', 'success message')
      await waitFor(() => {
        expect(
          getAllByText(document.body, 'There was an error while saving your changes'),
        ).toHaveLength(2)
      })
    })

    it('shows the re-lock modal when necessary', async () => {
      server.use(
        http.put('/api/v1/courses/1/modules/2', () => {
          return HttpResponse.json({published: true, relock_warning: true})
        }),
      )

      await batchUpdateOneModuleApiCall(1, 2, false, true, 'loading message', 'success message')
      await waitFor(() => {
        expect(document.querySelector('.relock-modules-dialog')).toBeInTheDocument()
      })
    })
  })

  describe('fetchModuleItemPublishedState', () => {
    beforeEach(() => {
      makeModuleWithItems(1, [117, 119], false)
    })

    it('GETs the module item states', async () => {
      let getCalled = false
      server.use(
        http.get('/api/v1/courses/1/modules/1/items', () => {
          getCalled = true
          return HttpResponse.json([{id: '117', published: true}])
        }),
      )

      await fetchModuleItemPublishedState(1, 1)
      expect(getCalled).toBe(true)
    })

    it('exhausts paginated responses', async () => {
      let firstCallMade = false
      let secondCallMade = false

      server.use(
        http.get('/api/v1/courses/1/modules/1/items', () => {
          firstCallMade = true
          return HttpResponse.json([{id: '117', published: true}], {
            headers: {
              Link: '<http://localhost/next-page>; rel="next"',
            },
          })
        }),
        http.get('/next-page', () => {
          secondCallMade = true
          return HttpResponse.json([{id: '119', published: true}])
        }),
      )

      await fetchModuleItemPublishedState(1, 1)
      expect(firstCallMade).toBe(true)
      expect(secondCallMade).toBe(true)
    })
  })

  describe('updateModuleItemsPublishedStates', () => {
    let allModuleItems: KeyedModuleItems
    beforeEach(() => {
      makeModuleWithItems(1, [117, 119])
      makeModuleWithItems(2, [217, 219, 117])
      allModuleItems = getAllModuleItems()
    })

    it('calls updateModuleItemPublishedState for each module item', () => {
      const spy = jest.spyOn(publishOneModuleHelperModule, 'updateModuleItemPublishedState')
      const published = true
      const isPublishing = false

      updateModuleItemsPublishedStates(1, published, isPublishing)
      expect(spy).toHaveBeenCalledTimes(2)
      expect(spy).toHaveBeenCalledWith(
        expect.any(HTMLElement),
        published,
        isPublishing,
        allModuleItems,
      )
      expect(spy).toHaveBeenCalledWith(
        expect.any(HTMLElement),
        published,
        isPublishing,
        allModuleItems,
      )
      expect((spy.mock.calls[0][0] as HTMLElement).getAttribute('data-module-item-id')).toEqual(
        '1117',
      )
      expect((spy.mock.calls[1][0] as HTMLElement).getAttribute('data-module-item-id')).toEqual(
        '1119',
      )
    })

    it('does not change published state if undefined', () => {
      const spy = jest.spyOn(publishOneModuleHelperModule, 'updateModuleItemPublishedState')
      const published = undefined
      const isPublishing = true

      updateModuleItemsPublishedStates(1, published, isPublishing)
      expect(spy).toHaveBeenCalledTimes(2)
      expect(updateModuleItem).toHaveBeenCalledTimes(2)
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_117: expect.any(Object)}),
        {bulkPublishInFlight: isPublishing},
        expect.any(Object),
      )
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_119: expect.any(Object)}),
        {bulkPublishInFlight: isPublishing},
        expect.any(Object),
      )
    })
  })

  describe('updateModuleItemPublishedState', () => {
    beforeEach(() => {
      makeModuleWithItems(1, [117, 119])
      makeModuleWithItems(2, [217, 219, 117])
    })

    it('calls updateModuleItem with all items for the same assignment', () => {
      const published = true
      const isPublishing = false
      const allModuleItems = getAllModuleItems()

      updateModuleItemPublishedState('1117', published, isPublishing, allModuleItems)
      expect(updateModuleItem).toHaveBeenCalledWith(
        {assignment_117: allModuleItems.assignment_117},
        {bulkPublishInFlight: isPublishing, published},
        expect.anything(), // view.model
      )
    })

    it("builds it's own 'items' array if none are given", () => {
      const published = true
      const isPublishing = false

      updateModuleItemPublishedState('1117', published, isPublishing)
      expect(updateModuleItem).toHaveBeenCalledWith(
        {assignment_117: [{view: expect.anything(), model: expect.anything()}]},
        {bulkPublishInFlight: isPublishing, published},
        expect.anything(), // view.model
      )
    })

    it('omits "published" from updatedAttrs if called with isPublished undefined', () => {
      const isPublishing = true
      updateModuleItemPublishedState('1117', undefined, isPublishing)
      expect(updateModuleItem).toHaveBeenCalledWith(
        {assignment_117: [{view: expect.anything(), model: expect.anything()}]},
        {bulkPublishInFlight: isPublishing},
        expect.anything(), // view.model
      )
    })

    it('sets ig-published class on the item row if published', () => {
      updateModuleItemPublishedState('1117', true, false)
      expect(
        document
          .querySelector('#context_module_item_1117 .ig-row')
          ?.classList.contains('ig-published'),
      ).toBe(true)

      updateModuleItemPublishedState('1117', false, false)
      expect(
        document
          .querySelector('#context_module_item_1117 .ig-row')
          ?.classList.contains('ig-published'),
      ).toBe(false)
    })

    it('sets ig-published class on the row of all matching items', () => {
      const allModuleItems = getAllModuleItems()
      updateModuleItemPublishedState('1117', true, false, allModuleItems)

      expect(
        document
          .querySelector('#context_module_item_1117 .ig-row')
          ?.classList.contains('ig-published'),
      ).toBe(true)
      expect(
        document
          .querySelector('#context_module_item_2117 .ig-row')
          ?.classList.contains('ig-published'),
      ).toBe(true)

      updateModuleItemPublishedState('1117', false, false, allModuleItems)
      expect(
        document
          .querySelector('#context_module_item_1117 .ig-row')
          ?.classList.contains('ig-published'),
      ).toBe(false)
      expect(
        document
          .querySelector('#context_module_item_2117 .ig-row')
          ?.classList.contains('ig-published'),
      ).toBe(false)
    })
  })

  describe('disableContextModulesPublishMenu', () => {
    it('calls the global function', () => {
      disableContextModulesPublishMenu(true)
      expect(updatePublishMenuDisabledState).toHaveBeenCalledWith(true)
      updatePublishMenuDisabledState.mockReset()
      disableContextModulesPublishMenu(false)
      expect(updatePublishMenuDisabledState).toHaveBeenCalledWith(false)
    })
  })

  describe('renderContextModulesPublishIcon', () => {
    beforeEach(() => {
      makeModuleWithItems(2, [217, 219], false)
    })
    it('renders the ContextModulesPublishIcon', async () => {
      renderContextModulesPublishIcon(1, 2, true, false, 'loading message')
      expect(
        await findByText(document.body, 'Lesson 2 module publish options, published'),
      ).toBeInTheDocument()
    })
  })

  describe('getAllModuleItems', () => {
    beforeEach(() => {
      makeModuleWithItems(1, [117, 119])
      makeModuleWithItems(2, [217, 219, 117])
    })

    it('finds all the module items', () => {
      const allModuleItems = getAllModuleItems()
      expect(allModuleItems.assignment_117).toHaveLength(2)
      expect(allModuleItems.assignment_119).toHaveLength(1)
      expect(allModuleItems.assignment_217).toHaveLength(1)
      expect(allModuleItems.assignment_219).toHaveLength(1)
    })
  })
})
