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

import {readFromSession, writeToSession} from '../IgniteAgentSessionStorage'

describe('IgniteAgentSessionStorage', () => {
  const SESSION_STORAGE_KEY = 'igniteAgent'

  beforeEach(() => {
    sessionStorage.clear()
    jest.clearAllMocks()
    jest.restoreAllMocks()
  })

  afterEach(() => {
    sessionStorage.clear()
  })

  describe('readFromSession', () => {
    it('returns undefined when sessionStorage is empty', () => {
      const result = readFromSession('isOpen')
      expect(result).toBeUndefined()
    })

    it('returns undefined when key does not exist in session state', () => {
      const mockState = {sessionId: '123'}
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      const result = readFromSession('isOpen')
      expect(result).toBeUndefined()
    })

    it('returns the value when key exists in session state', () => {
      const mockState = {isOpen: true, sessionId: '123'}
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      const result = readFromSession('isOpen')
      expect(result).toBe(true)
    })

    it('returns complex values correctly', () => {
      const mockState = {
        buttonRelativeVerticalPosition: 0,
        user: {id: 1, name: 'Test User'},
        messages: ['msg1', 'msg2'],
      }
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      expect(readFromSession('buttonRelativeVerticalPosition')).toBe(0)
      expect(readFromSession('user')).toEqual({id: 1, name: 'Test User'})
      expect(readFromSession('messages')).toEqual(['msg1', 'msg2'])
    })

    it('returns undefined and logs error when sessionStorage contains invalid JSON', () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
      sessionStorage.setItem(SESSION_STORAGE_KEY, 'invalid-json{')

      const result = readFromSession('isOpen')
      expect(result).toBeUndefined()
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        '[Ignite Agent] Error parsing session data. Returning undefined.',
        expect.any(Error),
      )

      consoleErrorSpy.mockRestore()
    })

    it('returns false when value is explicitly false', () => {
      const mockState = {isOpen: false}
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      const result = readFromSession('isOpen')
      expect(result).toBe(false)
    })

    it('returns null when value is explicitly null', () => {
      const mockState = {sessionId: null}
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      const result = readFromSession('sessionId')
      expect(result).toBeNull()
    })

    it('returns 0 when value is 0', () => {
      const mockState = {count: 0}
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      const result = readFromSession('count')
      expect(result).toBe(0)
    })
  })

  describe('writeToSession', () => {
    it('creates new session state when sessionStorage is empty', () => {
      writeToSession('isOpen', true)

      const state = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      expect(state.isOpen).toBe(true)
    })

    it('updates existing value in session state', () => {
      const mockState = {isOpen: false, sessionId: '123'}
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      writeToSession('isOpen', true)

      const state = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      expect(state.isOpen).toBe(true)
      expect(state.sessionId).toBe('123')
    })

    it('adds new property to existing session state', () => {
      const mockState = {isOpen: true}
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      writeToSession('sessionId', 'abc123')

      const state = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      expect(state.isOpen).toBe(true)
      expect(state.sessionId).toBe('abc123')
    })

    it('preserves all existing properties when updating', () => {
      const mockState = {
        isOpen: false,
        sessionId: '123',
        buttonRelativeVerticalPosition: 0,
        otherProp: 'value',
      }
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      writeToSession('isOpen', true)

      const state = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      expect(state.isOpen).toBe(true)
      expect(state.sessionId).toBe('123')
      expect(state.buttonRelativeVerticalPosition).toBe(0)
      expect(state.otherProp).toBe('value')
    })

    it('handles writing complex values', () => {
      writeToSession('user', {id: 1, name: 'Test User'})

      const state = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      expect(state.user).toEqual({id: 1, name: 'Test User'})
    })

    it('handles writing false value', () => {
      writeToSession('isOpen', false)

      const state = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      expect(state.isOpen).toBe(false)
    })

    it('handles writing null value', () => {
      writeToSession('sessionId', null)

      const state = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      expect(state.sessionId).toBeNull()
    })

    it('handles writing 0 value', () => {
      writeToSession('count', 0)

      const state = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      expect(state.count).toBe(0)
    })

    it('uses default state when existing data is invalid JSON', () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
      sessionStorage.setItem(SESSION_STORAGE_KEY, 'invalid-json{')

      writeToSession('customKey', 'testValue')

      const state = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      expect(state.customKey).toBe('testValue')
      expect(state.isOpen).toBe(false) // Default is false
      expect(state.sessionId).toBeNull()
      expect(state.buttonRelativeVerticalPosition).toBe(0)
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        '[Ignite Agent] Error parsing existing session data. Starting fresh.',
        expect.any(Error),
      )

      consoleErrorSpy.mockRestore()
    })

    it('handles error when sessionStorage.setItem fails', () => {
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
      expect(() => writeToSession('isOpen', true)).not.toThrow()

      // Restore original setItem
      if (descriptor) {
        Object.defineProperty(window.Storage.prototype, 'setItem', descriptor)
      }

      consoleErrorSpy.mockRestore()
    })
  })

  describe('edge cases', () => {
    it('handles empty string in sessionStorage', () => {
      sessionStorage.setItem(SESSION_STORAGE_KEY, '')
      const result = readFromSession('isOpen')
      expect(result).toBeUndefined()
    })

    it('handles empty object in sessionStorage', () => {
      sessionStorage.setItem(SESSION_STORAGE_KEY, '{}')
      const result = readFromSession('isOpen')
      expect(result).toBeUndefined()
    })

    it('handles string "null" in sessionStorage', () => {
      sessionStorage.setItem(SESSION_STORAGE_KEY, 'null')
      const result = readFromSession('isOpen')
      expect(result).toBeUndefined()
    })
  })
})
