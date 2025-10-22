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

import {IgniteAgentSessionStorage} from '../IgniteAgentSessionStorage'

describe('IgniteAgentSessionStorage', () => {
  const SESSION_STORAGE_KEY = 'igniteAgent'

  beforeEach(() => {
    sessionStorage.clear()
    jest.clearAllMocks()
  })

  afterEach(() => {
    sessionStorage.clear()
  })

  describe('getState', () => {
    it('returns null when sessionStorage is empty', () => {
      const result = IgniteAgentSessionStorage.getState()
      expect(result).toBeNull()
    })

    it('returns the parsed session state when valid JSON exists', () => {
      const mockState = {isOpen: true, sessionId: '123'}
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      const result = IgniteAgentSessionStorage.getState()
      expect(result).toEqual(mockState)
    })

    it('returns null when sessionStorage contains invalid JSON', () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
      sessionStorage.setItem(SESSION_STORAGE_KEY, 'invalid-json{')

      const result = IgniteAgentSessionStorage.getState()
      expect(result).toBeNull()
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        '[Ignite Agent] Could not read from sessionStorage:',
        expect.any(Error),
      )

      consoleErrorSpy.mockRestore()
    })

    it('handles complex nested state objects', () => {
      const mockState = {
        isOpen: false,
        sessionId: '456',
        user: {
          id: 1,
          name: 'Test User',
        },
        messages: ['msg1', 'msg2'],
      }
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      const result = IgniteAgentSessionStorage.getState()
      expect(result).toEqual(mockState)
    })
  })

  describe('setAgentState', () => {
    it('sets isOpen to true when state exists and true is passed', () => {
      const mockState = {isOpen: false, sessionId: '123'}
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      IgniteAgentSessionStorage.setAgentState(true)

      const updatedState = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      expect(updatedState.isOpen).toBe(true)
      expect(updatedState.sessionId).toBe('123')
    })

    it('sets isOpen to false when state exists and false is passed', () => {
      const mockState = {isOpen: true, sessionId: '123'}
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      IgniteAgentSessionStorage.setAgentState(false)

      const updatedState = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      expect(updatedState.isOpen).toBe(false)
      expect(updatedState.sessionId).toBe('123')
    })

    it('preserves other properties when setting to true', () => {
      const mockState = {
        isOpen: false,
        sessionId: '123',
        otherProp: 'value',
        nestedProp: {key: 'value'},
      }
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      IgniteAgentSessionStorage.setAgentState(true)

      const updatedState = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      expect(updatedState.isOpen).toBe(true)
      expect(updatedState.sessionId).toBe('123')
      expect(updatedState.otherProp).toBe('value')
      expect(updatedState.nestedProp).toEqual({key: 'value'})
    })

    it('preserves other properties when setting to false', () => {
      const mockState = {
        isOpen: true,
        sessionId: '456',
        otherProp: 'value',
        nestedProp: {key: 'value'},
      }
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      IgniteAgentSessionStorage.setAgentState(false)

      const updatedState = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      expect(updatedState.isOpen).toBe(false)
      expect(updatedState.sessionId).toBe('456')
      expect(updatedState.otherProp).toBe('value')
      expect(updatedState.nestedProp).toEqual({key: 'value'})
    })

    it('logs error when sessionStorage read fails', () => {
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
      sessionStorage.setItem(SESSION_STORAGE_KEY, 'invalid-json{')

      IgniteAgentSessionStorage.setAgentState(true)

      expect(consoleErrorSpy).toHaveBeenCalledWith(
        '[Ignite Agent] Could not write to sessionStorage:',
        expect.any(Error),
      )

      consoleErrorSpy.mockRestore()
    })
  })

  describe('edge cases', () => {
    it('handles empty string in sessionStorage', () => {
      sessionStorage.setItem(SESSION_STORAGE_KEY, '')
      const result = IgniteAgentSessionStorage.getState()
      expect(result).toBeNull()
    })

    it('handles null value in sessionStorage', () => {
      sessionStorage.setItem(SESSION_STORAGE_KEY, 'null')
      const result = IgniteAgentSessionStorage.getState()
      expect(result).toBeNull()
    })

    it('handles boolean values in session state', () => {
      const mockState = {isOpen: false}
      sessionStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(mockState))

      IgniteAgentSessionStorage.setAgentState(true)

      const updatedState = JSON.parse(sessionStorage.getItem(SESSION_STORAGE_KEY))
      expect(updatedState.isOpen).toBe(true)
      expect(typeof updatedState.isOpen).toBe('boolean')
    })
  })
})
