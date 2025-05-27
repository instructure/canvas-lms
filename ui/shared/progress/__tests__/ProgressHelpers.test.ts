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
import doFetchApi from '@canvas/do-fetch-api-effect'
import {monitorProgress, cancelProgressAction} from '../ProgressHelpers'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('@canvas/do-fetch-api-effect')
const mockDoFetchApi = doFetchApi as jest.MockedFunction<typeof doFetchApi>

describe('ProgressHelpers', () => {
  beforeEach(() => {
    fakeENV.setup()
    mockDoFetchApi.mockResolvedValue({
      response: new Response('', {status: 200}),
      json: {published: true},
      text: '',
    })
  })

  afterEach(() => {
    jest.clearAllMocks()
    mockDoFetchApi.mockReset()
    fakeENV.teardown()
  })

  describe('monitorProgress', () => {
    beforeAll(() => {
      jest.useFakeTimers()
    })

    it('polls for progress until completed', async () => {
      mockDoFetchApi.mockResolvedValueOnce({
        response: new Response('', {status: 200}),
        json: {
          id: '3533',
          workflow_state: 'queued',
          url: '/api/v1/progress/3533',
        },
        text: '',
      })
      mockDoFetchApi.mockResolvedValueOnce({
        response: new Response('', {status: 200}),
        json: {
          id: '3533',
          workflow_state: 'running',
          url: '/api/v1/progress/3533',
        },
        text: '',
      })
      mockDoFetchApi.mockResolvedValueOnce({
        response: new Response('', {status: 200}),
        json: {
          id: '3533',
          workflow_state: 'completed',
          url: '/api/v1/progress/3533',
        },
        text: '',
      })

      const setCurrentProgress = jest.fn()
      monitorProgress('3533', setCurrentProgress, () => {})
      await waitFor(() => expect(setCurrentProgress).toHaveBeenCalledTimes(1))
      expect(mockDoFetchApi).toHaveBeenCalledTimes(1)
      expect(mockDoFetchApi).toHaveBeenNthCalledWith(1, {path: '/api/v1/progress/3533'})
      jest.runOnlyPendingTimers()
      await waitFor(() => expect(setCurrentProgress).toHaveBeenCalledTimes(2))
      expect(mockDoFetchApi).toHaveBeenCalledTimes(2)
      expect(mockDoFetchApi).toHaveBeenNthCalledWith(2, {path: '/api/v1/progress/3533'})
      jest.runOnlyPendingTimers()
      await waitFor(() => expect(setCurrentProgress).toHaveBeenCalledTimes(3))
      expect(mockDoFetchApi).toHaveBeenCalledTimes(3)
      expect(mockDoFetchApi).toHaveBeenNthCalledWith(3, {path: '/api/v1/progress/3533'})
      jest.runOnlyPendingTimers()
    })

    it('polls for progress until failed', async () => {
      mockDoFetchApi.mockResolvedValueOnce({
        response: new Response('', {status: 200}),
        json: {
          id: '3533',
          workflow_state: 'queued',
          url: '/api/v1/progress/3533',
        },
        text: '',
      })
      mockDoFetchApi.mockResolvedValueOnce({
        response: new Response('', {status: 200}),
        json: {
          id: '3533',
          workflow_state: 'failed',
          url: '/api/v1/progress/3533',
        },
        text: '',
      })

      const setCurrentProgress = jest.fn()
      monitorProgress('3533', setCurrentProgress, () => {})
      await waitFor(() => expect(setCurrentProgress).toHaveBeenCalledTimes(1))
      expect(mockDoFetchApi).toHaveBeenCalledTimes(1)
      expect(mockDoFetchApi).toHaveBeenNthCalledWith(1, {path: '/api/v1/progress/3533'})
      jest.runOnlyPendingTimers()
      await waitFor(() => expect(setCurrentProgress).toHaveBeenCalledTimes(2))
      expect(mockDoFetchApi).toHaveBeenCalledTimes(2)
      expect(mockDoFetchApi).toHaveBeenNthCalledWith(2, {path: '/api/v1/progress/3533'})
      jest.runOnlyPendingTimers()
    })

    it('calls onProgressFail on a catestrophic failure', async () => {
      const err = new Error('whoops')
      mockDoFetchApi.mockRejectedValueOnce(err)
      const onProgressFail = jest.fn()
      monitorProgress('3533', () => {}, onProgressFail)
      await waitFor(() => expect(onProgressFail).toHaveBeenCalledWith(err))
    })
  })

  describe('cancelProgressAction', () => {
    it('bails out of no progress is provided', () => {
      const onCancelComplete = jest.fn()
      cancelProgressAction(undefined, onCancelComplete)
      expect(onCancelComplete).toHaveBeenCalledTimes(0)
      expect(mockDoFetchApi).toHaveBeenCalledTimes(0)
    })

    it('bails out if the progress has already completed', () => {
      const onCancelComplete = jest.fn()
      cancelProgressAction(
        {id: '17', workflow_state: 'completed', message: 'completed', completion: 100, results: {}},
        onCancelComplete,
      )
      expect(onCancelComplete).toHaveBeenCalledTimes(0)
      expect(mockDoFetchApi).toHaveBeenCalledTimes(0)
    })

    it('bails out if the progress has already failed', () => {
      const onCancelComplete = jest.fn()
      cancelProgressAction(
        {id: '17', workflow_state: 'failed', message: 'failed', completion: 25, results: {}},
        onCancelComplete,
      )
      expect(onCancelComplete).toHaveBeenCalledTimes(0)
      expect(mockDoFetchApi).toHaveBeenCalledTimes(0)
    })

    it('cancels the progress', async () => {
      const onCancelComplete = jest.fn()
      cancelProgressAction(
        {id: '17', workflow_state: 'running', message: 'canceled', completion: 25, results: {}},
        onCancelComplete,
      )
      expect(mockDoFetchApi).toHaveBeenCalledTimes(1)
      expect(mockDoFetchApi).toHaveBeenCalledWith({
        method: 'POST',
        path: '/api/v1/progress/17/cancel',
        body: {message: 'canceled'},
      })
      await waitFor(() => expect(onCancelComplete).toHaveBeenCalled())
      expect(onCancelComplete).toHaveBeenCalledTimes(1)
      expect(onCancelComplete).toHaveBeenCalledWith()
    })

    it('calls onCancelComplete with the error on failure', async () => {
      const mockError = new Error('API request failed')
      mockDoFetchApi.mockRejectedValueOnce(mockError)
      const onCancelComplete = jest.fn()
      cancelProgressAction(
        {id: '17', workflow_state: 'running', message: 'canceled', completion: 25, results: {}},
        onCancelComplete,
      )
      expect(mockDoFetchApi).toHaveBeenCalledTimes(1)
      expect(mockDoFetchApi).toHaveBeenCalledWith({
        method: 'POST',
        path: '/api/v1/progress/17/cancel',
        body: {message: 'canceled'},
      })
      await waitFor(() => expect(onCancelComplete).toHaveBeenCalled())
      expect(onCancelComplete).toHaveBeenCalledTimes(1)
      expect(onCancelComplete).toHaveBeenCalledWith(mockError)
    })
  })
})
