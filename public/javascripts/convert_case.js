/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

function camelizeString(str, lowerFirst) {
  return (str || '').replace(/(?:^|[-_])(\w)/g, (_, c, index) => {
    if (index === 0 && lowerFirst) {
      return c ? c.toLowerCase() : ''
    } else {
      return c ? c.toUpperCase() : ''
    }
  })
}

function underscoreString(str) {
  return str.replace(/([A-Z])/g, $1 => `_${$1.toLowerCase()}`)
}

// Convert all property keys in an object to camelCase
export function camelize(props) {
  let prop
  const attrs = {}

  for (prop in props) {
    if (props.hasOwnProperty(prop)) {
      attrs[camelizeString(prop, true)] = props[prop]
    }
  }

  return attrs
}

export function underscore(props) {
  let prop
  const attrs = {}

  for (prop in props) {
    if (props.hasOwnProperty(prop)) {
      attrs[underscoreString(prop)] = props[prop]
    }
  }

  return attrs
}
