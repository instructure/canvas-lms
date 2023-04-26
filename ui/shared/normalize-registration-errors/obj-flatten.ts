//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

// turns {foo: {bar: 1}} into {'foo[bar]': 1}
export default function flatten(
  obj: {
    [key: string]: any
  },
  options: {
    arrays?: boolean
  } = {},
  result: {
    [key: string]: any
  } = {},
  prefix: string = ''
) {
  for (let key in obj) {
    const value = obj[key]
    key = prefix ? `${prefix}[${key}]` : key
    let flattenable = typeof value === 'object'
    if (value.length != null && options.arrays === false) {
      flattenable = false
    }
    if (flattenable) {
      flatten(value, options, result, key)
    } else {
      result[key] = value
    }
  }
  return result
}
