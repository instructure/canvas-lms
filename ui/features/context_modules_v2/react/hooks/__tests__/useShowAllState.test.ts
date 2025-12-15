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
import {useShowAllState} from '../useShowAllState'

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

describe('useShowAllState', () => {
  const moduleId = 'test-module-123'
  const actualStorageKey = '_mperf_test-account_test-user_test-course_test-module-123'

  beforeEach(() => {
    localStorageMock.clear()
    vi.clearAllMocks()
  })

  it('initializes with false when no stored value exists', () => {
    const {result} = renderHook(() => useShowAllState(moduleId))
    const [showAll] = result.current

    expect(showAll).toBe(false)
  })

  it('initializes with stored value when it exists', () => {
    localStorageMock.setItem(actualStorageKey, JSON.stringify({s: true}))

    const {result} = renderHook(() => useShowAllState(moduleId))
    const [showAll] = result.current

    expect(showAll).toBe(true)
  })

  it('updates state and persists to localStorage when setShowAll is called', () => {
    const {result} = renderHook(() => useShowAllState(moduleId))
    const [, setShowAll] = result.current

    act(() => {
      setShowAll(true)
    })

    const [newShowAll] = result.current
    expect(newShowAll).toBe(true)
    expect(localStorageMock.setItem).toHaveBeenCalledWith(
      actualStorageKey,
      JSON.stringify({s: true}),
    )
  })

  it('works with function updates', () => {
    const {result} = renderHook(() => useShowAllState(moduleId))
    const [, setShowAll] = result.current

    act(() => {
      setShowAll(prev => !prev)
    })

    const [newShowAll] = result.current
    expect(newShowAll).toBe(true)
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

      const {result} = renderHook(() => useShowAllState(moduleId))
      const [, setShowAll] = result.current

      expect(() => {
        act(() => {
          setShowAll(true)
        })
      }).not.toThrow()
    })
  })
})
