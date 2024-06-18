/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import cache from '../cache'

describe('class/cache', () => {
  let cacheInstance

  beforeEach(() => {
    // assuming the actual cache instance is stored under a cache property
    cacheInstance = cache.cache
  })

  test('should store strings', () => {
    cacheInstance.set('key', 'value')
    expect(cacheInstance.get('key')).toBe('value')
  })

  test('should store arrays and objects', () => {
    cacheInstance.set('array', [1, 2, 3])
    cacheInstance.set('object', {a: 1, b: 2})
    expect(cacheInstance.get('array')).toEqual([1, 2, 3])
    expect(cacheInstance.get('object')).toEqual({a: 1, b: 2})
  })

  test('should delete keys', () => {
    cacheInstance.set('key', 'value')
    cacheInstance.remove('key')
    expect(cacheInstance.get('key')).toBeNull()
  })

  test('should accept complex keys', () => {
    cacheInstance.set([1, 2, 3], 'value1')
    cacheInstance.set({a: 1, b: 1}, 'value2')
    cacheInstance.set([1, 2], {a: 1}, 'test', 'value3')

    expect(cacheInstance.get([1, 2, 3])).toBe('value1')
    expect(cacheInstance.get({a: 1, b: 1})).toBe('value2')
    expect(cacheInstance.get([1, 2], {a: 1}, 'test')).toBe('value3')
  })

  test('should accept a prefix', () => {
    cacheInstance.prefix = 'prefix-'
    cacheInstance.set('key', 'value')
    expect(typeof cacheInstance.store['prefix-"key"']).toBe('string')
  })

  test('should accept local and sessionStorage as stores', () => {
    cacheInstance.use('localStorage')
    expect(cacheInstance.store).toBe(localStorage)

    cacheInstance.use('sessionStorage')
    expect(cacheInstance.store).toBe(sessionStorage)

    // Reset to memory store if needed
    cacheInstance.use('memory')
  })
})
