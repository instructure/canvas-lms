/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

function serialize(value) {
  if (typeof value === 'boolean' || value === null) {
    value = JSON.stringify(value)
  }
  if (value instanceof HTMLElement) {
    value = value.toString()
  }

  if (typeof value !== 'undefined' && typeof value !== 'string' && value.toString) {
    value = value.toString()
  } else {
    // Otherwise testem croaks
    console.log(typeof value)
    value = 'n/a'
  }

  return value
}

QUnit.config.log.unshift(details => {
  try {
    details.actual = serialize(details.actual)
    details.expected = serialize(details.expected)

    if (details.actual instanceof Array) {
      for (var i = 0; i < details.actual.length; i++) {
        details.actual[i] = serialize(details.actual[i])
      }
    }

    if (details.expected instanceof Array) {
      for (var i = 0; i < details.expected.length; i++) {
        details.expected[i] = serialize(details.expected[i])
      }
    }
  } catch (e) {}
})
