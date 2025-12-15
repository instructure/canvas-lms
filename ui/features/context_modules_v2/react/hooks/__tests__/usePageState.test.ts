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
import {usePageState} from '../usePageState'

// Mock ENV
;(window as any).ENV = {
  course_id: 'test-course',
  ACCOUNT_ID: 'test-account',
  current_user_id: 'test-user',
}

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {}

  return {
    getItem: vi.fn((key: string) => store[key] || null),
    setItem: vi.fn((key: string, value: string) => {
      store[key] = value.toString()
    }),
    removeItem: vi.fn((key: string) => {
      delete store[key]
    }),
    clear: vi.fn(() => {
      store = {}
    }),
  }
})()

Object.defineProperty(window, 'localStorage', {
  value: localStorageMock,
})

describe('usePageState', () => {
  const moduleId = 'test-module-123'
  const actualStorageKey = '_mperf_test-account_test-user_test-course_test-module-123'

  beforeEach(() => {
    localStorageMock.clear()
    vi.clearAllMocks()
  })

  it('initializes with page 1 when no stored value exists', () => {
    const {result} = renderHook(() => usePageState(moduleId))
    const [pageIndex] = result.current

    expect(pageIndex).toBe(1)
  })

  it('initializes with stored page value when it exists', () => {
    localStorageMock.setItem(actualStorageKey, JSON.stringify({p: '3'}))

    const {result} = renderHook(() => usePageState(moduleId))
    const [pageIndex] = result.current

    expect(pageIndex).toBe(3)
  })

  it('updates state and persists to localStorage when setPageIndex is called', () => {
    const {result} = renderHook(() => usePageState(moduleId))
    const [, setPageIndex] = result.current

    act(() => {
      setPageIndex(2)
    })

    const [newPageIndex] = result.current
    expect(newPageIndex).toBe(2)
    expect(localStorageMock.setItem).toHaveBeenCalledWith(
      actualStorageKey,
      JSON.stringify({p: '2'}),
    )
  })

  it('handles invalid stored page numbers gracefully', () => {
    localStorageMock.setItem(actualStorageKey, JSON.stringify({p: 'invalid'}))

    const {result} = renderHook(() => usePageState(moduleId))
    const [pageIndex] = result.current

    expect(pageIndex).toBe(NaN) // parseInt('invalid') returns NaN
  })

  describe('error handling', () => {
    let originalError: any
    beforeEach(() => {
      originalError = window.onerror
      console.error = () => {}
    })

    afterEach(() => {
      console.error = originalError
    })

    it('handles localStorage errors gracefully', () => {
      localStorageMock.setItem.mockImplementationOnce(() => {
        throw new Error('Storage error')
      })

      const {result} = renderHook(() => usePageState(moduleId))
      const [, setPageIndex] = result.current

      expect(() => {
        act(() => {
          setPageIndex(3)
        })
      }).not.toThrow()
    })
  })
})
