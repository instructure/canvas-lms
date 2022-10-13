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

/**
 * @member Util
 *
 * Shim for React.addons.classSet.
 *
 * @param  {Object} set
 *         A set of class strings and booleans. If the boolean is truthy,
 *         the class will be appended to the className.
 *
 * @return {String}
 *         The produced class string ready for use as a className prop.
 */
const classSet = function (set) {
  return Object.keys(set)
    .reduce(function (classes, key) {
      if (set[key]) {
        classes.push(key)
      }

      return classes
    }, [])
    .join(' ')
}

export default classSet
