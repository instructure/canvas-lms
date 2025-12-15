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

import {waitFor} from '@testing-library/dom'
import {monitorProgress, cancelProgressAction} from '../ProgressHelpers'
import fakeENV from '@canvas/test-utils/fakeENV'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

describe('ProgressHelpers', () => {
  // Track API calls
  let apiCallCount = 0
  let lastCapturedRequest: {path: string; method: string; body?: any} | null = null

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup()
    apiCallCount = 0
    lastCapturedRequest = null
    // Default handler - return completed state to prevent infinite loops
    server.use(
      http.get('/api/v1/progress/:progressId', () => {
        apiCallCount++
        return HttpResponse.json({
          id: 'default',
          workflow_state: 'completed',
          message: null,
          completion: 100,
          results: {},
        })
      }),
      http.post('/api/v1/progress/:progressId/cancel', async ({request}) => {
        apiCallCount++
        lastCapturedRequest = {
          path: new URL(request.url).pathname,
          method: 'POST',
          body: await request.json(),
        }
        return HttpResponse.json({
          id: 'default',
          workflow_state: 'completed',
          message: null,
          completion: 100,
          results: {},
        })
      }),
    )
  })

  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
    fakeENV.teardown()
  })

  describe('monitorProgress', () => {
    it('polls for progress until completed', async () => {
      // Create a sequence of responses based on call count
      let callIndex = 0
      const responses = [
        {id: '3533', workflow_state: 'queued', url: '/api/v1/progress/3533'},
        {id: '3533', workflow_state: 'running', url: '/api/v1/progress/3533'},
        {id: '3533', workflow_state: 'completed', url: '/api/v1/progress/3533'},
      ]

      server.use(
        http.get('/api/v1/progress/:progressId', () => {
          apiCallCount++
          const response = responses[callIndex] || responses[responses.length - 1]
          callIndex++
          return HttpResponse.json(response)
        }),
      )

      const setCurrentProgress = vi.fn()
      monitorProgress('3533', setCurrentProgress, () => {}, 50) // Use shorter polling interval
      await waitFor(() => expect(setCurrentProgress).toHaveBeenCalledTimes(1))
      expect(apiCallCount).toBe(1)
      await waitFor(() => expect(setCurrentProgress).toHaveBeenCalledTimes(2))
      expect(apiCallCount).toBe(2)
      await waitFor(() => expect(setCurrentProgress).toHaveBeenCalledTimes(3))
      expect(apiCallCount).toBe(3)
    })

    it('polls for progress until failed', async () => {
      let callIndex = 0
      const responses = [
        {id: '3533', workflow_state: 'queued', url: '/api/v1/progress/3533'},
        {id: '3533', workflow_state: 'failed', url: '/api/v1/progress/3533'},
      ]

      server.use(
        http.get('/api/v1/progress/:progressId', () => {
          apiCallCount++
          const response = responses[callIndex] || responses[responses.length - 1]
          callIndex++
          return HttpResponse.json(response)
        }),
      )

      const setCurrentProgress = vi.fn()
      monitorProgress('3533', setCurrentProgress, () => {}, 50) // Use shorter polling interval
      await waitFor(() => {
        expect(setCurrentProgress).toHaveBeenCalledTimes(1)
        expect(apiCallCount).toBe(1)
      })
      await waitFor(() => {
        expect(setCurrentProgress).toHaveBeenCalledTimes(2)
        expect(apiCallCount).toBe(2)
      })
    })

    it('calls onProgressFail on a catestrophic failure', async () => {
      server.use(http.get('/api/v1/progress/:progressId', () => HttpResponse.error()))
      const onProgressFail = vi.fn()
      monitorProgress('3533', () => {}, onProgressFail, 50) // Use shorter polling interval
      await waitFor(() => expect(onProgressFail).toHaveBeenCalledWith(expect.any(Error)))
    })
  })

  describe('cancelProgressAction', () => {
    it('bails out of no progress is provided', () => {
      const onCancelComplete = vi.fn()
      cancelProgressAction(undefined, onCancelComplete)
      expect(onCancelComplete).toHaveBeenCalledTimes(0)
      expect(apiCallCount).toBe(0)
    })

    it('bails out if the progress has already completed', () => {
      const onCancelComplete = vi.fn()
      cancelProgressAction(
        {id: '17', workflow_state: 'completed', message: 'completed', completion: 100, results: {}},
        onCancelComplete,
      )
      expect(onCancelComplete).toHaveBeenCalledTimes(0)
      expect(apiCallCount).toBe(0)
    })

    it('bails out if the progress has already failed', () => {
      const onCancelComplete = vi.fn()
      cancelProgressAction(
        {id: '17', workflow_state: 'failed', message: 'failed', completion: 25, results: {}},
        onCancelComplete,
      )
      expect(onCancelComplete).toHaveBeenCalledTimes(0)
      expect(apiCallCount).toBe(0)
    })

    it('cancels the progress', async () => {
      const onCancelComplete = vi.fn()
      cancelProgressAction(
        {id: '17', workflow_state: 'running', message: 'canceled', completion: 25, results: {}},
        onCancelComplete,
      )
      await waitFor(() => expect(apiCallCount).toBe(1))
      expect(lastCapturedRequest).not.toBeNull()
      expect(lastCapturedRequest!.path).toBe('/api/v1/progress/17/cancel')
      expect(lastCapturedRequest!.method).toBe('POST')
      expect(lastCapturedRequest!.body).toEqual({message: 'canceled'})
      await waitFor(() => expect(onCancelComplete).toHaveBeenCalled())
      expect(onCancelComplete).toHaveBeenCalledTimes(1)
      expect(onCancelComplete).toHaveBeenCalledWith()
    })

    it('calls onCancelComplete with the error on failure', async () => {
      server.use(http.post('/api/v1/progress/:progressId/cancel', () => HttpResponse.error()))
      const onCancelComplete = vi.fn()
      cancelProgressAction(
        {id: '17', workflow_state: 'running', message: 'canceled', completion: 25, results: {}},
        onCancelComplete,
      )
      await waitFor(() => expect(onCancelComplete).toHaveBeenCalled())
      expect(onCancelComplete).toHaveBeenCalledTimes(1)
      expect(onCancelComplete).toHaveBeenCalledWith(expect.any(Error))
    })
  })
})
