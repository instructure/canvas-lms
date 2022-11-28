/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {STORAGE_KEY, isSet, set, remove} from '../advancedPreference'

describe('advancedPreference', () => {
  beforeEach(() => {
    window.sessionStorage.clear()
  })

  describe('isSet', () => {
    it('returns false if the default key is not set', () => {
      expect(isSet()).toBe(false)
    })

    it('returns true if the default key is set to true', () => {
      window.sessionStorage.setItem(STORAGE_KEY, 'true')
      expect(isSet()).toBe(true)
    })
  })

  describe('set', () => {
    it('sets the default key value to true', () => {
      set()
      expect(!!window.sessionStorage.getItem(STORAGE_KEY)).toBe(true)
    })
  })

  describe('remove', () => {
    it('removes the default key from the store', () => {
      window.sessionStorage.setItem(STORAGE_KEY, 'true')
      remove()
      expect(!!window.sessionStorage.getItem(STORAGE_KEY)).toBe(false)
    })
  })

  describe('when storage is unavailable', () => {
    let actualSessionStorage: Storage

    const mockSessionStorage: Storage = {
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      getItem(key: string) {
        throw new DOMException()
        // eslint-disable-next-line no-unreachable
        return null
      },

      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      setItem(key: string, value: string) {
        throw new DOMException()
      },

      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      removeItem(key: string) {
        throw new DOMException()
      },

      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      key(index: number) {
        return null
      },

      clear() {},

      length: 0,
    }

    beforeAll(() => {
      actualSessionStorage = window.sessionStorage
      Object.defineProperty(window, 'sessionStorage', {
        value: mockSessionStorage,
      })
    })

    afterAll(() => {
      Object.defineProperty(window, 'sessionStorage', {
        value: actualSessionStorage,
      })
    })

    describe('isSet', () => {
      it('returns false', () => {
        expect(isSet()).toBe(false)
      })

      it('handles the error gracefully', () => {
        expect(() => isSet()).not.toThrow()
      })
    })

    describe('set', () => {
      it('handles the error gracefully', () => {
        expect(() => set()).not.toThrow()
      })
    })

    describe('remove', () => {
      it('handles the error gracefully', () => {
        expect(() => remove()).not.toThrow()
      })
    })
  })
})
