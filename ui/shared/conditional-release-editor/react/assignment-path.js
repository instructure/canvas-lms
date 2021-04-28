/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

const RANGE = 0
const SET = 1
const ASSIGNMENT = 2

const MAX_SIZE = 3

const validateValue = value => {
  const parsedValue = parseInt(value, 10)
  if (!Number.isNaN(parsedValue)) {
    return parsedValue
  } else {
    throw new Error(`Path value "${value}" is not a number`)
  }
}

export default class Path {
  constructor(...pathSegments) {
    this._pathSegments = pathSegments.slice(0, MAX_SIZE).map(val => validateValue(val))
  }

  get range() {
    return this._pathSegments[RANGE]
  }

  get set() {
    return this._pathSegments[SET]
  }

  get assignment() {
    return this._pathSegments[ASSIGNMENT]
  }

  get size() {
    return this._pathSegments.length
  }

  push(value) {
    value = validateValue(value)
    const size = this.size

    if (size >= MAX_SIZE) {
      throw new Error('Path is full')
    } else {
      const pathSegmentsCopy = this._pathSegments.slice(0, size)
      pathSegmentsCopy.push(value)

      return new Path(...pathSegmentsCopy)
    }
  }

  pop() {
    const size = this.size

    if (size === 0) {
      throw new Error('Path is empty')
    } else {
      const pathSegmentsCopy = this._pathSegments.slice(0, -1)
      return new Path(...pathSegmentsCopy)
    }
  }

  toJS() {
    const {range, set, assignment} = this
    return {range, set, assignment}
  }

  equals(other) {
    return this._pathSegments
      .map((val, idx) => val === other._pathSegments[idx])
      .reduce((prev, cur) => prev && cur, true)
  }

  toString() {
    return this._pathSegments.toString()
  }
}
