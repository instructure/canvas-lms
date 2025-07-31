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

import {SortBy, SortOrder} from '../constants'
import {getSearchParams, setSearchParams} from '../ManageURLSearchParams'

const getMockWindow = (): Window => {
  const result = {
    location: {
      search: '',
      href: 'http://example.com',
    },
    history: {
      replaceState: jest.fn().mockImplementation((state: any, title: string, url: string) => {
        result.location.search = new URL(url).search
      }),
    },
  } as any as Window
  return result
}

describe('ManageURLSearchParams', () => {
  describe('getSearchParams', () => {
    it('should return the correct search params', () => {
      const _window = getMockWindow()
      _window.location.search = '?page=1&per_page=10&sort_by=student&sort_order=asc'
      const result = getSearchParams(_window)
      expect(result).toEqual({
        currentPage: 1,
        studentsPerPage: 10,
        sortBy: 'student',
        sortOrder: 'asc',
      })
    })

    it('avoids invalid params', () => {
      const _window = getMockWindow()
      _window.location.search = '?page=banana&per_page=10&sort_by=banana&sort_order=asc'
      const result = getSearchParams(_window)
      expect(result).toEqual({
        currentPage: undefined,
        studentsPerPage: 10,
        sortBy: undefined,
        sortOrder: 'asc',
      })
    })
  })

  describe('setSearchParams', () => {
    it('should set the correct search params', () => {
      const _window = getMockWindow()
      setSearchParams(
        2,
        30,
        {
          sortBy: SortBy.SortableName,
          sortOrder: SortOrder.DESC,
          setSortBy: jest.fn(),
          setSortOrder: jest.fn(),
        },
        _window,
      )
      expect(_window.location.search).toBe('?page=2&per_page=30&sort_by=student&sort_order=desc')
    })
  })
})
