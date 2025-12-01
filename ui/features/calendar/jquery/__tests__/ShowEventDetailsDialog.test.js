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

import {reject} from 'es-toolkit/compat'

describe('ShowEventDetailsDialog appointment cancellation', () => {
  describe('child_events filtering with reject', () => {
    it('removes canceled appointment from child_events array', () => {
      const childEvents = [
        {url: '/appointments/1', user: {id: '1', name: 'User 1'}},
        {url: '/appointments/2', user: {id: '2', name: 'User 2'}},
        {url: '/appointments/3', user: {id: '3', name: 'User 3'}},
      ]

      const urlToRemove = '/appointments/2'
      const result = reject(childEvents, e => e.url === urlToRemove)

      expect(result).toEqual([
        {url: '/appointments/1', user: {id: '1', name: 'User 1'}},
        {url: '/appointments/3', user: {id: '3', name: 'User 3'}},
      ])
      expect(result).toHaveLength(2)
    })

    it('returns an array that can be iterated with forEach', () => {
      const childEvents = [
        {url: '/appointments/1', user: {id: '1', name: 'User 1'}},
        {url: '/appointments/2', user: {id: '2', name: 'User 2'}},
      ]

      const result = reject(childEvents, e => e.url === '/appointments/2')

      // Verify it's a real array with forEach method
      expect(Array.isArray(result)).toBe(true)
      expect(typeof result.forEach).toBe('function')

      // Verify forEach works correctly
      const names = []
      result.forEach(e => {
        names.push(e.user.name)
      })
      expect(names).toEqual(['User 1'])
    })

    it('handles empty array after filtering', () => {
      const childEvents = [{url: '/appointments/1', user: {id: '1', name: 'User 1'}}]

      const result = reject(childEvents, e => e.url === '/appointments/1')

      expect(result).toEqual([])
      expect(result).toHaveLength(0)
      expect(Array.isArray(result)).toBe(true)
    })

    it('handles no matches - returns all items', () => {
      const childEvents = [
        {url: '/appointments/1', user: {id: '1', name: 'User 1'}},
        {url: '/appointments/2', user: {id: '2', name: 'User 2'}},
      ]

      const result = reject(childEvents, e => e.url === '/appointments/999')

      expect(result).toEqual(childEvents)
      expect(result).toHaveLength(2)
    })

    it('returns an array not a LodashWrapper (regression test for migration bug)', () => {
      const childEvents = [
        {url: '/appointments/1', user: {id: '1', name: 'User 1'}},
        {url: '/appointments/2', user: {id: '2', name: 'User 2'}},
      ]

      const result = reject(childEvents, e => e.url === '/appointments/2')

      // The old lodash code without .value() would return a LodashWrapper
      // Verify we get a plain array, not a wrapper object
      expect(Array.isArray(result)).toBe(true)
      expect(result.constructor.name).toBe('Array')
      expect(result).not.toHaveProperty('value') // LodashWrapper has a .value() method
    })
  })
})
