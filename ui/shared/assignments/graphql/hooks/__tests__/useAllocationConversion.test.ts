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

import {renderHook} from '@testing-library/react-hooks'
import {useAllocationConversion} from '../useAllocationConversion'
import {useCheckAllocationConversion} from '../useCheckAllocationConversion'
import {
  useConvertAllocations,
  CONVERSION_JOB_NOT_STARTED,
  CONVERSION_JOB_QUEUED,
  CONVERSION_JOB_RUNNING,
  CONVERSION_JOB_COMPLETE,
  CONVERSION_JOB_FAILED,
  type ConversionJobState,
} from '../useConvertAllocations'

vi.mock('../useCheckAllocationConversion', () => ({
  useCheckAllocationConversion: vi.fn(),
}))

vi.mock('../useConvertAllocations', () => ({
  useConvertAllocations: vi.fn(),
  CONVERSION_JOB_NOT_STARTED: 'not_started',
  CONVERSION_JOB_QUEUED: 'queued',
  CONVERSION_JOB_RUNNING: 'running',
  CONVERSION_JOB_COMPLETE: 'complete',
  CONVERSION_JOB_FAILED: 'failed',
}))

const mockCheckHook = vi.mocked(useCheckAllocationConversion)
const mockConvertHook = vi.mocked(useConvertAllocations)

const defaultConvertReturn = {
  launchConversion: vi.fn(),
  launchDeletion: vi.fn(),
  conversionAction: 'convert' as const,
  conversionJobState: CONVERSION_JOB_NOT_STARTED as ConversionJobState,
  conversionJobProgress: 0,
  conversionJobError: null,
}

describe('useAllocationConversion', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    mockCheckHook.mockReturnValue({
      hasLegacyAllocations: false,
      loading: false,
      error: null,
    })

    mockConvertHook.mockReturnValue({...defaultConvertReturn})
  })

  it('surfaces hasLegacyAllocations and loading from check hook', () => {
    mockCheckHook.mockReturnValue({
      hasLegacyAllocations: true,
      loading: true,
      error: null,
    })

    const {result} = renderHook(() => useAllocationConversion('1', '2', true))

    expect(result.current.hasLegacyAllocations).toBe(true)
    expect(result.current.loading).toBe(true)
  })

  it('surfaces launchConversion, launchDeletion, conversionAction, conversionJobState, conversionJobError from convert hook', () => {
    const launchConversion = vi.fn()
    const launchDeletion = vi.fn()
    mockConvertHook.mockReturnValue({
      ...defaultConvertReturn,
      launchConversion,
      launchDeletion,
      conversionAction: 'delete',
      conversionJobState: CONVERSION_JOB_RUNNING,
      conversionJobError: 'some error',
    })

    const {result} = renderHook(() => useAllocationConversion('1', '2', true))

    expect(result.current.launchConversion).toBe(launchConversion)
    expect(result.current.launchDeletion).toBe(launchDeletion)
    expect(result.current.conversionAction).toBe('delete')
    expect(result.current.conversionJobState).toBe(CONVERSION_JOB_RUNNING)
    expect(result.current.conversionJobError).toBe('some error')
  })

  describe('isConversionInProgress', () => {
    it('is true when state is queued', () => {
      mockConvertHook.mockReturnValue({
        ...defaultConvertReturn,
        conversionJobState: CONVERSION_JOB_QUEUED,
      })

      const {result} = renderHook(() => useAllocationConversion('1', '2', true))
      expect(result.current.isConversionInProgress).toBe(true)
    })

    it('is true when state is running', () => {
      mockConvertHook.mockReturnValue({
        ...defaultConvertReturn,
        conversionJobState: CONVERSION_JOB_RUNNING,
      })

      const {result} = renderHook(() => useAllocationConversion('1', '2', true))
      expect(result.current.isConversionInProgress).toBe(true)
    })

    it.each<[string, ConversionJobState]>([
      ['not_started', CONVERSION_JOB_NOT_STARTED],
      ['complete', CONVERSION_JOB_COMPLETE],
      ['failed', CONVERSION_JOB_FAILED],
    ])('is false when state is %s', (_label, state) => {
      mockConvertHook.mockReturnValue({
        ...defaultConvertReturn,
        conversionJobState: state,
      })

      const {result} = renderHook(() => useAllocationConversion('1', '2', true))
      expect(result.current.isConversionInProgress).toBe(false)
    })
  })

  describe('isConversionComplete', () => {
    it('is true only when state is complete', () => {
      mockConvertHook.mockReturnValue({
        ...defaultConvertReturn,
        conversionJobState: CONVERSION_JOB_COMPLETE,
      })

      const {result} = renderHook(() => useAllocationConversion('1', '2', true))
      expect(result.current.isConversionComplete).toBe(true)
    })

    it.each<[string, ConversionJobState]>([
      ['not_started', CONVERSION_JOB_NOT_STARTED],
      ['queued', CONVERSION_JOB_QUEUED],
      ['running', CONVERSION_JOB_RUNNING],
      ['failed', CONVERSION_JOB_FAILED],
    ])('is false when state is %s', (_label, state) => {
      mockConvertHook.mockReturnValue({
        ...defaultConvertReturn,
        conversionJobState: state,
      })

      const {result} = renderHook(() => useAllocationConversion('1', '2', true))
      expect(result.current.isConversionComplete).toBe(false)
    })
  })
})
