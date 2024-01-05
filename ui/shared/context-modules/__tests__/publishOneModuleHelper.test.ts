// @ts-nocheck
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

import {getByText, getAllByText, waitFor} from '@testing-library/dom'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {updateModuleItem} from '../jquery/utils'
import publishOneModuleHelperModule from '../utils/publishOneModuleHelper'
import {initBody, makeModuleWithItems} from './testHelpers'

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

jest.mock('@canvas/do-fetch-api-effect')

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
    // @ts-expect-error
    window.modules = {
      updatePublishMenuDisabledState,
    }
  })

  beforeEach(() => {
    doFetchApi.mockResolvedValue({response: {ok: true}, json: {published: true}})
    initBody()
  })

  afterEach(() => {
    jest.clearAllMocks()
    doFetchApi.mockReset()
    document.body.innerHTML = ''
  })

  describe('publishModule', () => {
    let spy
    beforeEach(() => {
      spy = jest.spyOn(publishOneModuleHelperModule, 'batchUpdateOneModuleApiCall')
      makeModuleWithItems(1, 'Lesson 2', [117, 119], false)
    })
    afterEach(() => {
      spy.mockRestore()
    })
    it('calls batchUpdateOneModuleApiCall with the correct argumets', () => {
      const spy = jest.spyOn(publishOneModuleHelperModule, 'batchUpdateOneModuleApiCall')
      const courseId = 1
      const moduleId = 1
      let skipItems = false
      publishModule(courseId, moduleId, skipItems)
      expect(spy).toHaveBeenCalledWith(
        courseId,
        moduleId,
        true,
        skipItems,
        'Publishing module and items',
        'Module and items published'
      )
      spy.mockClear()
      skipItems = true
      publishModule(courseId, moduleId, skipItems)
      expect(spy).toHaveBeenCalledWith(
        courseId,
        moduleId,
        true,
        skipItems,
        'Publishing module',
        'Module published'
      )
    })
  })

  describe('unpublishModule', () => {
    let spy
    beforeEach(() => {
      spy = jest.spyOn(publishOneModuleHelperModule, 'batchUpdateOneModuleApiCall')
      makeModuleWithItems(1, 'Lesson 2', [117, 119], false)
    })
    afterEach(() => {
      spy.mockRestore()
    })
    it('calls batchUpdateOneModuleApiCall with the correct argumets', () => {
      const courseId = 1
      const moduleId = 1
      const skipItems = false
      unpublishModule(courseId, moduleId, skipItems)
      expect(spy).toHaveBeenCalledWith(
        courseId,
        moduleId,
        false,
        skipItems,
        'Unpublishing module and items',
        'Module and items unpublished'
      )
    })
  })

  describe('batchUpdateOneModuleApiCall', () => {
    let spy, spy2
    beforeEach(() => {
      makeModuleWithItems(1, 'Lesson 2', [117, 119], false)
      makeModuleWithItems(2, 'Lesson 2', [217, 219], true)

      // the batch update
      doFetchApi.mockResolvedValueOnce({response: {ok: true}, json: {published: true}})
    })
    afterEach(() => {
      spy?.mockRestore()
      spy2?.mockRestore()
    })

    it('PUTS the batch request then GETs the updated results', async () => {
      doFetchApi.mockResolvedValueOnce({
        json: [
          {id: '117', published: true},
          {id: '119', published: true},
        ],
        link: null,
      })
      await batchUpdateOneModuleApiCall(1, 2, false, true, 'loading message', 'success message')

      expect(doFetchApi).toHaveBeenCalledTimes(2)
      expect(doFetchApi).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'PUT',
          path: '/api/v1/courses/1/modules/2',
          body: {
            module: {
              published: false,
              skip_content_tags: true,
            },
          },
        })
      )
      expect(doFetchApi).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'GET',
          path: '/api/v1/courses/1/modules/2/items',
        })
      )
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
      doFetchApi.mockResolvedValueOnce({
        json: [{id: '117', published: true}],
        link: {next: {url: '/another/page'}},
      })
      doFetchApi.mockResolvedValueOnce({
        json: [{id: '119', published: true}],
        link: null,
      })
      spy = jest.spyOn(publishOneModuleHelperModule, 'updateModuleItemsPublishedStates')
      spy2 = jest.spyOn(publishOneModuleHelperModule, 'updateModuleItemPublishedState')
      await batchUpdateOneModuleApiCall(1, 1, true, true, 'loading message', 'success message')
      expect(spy).toHaveBeenCalledTimes(1)
      expect(spy).toHaveBeenCalledWith(1, undefined, true)
      // one for each item when disabling before the update +
      // one for each item after the fetch completes (which happens over 2 pages)
      // even if skipItems is true
      expect(spy2).toHaveBeenCalledTimes(4)
    })

    it('updates the module items when publishing item update', async () => {
      doFetchApi.mockResolvedValueOnce({
        json: [{id: '117', published: true}],
        link: {next: {url: '/another/page'}},
      })
      doFetchApi.mockResolvedValueOnce({
        json: [{id: '119', published: true}],
        link: null,
      })
      spy = jest.spyOn(publishOneModuleHelperModule, 'updateModuleItemsPublishedStates')
      spy2 = jest.spyOn(publishOneModuleHelperModule, 'updateModuleItemPublishedState')
      await batchUpdateOneModuleApiCall(1, 1, true, false, 'loading message', 'success message')
      expect(spy).toHaveBeenCalledTimes(1)
      expect(spy).toHaveBeenCalledWith(1, undefined, true)
      expect(spy2).toHaveBeenCalledTimes(4)
    })

    it('shows an alert if not all items were published', async () => {
      doFetchApi.mockReset()
      doFetchApi.mockResolvedValueOnce({
        response: {ok: true},
        json: {published: true, publish_warning: true},
      })

      await batchUpdateOneModuleApiCall(1, 1, true, true, 'loading message', 'success message')
      expect(getAllByText(document.body, 'Some module items could not be published')).toHaveLength(
        2
      ) // one visual, one screenreader alert
    })

    it('shows an alert if the publish failed', async () => {
      doFetchApi.mockRejectedValueOnce(new Error('whoops'))

      await batchUpdateOneModuleApiCall(1, 1, true, true, 'loading message', 'success message')
      expect(
        getAllByText(document.body, 'There was an error while saving your changes')
      ).toHaveLength(2) // one visual, one screenreader alert
    })

    it('shows the re-lock modal when necessary', async () => {
      doFetchApi.mockResolvedValueOnce({
        response: {ok: true},
        json: {published: true, relock_warning: true},
      })

      await batchUpdateOneModuleApiCall(1, 1, true, true, 'loading message', 'success message')
      expect(
        // @ts-expect-error
        getByText(document.querySelector('.ui-dialog'), 'Requirements Changed')
      ).toBeInTheDocument()
    })
  })

  describe('updateModuleItemsPublishedStates', () => {
    let allModuleItems
    beforeEach(() => {
      makeModuleWithItems(1, 'Lesson 2', [117, 119])
      makeModuleWithItems(2, 'Lesson 2', [217, 219, 117])
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
        allModuleItems
      )
      expect(spy).toHaveBeenCalledWith(
        expect.any(HTMLElement),
        published,
        isPublishing,
        allModuleItems
      )
      expect((spy.mock.calls[0][0] as HTMLElement).getAttribute('data-module-item-id')).toEqual(
        '1117'
      )
      expect((spy.mock.calls[1][0] as HTMLElement).getAttribute('data-module-item-id')).toEqual(
        '1119'
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
        expect.any(Object)
      )
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_119: expect.any(Object)}),
        {bulkPublishInFlight: isPublishing},
        expect.any(Object)
      )
    })
  })

  describe('updateModuleItemPublishedState', () => {
    beforeEach(() => {
      makeModuleWithItems(1, 'Lesson 2', [117, 119])
      makeModuleWithItems(2, 'Lesson 2', [217, 219, 117])
    })

    it('calls updateModuleItem with all items for the same assignment', () => {
      const published = true
      const isPublishing = false
      const allModuleItems = getAllModuleItems()

      updateModuleItemPublishedState('1117', published, isPublishing, allModuleItems)
      expect(updateModuleItem).toHaveBeenCalledWith(
        {assignment_117: allModuleItems.assignment_117},
        {bulkPublishInFlight: isPublishing, published},
        expect.anything() // view.model
      )
    })

    it("builds it's own 'items' array if none are given", () => {
      const published = true
      const isPublishing = false

      updateModuleItemPublishedState('1117', published, isPublishing)
      expect(updateModuleItem).toHaveBeenCalledWith(
        {assignment_117: [{view: expect.anything(), model: expect.anything()}]},
        {bulkPublishInFlight: isPublishing, published},
        expect.anything() // view.model
      )
    })

    it('omits "published" from updatedAttrs if called with isPublished undefined', () => {
      const isPublishing = true
      updateModuleItemPublishedState('1117', undefined, isPublishing)
      expect(updateModuleItem).toHaveBeenCalledWith(
        {assignment_117: [{view: expect.anything(), model: expect.anything()}]},
        {bulkPublishInFlight: isPublishing},
        expect.anything() // view.model
      )
    })

    it('sets ig-published class on the item row if published', () => {
      updateModuleItemPublishedState('1117', true, false)
      expect(
        document
          .querySelector('#context_module_item_1117 .ig-row')
          ?.classList.contains('ig-published')
      ).toBe(true)

      updateModuleItemPublishedState('1117', false, false)
      expect(
        document
          .querySelector('#context_module_item_1117 .ig-row')
          ?.classList.contains('ig-published')
      ).toBe(false)
    })

    it('sets ig-published class on the row of all matching items', () => {
      const allModuleItems = getAllModuleItems()
      updateModuleItemPublishedState('1117', true, false, allModuleItems)

      expect(
        document
          .querySelector('#context_module_item_1117 .ig-row')
          ?.classList.contains('ig-published')
      ).toBe(true)
      expect(
        document
          .querySelector('#context_module_item_2117 .ig-row')
          ?.classList.contains('ig-published')
      ).toBe(true)

      updateModuleItemPublishedState('1117', false, false, allModuleItems)
      expect(
        document
          .querySelector('#context_module_item_1117 .ig-row')
          ?.classList.contains('ig-published')
      ).toBe(false)
      expect(
        document
          .querySelector('#context_module_item_2117 .ig-row')
          ?.classList.contains('ig-published')
      ).toBe(false)
    })
  })

  describe('fetchModuleItemPublishedState', () => {
    beforeEach(() => {
      doFetchApi.mockReset()
      doFetchApi.mockResolvedValue({response: {ok: true}, json: [], link: null})
    })
    it('GETs the module item states', () => {
      fetchModuleItemPublishedState(7, 8)
      expect(doFetchApi).toHaveBeenCalledTimes(1)
      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'GET',
        path: '/api/v1/courses/7/modules/8/items',
      })
    })
    it('exhausts paginated responses', async () => {
      doFetchApi.mockResolvedValueOnce({
        response: {ok: true},
        json: [{id: '1', published: true}],
        link: {next: {url: '/another/page'}},
      })

      fetchModuleItemPublishedState(7, 8)
      await waitFor(() => expect(doFetchApi).toHaveBeenCalledTimes(2))
      expect(doFetchApi).toHaveBeenLastCalledWith({
        method: 'GET',
        path: '/another/page',
      })
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
      makeModuleWithItems(2, 'Lesson 2', [217, 219], false)
    })
    it('renders the ContextModulesPublishIcon', () => {
      renderContextModulesPublishIcon(1, 2, true, false, 'loading message')
      expect(
        getByText(document.body, 'Lesson 2 module publish options, published')
      ).toBeInTheDocument()
    })
  })

  describe('getAllModuleItems', () => {
    beforeEach(() => {
      makeModuleWithItems(1, 'Lesson 2', [117, 119])
      makeModuleWithItems(2, 'Lesson 2', [217, 219, 117])
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
