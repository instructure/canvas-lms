/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
  addToLimit,
  clearData,
  clearLimit,
  getData,
  getLimit,
  putData,
  removeFromLimit,
} from '../platform_storage'

describe('platform_storage', () => {
  const tool_id = 'tool_id'
  const key = 'key'
  const value = 'value'

  beforeEach(() => {
    clearLimit(tool_id)
  })

  describe('getLimit', () => {
    it('defaults counts to 0', () => {
      const limit = getLimit('tool that does not have limit already')
      expect(limit.keyCount).toBe(0)
      expect(limit.charCount).toBe(0)
    })
  })

  describe('addToLimit', () => {
    it('increments key count for tool id', () => {
      const before = {...getLimit(tool_id)}
      addToLimit(tool_id, key, value)
      const after = getLimit(tool_id)
      expect(after.keyCount).toEqual(before.keyCount + 1)
    })

    it('adds key and value length to char count for tool', () => {
      const before = {...getLimit(tool_id)}
      addToLimit(tool_id, key, value)
      const after = getLimit(tool_id)
      expect(after.charCount).toEqual(before.charCount + key.length + value.length)
    })

    describe('when tool has reached key count limit', () => {
      beforeEach(() => {
        getLimit(tool_id).keyCount = 500
      })

      it('throws a storage_exhaustion error', () => {
        expect(() => addToLimit(tool_id, key, value)).toThrow('Reached key limit')
      })
    })

    describe('when tool has reached char count limit', () => {
      beforeEach(() => {
        getLimit(tool_id).charCount = 4096
      })

      it('throws a storage_exhaustion error', () => {
        expect(() => addToLimit(tool_id, key, value)).toThrow('Reached byte limit')
      })
    })
  })

  describe('removeFromLimit', () => {
    beforeEach(() => {
      addToLimit(tool_id, 'hello', 'world')
      addToLimit(tool_id, key, value)
    })

    it('decrements key count for tool id', () => {
      const before = {...getLimit(tool_id)}
      removeFromLimit(tool_id, key, value)
      const after = getLimit(tool_id)
      expect(after.keyCount).toEqual(before.keyCount - 1)
    })

    it('removes key and value length from char count for tool', () => {
      const before = {...getLimit(tool_id)}
      removeFromLimit(tool_id, key, value)
      const after = getLimit(tool_id)
      expect(after.charCount).toEqual(before.charCount - key.length - value.length)
    })

    describe('when key count goes below 0', () => {
      beforeEach(() => {
        removeFromLimit(tool_id, key, value)
        removeFromLimit(tool_id, key, value)
        removeFromLimit(tool_id, key, value)
      })

      it('resets key count to 0', () => {
        const {keyCount} = getLimit(tool_id)
        expect(keyCount).toBe(0)
      })
    })

    describe('when char count goes below 0', () => {
      beforeEach(() => {
        removeFromLimit(tool_id, key, value)
        removeFromLimit(tool_id, key, value)
        removeFromLimit(tool_id, key, value)
      })

      it('resets char count to 0', () => {
        const {charCount} = getLimit(tool_id)
        expect(charCount).toBe(0)
      })
    })
  })

  describe('putData', () => {
    beforeEach(() => {
      jest.spyOn(window.localStorage, 'setItem')
    })

    it('namespaces key with tool id', () => {
      putData(tool_id, key, value)
      expect(window.localStorage.setItem).toHaveBeenCalledWith(
        `lti|platform_storage|${tool_id}|${key}`,
        value
      )
    })
  })

  describe('getData', () => {
    beforeEach(() => {
      jest.spyOn(window.localStorage, 'getItem')
      putData(tool_id, key, value)
    })

    it('namespaces key with tool id', () => {
      getData(tool_id, key)
      expect(window.localStorage.getItem).toHaveBeenCalledWith(
        `lti|platform_storage|${tool_id}|${key}`
      )
    })
  })

  describe('clearData', () => {
    beforeEach(() => {
      jest.spyOn(window.localStorage, 'removeItem')
    })

    describe('when key does not exist', () => {
      it('does nothing', () => {
        expect(window.localStorage.removeItem).not.toHaveBeenCalled()
      })
    })

    describe('when key is already stored', () => {
      beforeEach(() => {
        jest.spyOn(window.localStorage, 'getItem').mockImplementation(() => value)
        putData(tool_id, key, value)
      })

      it('namespaces key with tool id', () => {
        clearData(tool_id, key)
        expect(window.localStorage.removeItem).toHaveBeenCalledWith(
          `lti|platform_storage|${tool_id}|${key}`
        )
      })
    })
  })
})
