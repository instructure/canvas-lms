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

import {renderHook, act} from '@testing-library/react-hooks'
import useLaunchConversionJobHook, {
  CONVERSION_JOB_COMPLETE,
  CONVERSION_JOB_FAILED,
  CONVERSION_JOB_NOT_STARTED,
  CONVERSION_JOB_QUEUED,
  CONVERSION_JOB_RUNNING,
} from '../LaunchConversionJobHook'
import axios from 'axios'

vi.mock('axios', () => ({
  put: vi.fn(() => Promise.resolve({status: 204})),
  get: vi.fn(() => Promise.resolve({status: 200, data: {progress: 0, workflow_state: 'queued'}})),
}))

describe('useLaunchConversionJobHook', () => {
  it('should return initial state', () => {
    const {result} = renderHook(() => useLaunchConversionJobHook('1', false))

    expect(result.current.launchConversionJob).toBeInstanceOf(Function)
    expect(result.current.conversionJobState).toBe(CONVERSION_JOB_NOT_STARTED)
    expect(result.current.conversionJobProgress).toBe(0)
    expect(result.current.conversionJobError).toBeNull()
  })

  it.skip('should update conversion job state when launchConversionJob is called', async () => {
    const {result, waitForNextUpdate} = renderHook(() => useLaunchConversionJobHook('1', false))

    act(() => {
      result.current.launchConversionJob()
    })

    await waitForNextUpdate()

    expect(result.current.conversionJobState).toBe(CONVERSION_JOB_QUEUED)
    expect(result.current.conversionJobProgress).toBe(0)
  })

  it.skip('returns conversion job progress and state when polling job progress', async () => {
    ;(axios.get as any).mockResolvedValueOnce({
      status: 200,
      data: {progress: 30, workflow_state: 'running'},
    })
    const {result, waitForNextUpdate} = renderHook(() => useLaunchConversionJobHook('1', true))

    act(() => {
      result.current.launchConversionJob()
    })

    // update twice to simulate polling
    await waitForNextUpdate()
    await waitForNextUpdate()

    expect(result.current.conversionJobState).toBe(CONVERSION_JOB_RUNNING)
    expect(result.current.conversionJobProgress).toBe(30)
  })

  it.skip('returns success state when job completes', async () => {
    ;(axios.get as any).mockResolvedValueOnce({
      status: 200,
      data: {progress: 100, workflow_state: 'completed'},
    })
    const {result, waitForNextUpdate} = renderHook(() => useLaunchConversionJobHook('1', true))

    act(() => {
      result.current.launchConversionJob()
    })

    // update twice to simulate polling
    await waitForNextUpdate()
    await waitForNextUpdate()

    expect(result.current.conversionJobState).toBe(CONVERSION_JOB_COMPLETE)
    expect(result.current.conversionJobProgress).toBe(100)
  })

  it.skip('returns error state when job fails', async () => {
    ;(axios.get as any).mockRejectedValueOnce(new Error('Network Error'))
    const {result, waitForNextUpdate} = renderHook(() => useLaunchConversionJobHook('1', true))

    act(() => {
      result.current.launchConversionJob()
    })

    // update twice to simulate polling
    await waitForNextUpdate()
    await waitForNextUpdate()

    expect(result.current.conversionJobState).toBe(CONVERSION_JOB_FAILED)
    expect(result.current.conversionJobError).toBe('An error occurred while fetching job progress.')
    expect(result.current.conversionJobProgress).toBe(0)
  })
})
