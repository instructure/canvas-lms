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

import {
  DEFAULT_PAGE_NUMBER,
  DEFAULT_SHOW_ALL,
  ModuleItemsStore,
  PREFIX,
} from '../utils/ModuleItemsStore'

describe('ModuleItemsStore', () => {
  let store: ModuleItemsStore
  const courseId = 'course123'
  const accountId = 'account456'
  const userId = 'user789'
  const moduleId = 'module001'
  const composedKey = `${PREFIX}_${accountId}_${userId}_${courseId}_${moduleId}`

  beforeEach(() => {
    store = new ModuleItemsStore(courseId, accountId, userId)
    localStorage.clear()
  })

  describe('page number', () => {
    describe('get', () => {
      it('should retrieve the default pageNumber when no data exists', () => {
        const result = store.getPageNumber(moduleId)
        expect(result).toBe(DEFAULT_PAGE_NUMBER)
      })

      it('should retrieve the pageNumber from localStorage', () => {
        localStorage.setItem(composedKey, '{"p": "2"}')
        const result = store.getPageNumber(moduleId)
        expect(result).toBe('2')
      })

      it('should handle existing invalid JSON in localStorage for pageNumber', () => {
        localStorage.setItem(composedKey, 'invalid JSON')
        const result = store.getPageNumber(moduleId)
        expect(result).toBe(DEFAULT_PAGE_NUMBER)
      })

      it('should handle when localStorage is not available', () => {
        const originalLocalStorage = global.localStorage
        // Temporarily set localStorage to undefined to simulate it not being available
        // @ts-expect-error
        global.localStorage = undefined

        expect(() => {
          store.getPageNumber(moduleId)
        }).not.toThrow()

        // Restore localStorage
        global.localStorage = originalLocalStorage
      })
    })

    describe('set', () => {
      it('should save and retrieve pageNumber', () => {
        store.setPageNumber(moduleId, 2)
        const item = localStorage.getItem(composedKey)
        expect(item).not.toBeNull()
        expect(JSON.parse(item as string).p).toBe('2')
      })

      it('should update pageNumber in existing data', () => {
        localStorage.setItem(composedKey, '{"p": "1"}')
        store.setPageNumber(moduleId, 3)
        const item = localStorage.getItem(composedKey)
        expect(item).not.toBeNull()
        expect(JSON.parse(item as string).p).toBe('3')
      })

      it('should handle existing invalid JSON in localStorage for pageNumber', () => {
        // Initial invalid JSON
        localStorage.setItem(composedKey, 'invalid JSON')
        store.setPageNumber(moduleId, 1)
        const data = JSON.parse(localStorage.getItem(composedKey) || '{}')
        expect(data.p).toBe('1')
      })

      it('should handle when localStorage is not available', () => {
        const originalLocalStorage = global.localStorage
        // Temporarily set localStorage to undefined to simulate it not being available
        // @ts-expect-error
        global.localStorage = undefined

        expect(() => {
          store.setPageNumber(moduleId, 2)
        }).not.toThrow()

        // Restore localStorage
        global.localStorage = originalLocalStorage
      })
    })

    describe('delete', () => {
      it('should remove the pageNumber from localStorage', () => {
        localStorage.setItem(composedKey, '{"p": "2"}')
        store.removePageNumber(moduleId)
        const data = JSON.parse(localStorage.getItem(composedKey) || '{}')
        expect(data.p).toBeUndefined()
      })

      it('should handle deleting pageNumber when no data exists', () => {
        store.removePageNumber(moduleId)
        const data = JSON.parse(localStorage.getItem(composedKey) || '{}')
        expect(data.p).toBeUndefined()
      })

      it('should handle when localStorage is not available', () => {
        const originalLocalStorage = global.localStorage
        // Temporarily set localStorage to undefined to simulate it not being available
        // @ts-expect-error
        global.localStorage = undefined

        expect(() => {
          store.removePageNumber(moduleId)
        }).not.toThrow()

        // Restore localStorage
        global.localStorage = originalLocalStorage
      })
    })
  })

  describe('show all', () => {
    describe('get', () => {
      it('should retrieve the default showAll flag when no data exists', () => {
        const result = store.getShowAll(moduleId)
        expect(result).toBe(DEFAULT_SHOW_ALL)
      })

      it('should retrieve the showAll flag from localStorage', () => {
        localStorage.setItem(composedKey, '{"s": true}')
        const result = store.getShowAll(moduleId)
        expect(result).toBe(true)
      })

      it('should handle existing invalid JSON in localStorage for showAll flag', () => {
        localStorage.setItem(composedKey, 'invalid JSON')
        const result = store.getShowAll(moduleId)
        expect(result).toBe(DEFAULT_SHOW_ALL)
      })

      it('should handle when localStorage is not available', () => {
        const originalLocalStorage = global.localStorage
        // Temporarily set localStorage to undefined to simulate it not being available
        // @ts-expect-error
        global.localStorage = undefined

        expect(() => {
          store.getShowAll(moduleId)
        }).not.toThrow()

        // Restore localStorage
        global.localStorage = originalLocalStorage
      })
    })

    describe('set', () => {
      it('should save and retrieve showAll flag', () => {
        store.setShowAll(moduleId, true)
        const data = JSON.parse(localStorage.getItem(composedKey) || '{}')
        expect(data.s).toBe(true)
      })

      it('should update showAll flag in existing data', () => {
        localStorage.setItem(composedKey, '{"s": true}')
        store.setShowAll(moduleId, false)
        const data = JSON.parse(localStorage.getItem(composedKey) || '{}')
        expect(data.s).toBe(false)
      })

      it('should handle existing invalid JSON in localStorage for showAll flag', () => {
        // Initial invalid JSON
        localStorage.setItem(composedKey, 'invalid JSON')
        store.setShowAll(moduleId, true)
        const data = JSON.parse(localStorage.getItem(composedKey) || '{}')
        expect(data.s).toBe(true)
      })

      it('should handle when localStorage is not available', () => {
        const originalLocalStorage = global.localStorage
        // Temporarily set localStorage to undefined to simulate it not being available
        // @ts-expect-error
        global.localStorage = undefined

        expect(() => {
          store.setShowAll(moduleId, true)
        }).not.toThrow()

        // Restore localStorage
        global.localStorage = originalLocalStorage
      })
    })
  })
})
