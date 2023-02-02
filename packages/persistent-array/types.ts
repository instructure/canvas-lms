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

export type PersistentArray<T> = Array<T>
export type PersistentArrayParameters = {
  // Where to store the value in localStorage. If a value is found at that key,
  // it will be used as the initial value for the array.
  key: string

  // Milliseconds to wait before persisting any batched writes. APIs that
  // accept single elements, like push and pop, batch their writes to
  // localStorage.
  throttle: number

  // Maximum number of elements the array should contain. If a call to #push()
  // would cause the array to exceed this boundary, a value will be shifted
  // from the front first.
  //
  // Defaults to Infinity.
  size: number

  // A hook to transform the value to make it more suitable for saving by the
  // transform parameter. This only applies to the saved value and not for the
  // one stored in memory.
  //
  // Don't mutate it!!!
  transform: <T>(array: Array<T>) => Array<T>
}
