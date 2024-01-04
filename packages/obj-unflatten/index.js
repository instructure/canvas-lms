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

import {reduce} from 'lodash'

/**
 * Converts an object with nested key strings into an object with nested structure.
 * Example: turns {'foo[bar]': 1} into {foo: {bar: 1}}
 * @param {Object} obj - The object with nested key strings.
 * @returns {Object} The unflattened object with nested structure.
 */

export default function unflatten(obj) {
  return reduce(
    obj,
    (newObj, val, key) => {
      let keys = key.split('][')
      let lastKey = keys.length - 1

      // If the first keys part contains [ and the last ends with ], then []
      // are correctly balanced.
      if (/\[/.test(keys[0]) && /\]$/.test(keys[lastKey])) {
        // Remove the trailing ] from the last keys part.
        keys[lastKey] = keys[lastKey].replace(/\]$/, '')

        // Split first keys part into two parts on the [ and add them back onto
        // the beginning of the keys array.
        keys = keys.shift().split('[').concat(keys)
        lastKey = keys.length - 1
      } else {
        // Basic 'foo' style key.
        lastKey = 0
      }

      if (lastKey) {
        // Complex key, build deep object structure based on a few rules:
        // * The 'cur' pointer starts at the object top-level.
        // * [] = array push (n is set to array length), [n] = array if n is
        //   numeric, otherwise object.
        // * If at the last keys part, set the value.
        // * For each keys part, if the current level is undefined create an
        //   object or array based on the type of the next keys part.
        // * Move the 'cur' pointer to the next level.
        // * Rinse & repeat.
        let i = 0
        let cur = newObj
        while (i <= lastKey) {
          key = keys[i] === '' ? cur.length : keys[i]

          cur = cur[key] =
            // eslint-disable-next-line no-restricted-globals
            i < lastKey ? cur[key] || (keys[i + 1] && isNaN(keys[i + 1]) ? {} : []) : val
          i++
        }
        // Simple key, even simpler rules, since only scalars and shallow
        // arrays are allowed.
      } else if (Array.isArray(newObj[key])) {
        // val is already an array, so push on the next value.
        newObj[key].push(val)
      } else if (newObj[key] != null) {
        // val isn't an array, but since a second value has been specified,
        // convert val into an array.
        newObj[key] = [newObj[key], val]
      } else {
        // val is a scalar.
        newObj[key] = val
      }

      return newObj
    },
    Object.create(null)
  )
}
