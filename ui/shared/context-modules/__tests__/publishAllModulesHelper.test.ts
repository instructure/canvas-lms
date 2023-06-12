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

import {waitFor} from '@testing-library/dom'
import doFetchApi from '@canvas/do-fetch-api-effect'
import publishOneModuleHelperModule from '../utils/publishOneModuleHelper'

import publishAllModulesHelperModule from '../utils/publishAllModulesHelper'
import {initBody, makeModuleWithItems} from './testHelpers'

const {
  batchUpdateAllModulesApiCall,
  monitorProgress,
  cancelBatchUpdate,
  fetchAllItemPublishedStates,
  updateModulePendingPublishedStates,
  updateModulePublishedState,
  moduleIds,
} = {
  ...publishAllModulesHelperModule,
}

const {renderContextModulesPublishIcon} = {
  ...publishOneModuleHelperModule,
}

jest.mock('@canvas/do-fetch-api-effect')
jest.mock('../utils/publishOneModuleHelper')

describe('publishAllModulesHelper', () => {
  beforeEach(() => {
    doFetchApi.mockResolvedValue({response: {ok: true}, json: {published: true}})
    initBody()
  })

  afterEach(() => {
    jest.clearAllMocks()
    doFetchApi.mockReset()
    document.body.innerHTML = ''
  })

  describe('batchUpdateAllModulesApiCall', () => {
    beforeEach(() => {
      makeModuleWithItems(1, 'Lesson 2', [117, 119], false)
      makeModuleWithItems(2, 'Lesson 2', [217, 219], true)
    })

    it('PUTS the batch request', async () => {
      const publish = true
      const skipItems = true
      await batchUpdateAllModulesApiCall(1, publish, skipItems)

      expect(doFetchApi).toHaveBeenCalledTimes(1)
      expect(doFetchApi).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'PUT',
          path: '/api/v1/courses/1/modules',
          body: {
            module_ids: [1, 2],
            event: 'publish',
            skip_content_tags: skipItems,
            async: true,
          },
        })
      )
    })

    it('returns a rejected promise on error', async () => {
      const whoops = new Error('whoops')
      doFetchApi.mockRejectedValueOnce(whoops)
      await expect(batchUpdateAllModulesApiCall(2, true, true)).rejects.toBe(whoops)
    })
  })

  describe('monitorProgress', () => {
    beforeAll(() => {
      jest.useFakeTimers()
    })

    afterEach(() => {
      doFetchApi.mockRestore()
    })

    it('polls for progress until completed', async () => {
      doFetchApi.mockResolvedValueOnce({
        json: {
          id: '3533',
          workflow_state: 'queued',
          url: '/api/v1/progress/3533',
        },
      })
      doFetchApi.mockResolvedValueOnce({
        json: {
          id: '3533',
          workflow_state: 'running',
          url: '/api/v1/progress/3533',
        },
      })
      doFetchApi.mockResolvedValueOnce({
        json: {
          id: '3533',
          workflow_state: 'completed',
          url: '/api/v1/progress/3533',
        },
      })

      const setCurrentProgress = jest.fn()
      monitorProgress(3533, setCurrentProgress, () => {})
      await waitFor(() => expect(setCurrentProgress).toHaveBeenCalledTimes(1))
      expect(doFetchApi).toHaveBeenCalledTimes(1)
      expect(doFetchApi).toHaveBeenNthCalledWith(1, {path: '/api/v1/progress/3533'})
      jest.runOnlyPendingTimers()
      await waitFor(() => expect(setCurrentProgress).toHaveBeenCalledTimes(2))
      expect(doFetchApi).toHaveBeenCalledTimes(2)
      expect(doFetchApi).toHaveBeenNthCalledWith(2, {path: '/api/v1/progress/3533'})
      jest.runOnlyPendingTimers()
      await waitFor(() => expect(setCurrentProgress).toHaveBeenCalledTimes(3))
      expect(doFetchApi).toHaveBeenCalledTimes(3)
      expect(doFetchApi).toHaveBeenNthCalledWith(3, {path: '/api/v1/progress/3533'})
      jest.runOnlyPendingTimers()
    })

    it('polls for progress until failed', async () => {
      doFetchApi.mockResolvedValueOnce({
        json: {
          id: '3533',
          workflow_state: 'queued',
          url: '/api/v1/progress/3533',
        },
      })
      doFetchApi.mockResolvedValueOnce({
        json: {
          id: '3533',
          workflow_state: 'failed',
          url: '/api/v1/progress/3533',
        },
      })

      const setCurrentProgress = jest.fn()
      monitorProgress(3533, setCurrentProgress, () => {})
      await waitFor(() => expect(setCurrentProgress).toHaveBeenCalledTimes(1))
      expect(doFetchApi).toHaveBeenCalledTimes(1)
      expect(doFetchApi).toHaveBeenNthCalledWith(1, {path: '/api/v1/progress/3533'})
      jest.runOnlyPendingTimers()
      await waitFor(() => expect(setCurrentProgress).toHaveBeenCalledTimes(2))
      expect(doFetchApi).toHaveBeenCalledTimes(2)
      expect(doFetchApi).toHaveBeenNthCalledWith(2, {path: '/api/v1/progress/3533'})
      jest.runOnlyPendingTimers()
    })

    it('calls onProgressFail on a catestrophic failure', async () => {
      const err = new Error('whoops')
      doFetchApi.mockRejectedValueOnce(err)
      const onProgressFail = jest.fn()
      monitorProgress(3533, () => {}, onProgressFail)
      await waitFor(() => expect(onProgressFail).toHaveBeenCalledWith(err))
    })
  })

  describe('cancelBatchUpdate', () => {
    beforeEach(() => {
      doFetchApi.mockResolvedValue({})
    })

    it('bails out of no progress is provided', () => {
      const onCancelComplete = jest.fn()
      cancelBatchUpdate(undefined, onCancelComplete)
      expect(onCancelComplete).toHaveBeenCalledTimes(0)
      expect(doFetchApi).toHaveBeenCalledTimes(0)
    })

    it('bails out if the progress has already completed', () => {
      const onCancelComplete = jest.fn()
      cancelBatchUpdate({workflow_state: 'completed'}, onCancelComplete)
      expect(onCancelComplete).toHaveBeenCalledTimes(0)
      expect(doFetchApi).toHaveBeenCalledTimes(0)
    })

    it('bails out if the progress has already failed', () => {
      const onCancelComplete = jest.fn()
      cancelBatchUpdate({workflow_state: 'failed'}, onCancelComplete)
      expect(onCancelComplete).toHaveBeenCalledTimes(0)
      expect(doFetchApi).toHaveBeenCalledTimes(0)
    })

    it('cancels the progress', async () => {
      const onCancelComplete = jest.fn()
      cancelBatchUpdate({id: '17', workflow_state: 'running'}, onCancelComplete)
      expect(doFetchApi).toHaveBeenCalledTimes(1)
      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'POST',
        path: '/api/v1/progress/17/cancel',
        body: {message: 'canceled'},
      })
      await waitFor(() => expect(onCancelComplete).toHaveBeenCalled())
      expect(onCancelComplete).toHaveBeenCalledTimes(1)
      expect(onCancelComplete).toHaveBeenCalledWith()
    })

    it('calls onCancelComplete with the error on failure', async () => {
      doFetchApi.mockRejectedValueOnce('whoops')
      const onCancelComplete = jest.fn()
      cancelBatchUpdate({id: '17', workflow_state: 'running'}, onCancelComplete)
      expect(doFetchApi).toHaveBeenCalledTimes(1)
      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'POST',
        path: '/api/v1/progress/17/cancel',
        body: {message: 'canceled'},
      })
      await waitFor(() => expect(onCancelComplete).toHaveBeenCalled())
      expect(onCancelComplete).toHaveBeenCalledTimes(1)
      expect(onCancelComplete).toHaveBeenCalledWith('whoops')
    })
  })

  describe('fetchAllItemPublishedStates', () => {
    beforeEach(() => {
      doFetchApi.mockReset()
      doFetchApi.mockResolvedValue({response: {ok: true}, json: [], link: null})
    })
    it('GETs the module item states', () => {
      fetchAllItemPublishedStates(7)
      expect(doFetchApi).toHaveBeenCalledTimes(1)
      expect(doFetchApi).toHaveBeenCalledWith({
        method: 'GET',
        path: '/api/v1/courses/7/modules?include[]=items',
      })
    })
    it('exhausts paginated responses', async () => {
      doFetchApi.mockResolvedValueOnce({
        response: {ok: true},
        json: [{id: 1, published: true, items: []}],
        link: {next: {url: '/another/page'}},
      })

      fetchAllItemPublishedStates(7)
      await waitFor(() => expect(doFetchApi).toHaveBeenCalledTimes(2))
      expect(doFetchApi).toHaveBeenLastCalledWith({
        method: 'GET',
        path: '/another/page',
      })
    })
    it('returns a rejected promise on error', async () => {
      const whoops = new Error('whoops')
      doFetchApi.mockRejectedValueOnce(whoops)
      await expect(fetchAllItemPublishedStates(7)).rejects.toBe(whoops)
    })
  })

  describe('updateModulePendingPublishedStates', () => {
    let updateModuleSpy, updateItemsSpy
    beforeEach(() => {
      makeModuleWithItems(1, 'Lesson 2', [117, 119], false)
      makeModuleWithItems(2, 'Lesson 2', [217, 219], true)
    })
    afterEach(() => {
      updateModuleSpy?.mockRestore()
    })

    it('updates the modules and their items', () => {
      updateModuleSpy = jest.spyOn(publishAllModulesHelperModule, 'updateModulePublishedState')
      updateItemsSpy = jest.spyOn(publishOneModuleHelperModule, 'updateModuleItemsPublishedStates')
      const isPublishing = true
      updateModulePendingPublishedStates(isPublishing)
      expect(updateModuleSpy).toHaveBeenCalledTimes(2)
      expect(updateItemsSpy).toHaveBeenCalledTimes(2)
      expect(updateItemsSpy).toHaveBeenCalledWith(1, undefined, isPublishing)
    })
  })

  describe('updateModulePublishedState', () => {
    let spy
    beforeEach(() => {
      makeModuleWithItems(1, 'Lesson 2', [117, 119], false)
      makeModuleWithItems(2, 'Lesson 2', [217, 219], true)
    })
    afterEach(() => {
      spy?.mockRestore()
    })

    it('updates the module', () => {
      const published = true
      const isPublishing = false
      updateModulePublishedState(1, published, isPublishing)
      expect(renderContextModulesPublishIcon).toHaveBeenCalledTimes(1)
      expect(renderContextModulesPublishIcon).toHaveBeenCalledWith('1', 1, published, isPublishing)
    })
  })

  describe('moduleIds', () => {
    it('extracts module ids from the erb generated dom elements', () => {
      document.body.innerHTML = `
      <div>
        <span id="a_module_17" class="context_module" data-module-id="17">module 17</span>
        <span id="b_module_19" class="context_module" data-module-id="19">module 19</span
        <span id="template_module" class="context_module" data-module-id="{{ id }}"></span
      `
      const mids = moduleIds()
      expect(mids).toStrictEqual([17, 19])
    })

    it('returns only unique its', () => {
      document.body.innerHTML = `
      <div>
        <span id="a_module_17" class="context_module" data-module-id="17">module 17</span>
        <span id="b_module_17" class="context_module" data-module-id="17">module 17 too</span
        <span id="template_module" class="context_module" data-module-id="{{ id }}"></span
      `
      const mids = moduleIds()
      expect(mids).toStrictEqual([17])
    })
  })
})
