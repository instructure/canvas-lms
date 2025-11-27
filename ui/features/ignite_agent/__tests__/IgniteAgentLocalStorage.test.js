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

import {readFromLocal, writeToLocal} from '../IgniteAgentLocalStorage'

describe('IgniteAgentLocalStorage', () => {
  const LOCAL_STORAGE_KEY = 'igniteAgentLocal'

  beforeEach(() => {
    localStorage.clear()
    jest.clearAllMocks()
    jest.restoreAllMocks()
  })

  afterEach(() => {
    localStorage.clear()
  })

  describe('readFromLocal', () => {
    it('returns undefined when localStorage is empty', () => {
      const result = readFromLocal('buttonRelativeVerticalPosition')
      expect(result).toBeUndefined()
    })

    it('returns undefined when key does not exist in local state', () => {
      const mockState = {someOtherKey: 'value'}
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(mockState))

      const result = readFromLocal('buttonRelativeVerticalPosition')
      expect(result).toBeUndefined()
    })

    it('returns the value when key exists in local state', () => {
      const mockState = {buttonRelativeVerticalPosition: 50}
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(mockState))

      const result = readFromLocal('buttonRelativeVerticalPosition')
      expect(result).toBe(50)
    })

    it('returns complex values correctly', () => {
      const mockState = {
        buttonRelativeVerticalPosition: 40,
        preferences: {theme: 'dark', fontSize: 16},
        recentItems: ['item1', 'item2'],
      }
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(mockState))

      expect(readFromLocal('buttonRelativeVerticalPosition')).toBe(40)
      expect(readFromLocal('preferences')).toEqual({theme: 'dark', fontSize: 16})
      expect(readFromLocal('recentItems')).toEqual(['item1', 'item2'])
    })

    it('returns undefined and logs error when localStorage contains invalid JSON', () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
      localStorage.setItem(LOCAL_STORAGE_KEY, 'invalid-json{')

      const result = readFromLocal('buttonRelativeVerticalPosition')
      expect(result).toBeUndefined()
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        '[Ignite Agent] Error parsing local storage data. Returning undefined.',
        expect.any(Error),
      )

      consoleErrorSpy.mockRestore()
    })

    it('returns false when value is explicitly false', () => {
      const mockState = {enabled: false}
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(mockState))

      const result = readFromLocal('enabled')
      expect(result).toBe(false)
    })

    it('returns null when value is explicitly null', () => {
      const mockState = {lastUpdate: null}
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(mockState))

      const result = readFromLocal('lastUpdate')
      expect(result).toBeNull()
    })

    it('returns 0 when value is 0', () => {
      const mockState = {buttonRelativeVerticalPosition: 0}
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(mockState))

      const result = readFromLocal('buttonRelativeVerticalPosition')
      expect(result).toBe(0)
    })
  })

  describe('writeToLocal', () => {
    it('creates new local state when localStorage is empty', () => {
      writeToLocal('buttonRelativeVerticalPosition', 50)

      const state = JSON.parse(localStorage.getItem(LOCAL_STORAGE_KEY))
      expect(state.buttonRelativeVerticalPosition).toBe(50)
    })

    it('updates existing value in local state', () => {
      const mockState = {buttonRelativeVerticalPosition: 40}
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(mockState))

      writeToLocal('buttonRelativeVerticalPosition', 60)

      const state = JSON.parse(localStorage.getItem(LOCAL_STORAGE_KEY))
      expect(state.buttonRelativeVerticalPosition).toBe(60)
    })

    it('adds new property to existing local state', () => {
      const mockState = {buttonRelativeVerticalPosition: 40}
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(mockState))

      writeToLocal('theme', 'dark')

      const state = JSON.parse(localStorage.getItem(LOCAL_STORAGE_KEY))
      expect(state.buttonRelativeVerticalPosition).toBe(40)
      expect(state.theme).toBe('dark')
    })

    it('preserves all existing properties when updating', () => {
      const mockState = {
        buttonRelativeVerticalPosition: 40,
        theme: 'light',
        fontSize: 14,
        otherProp: 'value',
      }
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(mockState))

      writeToLocal('buttonRelativeVerticalPosition', 55)

      const state = JSON.parse(localStorage.getItem(LOCAL_STORAGE_KEY))
      expect(state.buttonRelativeVerticalPosition).toBe(55)
      expect(state.theme).toBe('light')
      expect(state.fontSize).toBe(14)
      expect(state.otherProp).toBe('value')
    })

    it('handles writing complex values', () => {
      writeToLocal('preferences', {theme: 'dark', fontSize: 16})

      const state = JSON.parse(localStorage.getItem(LOCAL_STORAGE_KEY))
      expect(state.preferences).toEqual({theme: 'dark', fontSize: 16})
    })

    it('handles writing false value', () => {
      writeToLocal('enabled', false)

      const state = JSON.parse(localStorage.getItem(LOCAL_STORAGE_KEY))
      expect(state.enabled).toBe(false)
    })

    it('handles writing null value', () => {
      writeToLocal('lastUpdate', null)

      const state = JSON.parse(localStorage.getItem(LOCAL_STORAGE_KEY))
      expect(state.lastUpdate).toBeNull()
    })

    it('handles writing 0 value', () => {
      writeToLocal('buttonRelativeVerticalPosition', 0)

      const state = JSON.parse(localStorage.getItem(LOCAL_STORAGE_KEY))
      expect(state.buttonRelativeVerticalPosition).toBe(0)
    })

    it('uses default state when existing data is invalid JSON', () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
      localStorage.setItem(LOCAL_STORAGE_KEY, 'invalid-json{')

      writeToLocal('buttonRelativeVerticalPosition', 50)

      const state = JSON.parse(localStorage.getItem(LOCAL_STORAGE_KEY))
      expect(state.buttonRelativeVerticalPosition).toBe(50)
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        '[Ignite Agent] Error parsing existing local storage data. Starting fresh.',
        expect.any(Error),
      )

      consoleErrorSpy.mockRestore()
    })

    it('handles error when localStorage.setItem fails', () => {
      // Suppress console.error for this test since we're intentionally causing an error
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
      const mockError = new Error('Storage quota exceeded')

      // Get the descriptor to properly mock the property
      const descriptor = Object.getOwnPropertyDescriptor(window.Storage.prototype, 'setItem')
      Object.defineProperty(window.Storage.prototype, 'setItem', {
        configurable: true,
        enumerable: true,
        writable: true,
        value: jest.fn(() => {
          throw mockError
        }),
      })

      // The critical behavior: function should handle error gracefully without throwing
      expect(() => writeToLocal('buttonRelativeVerticalPosition', 50)).not.toThrow()

      // Restore original setItem
      if (descriptor) {
        Object.defineProperty(window.Storage.prototype, 'setItem', descriptor)
      }

      consoleErrorSpy.mockRestore()
    })
  })

  describe('edge cases', () => {
    it('handles empty string in localStorage', () => {
      localStorage.setItem(LOCAL_STORAGE_KEY, '')
      const result = readFromLocal('buttonRelativeVerticalPosition')
      expect(result).toBeUndefined()
    })

    it('handles empty object in localStorage', () => {
      localStorage.setItem(LOCAL_STORAGE_KEY, '{}')
      const result = readFromLocal('buttonRelativeVerticalPosition')
      expect(result).toBeUndefined()
    })

    it('handles string "null" in localStorage', () => {
      localStorage.setItem(LOCAL_STORAGE_KEY, 'null')
      const result = readFromLocal('buttonRelativeVerticalPosition')
      expect(result).toBeUndefined()
    })
  })

  describe('persistence across function calls', () => {
    it('persists data across multiple writes', () => {
      writeToLocal('buttonRelativeVerticalPosition', 40)
      writeToLocal('theme', 'dark')
      writeToLocal('fontSize', 16)

      const state = JSON.parse(localStorage.getItem(LOCAL_STORAGE_KEY))
      expect(state.buttonRelativeVerticalPosition).toBe(40)
      expect(state.theme).toBe('dark')
      expect(state.fontSize).toBe(16)
    })

    it('reads data written in previous call', () => {
      writeToLocal('buttonRelativeVerticalPosition', 65)

      const result = readFromLocal('buttonRelativeVerticalPosition')
      expect(result).toBe(65)
    })

    it('updates data multiple times', () => {
      writeToLocal('buttonRelativeVerticalPosition', 30)
      expect(readFromLocal('buttonRelativeVerticalPosition')).toBe(30)

      writeToLocal('buttonRelativeVerticalPosition', 50)
      expect(readFromLocal('buttonRelativeVerticalPosition')).toBe(50)

      writeToLocal('buttonRelativeVerticalPosition', 70)
      expect(readFromLocal('buttonRelativeVerticalPosition')).toBe(70)
    })
  })
})
