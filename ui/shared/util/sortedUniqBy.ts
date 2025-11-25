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

import {sortBy, uniqBy} from 'es-toolkit'

/**
 * Creates an array that is sorted and has unique elements based on the iteratee.
 * This function first sorts the array, then removes duplicates based on the iteratee.
 *
 * @template T
 * @param {T[]} array - The array to process
 * @param {keyof T | ((item: T) => unknown)} iteratee - The iteratee to determine uniqueness (property key or function)
 * @returns {T[]} Returns the new sorted array of unique values
 *
 * @example
 * const items = [{id: 2, name: 'b'}, {id: 1, name: 'a'}, {id: 2, name: 'c'}]
 * sortedUniqBy(items, 'id')
 * // => [{id: 1, name: 'a'}, {id: 2, name: 'b'}]
 */
export function sortedUniqBy<T extends object>(
  array: T[],
  iteratee: keyof T | ((item: T) => unknown)
): T[] {
  // Both sortBy and uniqBy only accept functions, so convert property keys to functions
  const getterFn = typeof iteratee === 'function' ? iteratee : (item: T) => item[iteratee]
  // sortBy expects an array of criteria functions
  const sorted = sortBy(array, [getterFn])
  return uniqBy(sorted, getterFn)
}
