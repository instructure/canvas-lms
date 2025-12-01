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

import {sortedUniqBy} from '../sortedUniqBy'

describe('sortedUniqBy', () => {
  describe('with property key iteratee', () => {
    test('sorts and removes duplicates based on property', () => {
      const items = [
        {id: 2, name: 'b'},
        {id: 1, name: 'a'},
        {id: 2, name: 'c'},
      ]
      const result = sortedUniqBy(items, 'id')

      expect(result).toEqual([
        {id: 1, name: 'a'},
        {id: 2, name: 'b'},
      ])
    })

    test('keeps first occurrence when duplicates exist after sorting', () => {
      const items = [
        {id: 3, name: 'c'},
        {id: 1, name: 'a'},
        {id: 2, name: 'b'},
        {id: 1, name: 'duplicate'},
      ]
      const result = sortedUniqBy(items, 'id')

      expect(result).toEqual([
        {id: 1, name: 'a'},
        {id: 2, name: 'b'},
        {id: 3, name: 'c'},
      ])
    })

    test('handles string properties', () => {
      const items = [{name: 'zebra'}, {name: 'apple'}, {name: 'banana'}, {name: 'apple'}]
      const result = sortedUniqBy(items, 'name')

      expect(result).toEqual([{name: 'apple'}, {name: 'banana'}, {name: 'zebra'}])
    })

    test('handles already sorted array', () => {
      const items = [{id: 1}, {id: 2}, {id: 3}]
      const result = sortedUniqBy(items, 'id')

      expect(result).toEqual([{id: 1}, {id: 2}, {id: 3}])
    })
  })

  describe('with function iteratee', () => {
    test('sorts and removes duplicates based on function result', () => {
      const items = [
        {id: 2, name: 'b'},
        {id: 1, name: 'a'},
        {id: 2, name: 'c'},
      ]
      const iteratee = (item: (typeof items)[0]) => item.id
      const result = sortedUniqBy(items, iteratee)

      expect(result).toEqual([
        {id: 1, name: 'a'},
        {id: 2, name: 'b'},
      ])
    })

    test('handles complex function logic', () => {
      const items = [
        {value: 10, type: 'A'},
        {value: 5, type: 'B'},
        {value: 15, type: 'C'},
        {value: 10, type: 'D'},
      ]
      const iteratee = (item: (typeof items)[0]) => Math.floor(item.value / 5)
      const result = sortedUniqBy(items, iteratee)

      expect(result).toEqual([
        {value: 5, type: 'B'},
        {value: 10, type: 'A'},
        {value: 15, type: 'C'},
      ])
    })

    test('handles case-insensitive string comparison', () => {
      const items = [{name: 'Zebra'}, {name: 'apple'}, {name: 'BANANA'}, {name: 'Apple'}]
      const iteratee = (item: (typeof items)[0]) => item.name.toLowerCase()
      const result = sortedUniqBy(items, iteratee)

      expect(result).toEqual([{name: 'apple'}, {name: 'BANANA'}, {name: 'Zebra'}])
    })
  })

  describe('edge cases', () => {
    test('handles empty array', () => {
      const result = sortedUniqBy([], 'id')

      expect(result).toEqual([])
    })

    test('handles single element array', () => {
      const items = [{id: 1, name: 'a'}]
      const result = sortedUniqBy(items, 'id')

      expect(result).toEqual([{id: 1, name: 'a'}])
    })

    test('handles array with all duplicates', () => {
      const items = [
        {id: 1, name: 'a'},
        {id: 1, name: 'b'},
        {id: 1, name: 'c'},
      ]
      const result = sortedUniqBy(items, 'id')

      expect(result).toEqual([{id: 1, name: 'a'}])
    })

    test('handles array with all unique elements', () => {
      const items = [{id: 3}, {id: 1}, {id: 2}]
      const result = sortedUniqBy(items, 'id')

      expect(result).toEqual([{id: 1}, {id: 2}, {id: 3}])
    })

    test('handles numeric values including zero', () => {
      const items = [{score: 0}, {score: -1}, {score: 1}, {score: 0}]
      const result = sortedUniqBy(items, 'score')

      expect(result).toEqual([{score: -1}, {score: 0}, {score: 1}])
    })

    test('handles undefined and null values', () => {
      const items = [{value: undefined}, {value: null}, {value: 1}, {value: undefined}]
      const result = sortedUniqBy(items, 'value')

      // Verify deduplication works correctly
      expect(result).toHaveLength(3) // undefined, null, 1
      expect(result.some(item => item.value === 1)).toBeTruthy()
      expect(result.some(item => item.value === null)).toBeTruthy()
      expect(result.some(item => item.value === undefined)).toBeTruthy()
    })

    test('handles arrays containing undefined objects', () => {
      type Item = {index: number; component?: string} | undefined
      const items: Item[] = [
        {index: 2, component: 'b'},
        undefined,
        {index: 1, component: 'a'},
        undefined,
        {index: 2, component: 'c'},
      ]
      const result = sortedUniqBy(items as Array<{index: number; component?: string}>, 'index')

      // Should filter out undefined and deduplicate
      expect(result).toEqual([
        {index: 1, component: 'a'},
        {index: 2, component: 'b'},
      ])
    })
  })

  describe('maintains sort order', () => {
    test('sorts by numeric values in ascending order', () => {
      const items = [{priority: 5}, {priority: 1}, {priority: 3}, {priority: 2}]
      const result = sortedUniqBy(items, 'priority')

      expect(result.map(item => item.priority)).toEqual([1, 2, 3, 5])
    })

    test('sorts by string values in lexicographic order', () => {
      const items = [{letter: 'd'}, {letter: 'a'}, {letter: 'c'}, {letter: 'b'}, {letter: 'a'}]
      const result = sortedUniqBy(items, 'letter')

      expect(result.map(item => item.letter)).toEqual(['a', 'b', 'c', 'd'])
    })

    test('maintains stable sort with complex objects', () => {
      const items = [
        {id: 2, timestamp: 100},
        {id: 1, timestamp: 200},
        {id: 2, timestamp: 300},
      ]
      const result = sortedUniqBy(items, 'id')

      expect(result).toEqual([
        {id: 1, timestamp: 200},
        {id: 2, timestamp: 100},
      ])
    })
  })

  describe('nested property paths', () => {
    test('handles nested property path like "course._id"', () => {
      const enrollments = [
        {course: {_id: '2', name: 'Course 2'}},
        {course: {_id: '1', name: 'Course 1'}},
        {course: {_id: '2', name: 'Course 2 Duplicate'}},
      ]
      const result = sortedUniqBy(enrollments, 'course._id')

      expect(result).toEqual([
        {course: {_id: '1', name: 'Course 1'}},
        {course: {_id: '2', name: 'Course 2'}},
      ])
      expect(result).toHaveLength(2) // Critical: verify data not lost
    })

    test('handles deeply nested property paths', () => {
      const items = [
        {user: {profile: {id: 3}}},
        {user: {profile: {id: 1}}},
        {user: {profile: {id: 2}}},
        {user: {profile: {id: 1}}},
      ]
      const result = sortedUniqBy(items, 'user.profile.id')

      expect(result).toEqual([
        {user: {profile: {id: 1}}},
        {user: {profile: {id: 2}}},
        {user: {profile: {id: 3}}},
      ])
      expect(result).toHaveLength(3)
    })

    test('handles nested path with string values', () => {
      const items = [
        {course: {term: {name: 'Spring'}}},
        {course: {term: {name: 'Fall'}}},
        {course: {term: {name: 'Spring'}}},
      ]
      const result = sortedUniqBy(items, 'course.term.name')

      expect(result).toEqual([{course: {term: {name: 'Fall'}}}, {course: {term: {name: 'Spring'}}}])
      expect(result).toHaveLength(2)
    })

    test('handles nested path with undefined intermediate values', () => {
      const items = [{course: {_id: '1'}}, {course: undefined as any}, {course: {_id: '2'}}]
      const result = sortedUniqBy(items, 'course._id')

      // Should handle undefined gracefully without crashing
      expect(result.length).toBeGreaterThan(0)
    })

    test('real-world case: enrollment deduplication', () => {
      // This is the actual use case from NotificationPreferencesContextSelect
      const enrollments = [
        {
          course: {_id: '1', name: 'Math 101', term: {_id: 't1', name: 'Fall 2024'}},
        },
        {
          course: {_id: '1', name: 'Math 101', term: {_id: 't1', name: 'Fall 2024'}},
        }, // Duplicate
        {
          course: {_id: '2', name: 'CS 101', term: {_id: 't1', name: 'Fall 2024'}},
        },
        {
          course: {_id: '3', name: 'English 101', term: {_id: 't2', name: 'Spring 2025'}},
        },
      ]

      const result = sortedUniqBy(enrollments, 'course._id')

      // Should return 3 unique courses (not 1, which would be a data loss bug)
      expect(result).toHaveLength(3)
      expect(result[0].course._id).toBe('1')
      expect(result[1].course._id).toBe('2')
      expect(result[2].course._id).toBe('3')
    })
  })
})
