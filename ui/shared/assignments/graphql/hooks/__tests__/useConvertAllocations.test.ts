/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {renderHook, act} from '@testing-library/react-hooks'
import doFetchApiModule from '@canvas/do-fetch-api-effect'
import {
  useConvertAllocations,
  CONVERSION_JOB_NOT_STARTED,
  CONVERSION_JOB_QUEUED,
  CONVERSION_JOB_RUNNING,
  CONVERSION_JOB_COMPLETE,
  CONVERSION_JOB_FAILED,
} from '../useConvertAllocations'

vi.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: vi.fn(),
}))

const doFetchApi = vi.mocked(doFetchApiModule)

describe('useConvertAllocations', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('returns initial state', () => {
    const {result} = renderHook(() => useConvertAllocations('1', '2'))

    expect(result.current.conversionJobState).toBe(CONVERSION_JOB_NOT_STARTED)
    expect(result.current.conversionAction).toBe('convert')
    expect(result.current.conversionJobError).toBeNull()
  })

  describe('launchConversion', () => {
    it('calls doFetchApi with PUT and should_delete: false, sets state to queued on 204', async () => {
      doFetchApi.mockResolvedValueOnce({
        response: {status: 204} as Response,
        json: null,
        text: '',
        link: undefined,
      })

      const {result} = renderHook(() => useConvertAllocations('1', '2'))

      await act(async () => {
        result.current.launchConversion()
      })

      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/api/v1/courses/1/assignments/2/convert_peer_review_allocations',
        method: 'PUT',
        body: {type: 'AssessmentRequest', should_delete: false},
      })
      expect(result.current.conversionJobState).toBe(CONVERSION_JOB_QUEUED)
      expect(result.current.conversionAction).toBe('convert')
    })

    it('sets state to failed with conversion error message on error', async () => {
      doFetchApi.mockRejectedValueOnce(new Error('Network error'))

      const {result} = renderHook(() => useConvertAllocations('1', '2'))

      await act(async () => {
        result.current.launchConversion()
      })

      expect(result.current.conversionJobState).toBe(CONVERSION_JOB_FAILED)
      expect(result.current.conversionJobError).toBe(
        'An error occurred while starting the conversion.',
      )
    })
  })

  describe('launchDeletion', () => {
    it('calls doFetchApi with PUT and should_delete: true, sets state to queued on 204', async () => {
      doFetchApi.mockResolvedValueOnce({
        response: {status: 204} as Response,
        json: null,
        text: '',
        link: undefined,
      })

      const {result} = renderHook(() => useConvertAllocations('1', '2'))

      await act(async () => {
        result.current.launchDeletion()
      })

      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/api/v1/courses/1/assignments/2/convert_peer_review_allocations',
        method: 'PUT',
        body: {type: 'AssessmentRequest', should_delete: true},
      })
      expect(result.current.conversionJobState).toBe(CONVERSION_JOB_QUEUED)
      expect(result.current.conversionAction).toBe('delete')
    })

    it('sets state to failed with deletion error message on error', async () => {
      doFetchApi.mockRejectedValueOnce(new Error('Network error'))

      const {result} = renderHook(() => useConvertAllocations('1', '2'))

      await act(async () => {
        result.current.launchDeletion()
      })

      expect(result.current.conversionJobState).toBe(CONVERSION_JOB_FAILED)
      expect(result.current.conversionJobError).toBe(
        'An error occurred while starting the deletion.',
      )
    })
  })

  describe('polling', () => {
    it('transitions to running when status endpoint returns running', async () => {
      // Launch conversion first
      doFetchApi.mockResolvedValueOnce({
        response: {status: 204} as Response,
        json: null,
        text: '',
        link: undefined,
      })

      const {result} = renderHook(() => useConvertAllocations('1', '2'))

      await act(async () => {
        result.current.launchConversion()
      })

      // Set up polling response
      doFetchApi.mockResolvedValueOnce({
        response: {ok: true} as Response,
        json: {workflow_state: 'running', progress: 50},
        text: '',
        link: undefined,
      })

      await act(async () => {
        vi.advanceTimersByTime(1000)
      })

      expect(result.current.conversionJobState).toBe(CONVERSION_JOB_RUNNING)
    })

    it('transitions to complete and stops polling when status returns completed', async () => {
      doFetchApi.mockResolvedValueOnce({
        response: {status: 204} as Response,
        json: null,
        text: '',
        link: undefined,
      })

      const {result} = renderHook(() => useConvertAllocations('1', '2'))

      await act(async () => {
        result.current.launchConversion()
      })

      doFetchApi.mockResolvedValueOnce({
        response: {ok: true} as Response,
        json: {workflow_state: 'completed'},
        text: '',
        link: undefined,
      })

      await act(async () => {
        vi.advanceTimersByTime(1000)
      })

      expect(result.current.conversionJobState).toBe(CONVERSION_JOB_COMPLETE)

      // Advance again to confirm polling has stopped
      const callCount = doFetchApi.mock.calls.length
      await act(async () => {
        vi.advanceTimersByTime(2000)
      })
      expect(doFetchApi.mock.calls).toHaveLength(callCount)
    })

    it('transitions to failed and stops polling when status returns failed', async () => {
      doFetchApi.mockResolvedValueOnce({
        response: {status: 204} as Response,
        json: null,
        text: '',
        link: undefined,
      })

      const {result} = renderHook(() => useConvertAllocations('1', '2'))

      await act(async () => {
        result.current.launchConversion()
      })

      doFetchApi.mockResolvedValueOnce({
        response: {ok: true} as Response,
        json: {workflow_state: 'failed'},
        text: '',
        link: undefined,
      })

      await act(async () => {
        vi.advanceTimersByTime(1000)
      })

      expect(result.current.conversionJobState).toBe(CONVERSION_JOB_FAILED)
      expect(result.current.conversionJobError).toBe('The conversion job failed.')
    })

    it('transitions to failed when polling fetch throws an error', async () => {
      doFetchApi.mockResolvedValueOnce({
        response: {status: 204} as Response,
        json: null,
        text: '',
        link: undefined,
      })

      const {result} = renderHook(() => useConvertAllocations('1', '2'))

      await act(async () => {
        result.current.launchConversion()
      })

      doFetchApi.mockRejectedValueOnce(new Error('Poll error'))

      await act(async () => {
        vi.advanceTimersByTime(1000)
      })

      expect(result.current.conversionJobState).toBe(CONVERSION_JOB_FAILED)
      expect(result.current.conversionJobError).toBe(
        'An error occurred while fetching job progress.',
      )
    })
  })
})
