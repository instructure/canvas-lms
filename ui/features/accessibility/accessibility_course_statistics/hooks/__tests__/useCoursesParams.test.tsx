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
import {MemoryRouter} from 'react-router-dom'
import React from 'react'
import {useCoursesParams} from '../useCoursesParams'

const defaultOptions = {
  defaultSort: 'course_name',
  defaultOrder: 'asc' as const,
}

describe('useCoursesParams', () => {
  const createWrapper =
    (initialEntries: string[] = ['/']) =>
    ({children}: {children: React.ReactNode}) => {
      return <MemoryRouter initialEntries={initialEntries}>{children}</MemoryRouter>
    }

  describe('reading parameters from URL', () => {
    it('returns default values when no URL parameters are present', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses']),
      })

      expect(result.current.sort).toBe('course_name')
      expect(result.current.order).toBe('asc')
      expect(result.current.page).toBe(1)
      expect(result.current.search).toBe('')
    })

    it('reads sort parameter from URL', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?sort=sis_course_id']),
      })

      expect(result.current.sort).toBe('sis_course_id')
    })

    it('reads order parameter from URL', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?order=desc']),
      })

      expect(result.current.order).toBe('desc')
    })

    it('reads page parameter from URL', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?page=5']),
      })

      expect(result.current.page).toBe(5)
    })

    it('reads search parameter from URL', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?search=biology']),
      })

      expect(result.current.search).toBe('biology')
    })

    it('reads all parameters from URL', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?sort=sis_course_id&order=desc&page=3&search=chemistry']),
      })

      expect(result.current.sort).toBe('sis_course_id')
      expect(result.current.order).toBe('desc')
      expect(result.current.page).toBe(3)
      expect(result.current.search).toBe('chemistry')
    })

    it('defaults to page 1 when page is invalid', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?page=0']),
      })

      expect(result.current.page).toBe(1)
    })

    it('defaults to page 1 when page is not a number', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?page=invalid']),
      })

      expect(result.current.page).toBe(1)
    })
  })

  describe('handleChangeSort', () => {
    it('updates sort parameter in URL', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses']),
      })

      act(() => {
        result.current.handleChangeSort('sis_course_id')
      })

      expect(result.current.sort).toBe('sis_course_id')
    })

    it('sets order to asc when sorting by new column', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?sort=course_name&order=desc']),
      })

      act(() => {
        result.current.handleChangeSort('sis_course_id')
      })

      expect(result.current.sort).toBe('sis_course_id')
      expect(result.current.order).toBe('asc')
    })

    it('toggles order from asc to desc when sorting by same column', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?sort=course_name&order=asc']),
      })

      act(() => {
        result.current.handleChangeSort('course_name')
      })

      expect(result.current.sort).toBe('course_name')
      expect(result.current.order).toBe('desc')
    })

    it('toggles order from desc to asc when sorting by same column', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?sort=course_name&order=desc']),
      })

      act(() => {
        result.current.handleChangeSort('course_name')
      })

      expect(result.current.sort).toBe('course_name')
      expect(result.current.order).toBe('asc')
    })

    it('resets page to 1 when changing sort', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?page=5']),
      })

      act(() => {
        result.current.handleChangeSort('sis_course_id')
      })

      expect(result.current.page).toBe(1)
    })

    it('preserves search parameter when changing sort', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?search=biology']),
      })

      act(() => {
        result.current.handleChangeSort('sis_course_id')
      })

      expect(result.current.search).toBe('biology')
    })
  })

  describe('handlePageChange', () => {
    it('updates page parameter in URL', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses']),
      })

      act(() => {
        result.current.handlePageChange(3)
      })

      expect(result.current.page).toBe(3)
    })

    it('preserves sort and order when changing page', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?sort=sis_course_id&order=desc']),
      })

      act(() => {
        result.current.handlePageChange(2)
      })

      expect(result.current.sort).toBe('sis_course_id')
      expect(result.current.order).toBe('desc')
      expect(result.current.page).toBe(2)
    })

    it('preserves search parameter when changing page', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?search=physics']),
      })

      act(() => {
        result.current.handlePageChange(4)
      })

      expect(result.current.search).toBe('physics')
      expect(result.current.page).toBe(4)
    })
  })

  describe('handleSearchChange', () => {
    it('updates search parameter in URL', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses']),
      })

      act(() => {
        result.current.handleSearchChange('mathematics')
      })

      expect(result.current.search).toBe('mathematics')
    })

    it('removes search parameter when set to empty string', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?search=biology']),
      })

      act(() => {
        result.current.handleSearchChange('')
      })

      expect(result.current.search).toBe('')
    })

    it('resets page to 1 when changing search', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?page=3']),
      })

      act(() => {
        result.current.handleSearchChange('chemistry')
      })

      expect(result.current.page).toBe(1)
      expect(result.current.search).toBe('chemistry')
    })

    it('resets page to 1 when clearing search', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?search=biology&page=5']),
      })

      act(() => {
        result.current.handleSearchChange('')
      })

      expect(result.current.page).toBe(1)
      expect(result.current.search).toBe('')
    })

    it('preserves sort and order when changing search', () => {
      const {result} = renderHook(() => useCoursesParams(defaultOptions), {
        wrapper: createWrapper(['/courses?sort=sis_course_id&order=desc']),
      })

      act(() => {
        result.current.handleSearchChange('history')
      })

      expect(result.current.sort).toBe('sis_course_id')
      expect(result.current.order).toBe('desc')
      expect(result.current.search).toBe('history')
    })
  })
})
