/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import unflatten from 'obj-unflatten'

QUnit.module('unflatten')

test('simple object', () => {
  const input = {
    foo: 1,
    bar: 'baz',
  }
  deepEqual(unflatten(input), input)
})

test('nested params', () => {
  const input = {
    'a[0]': 1,
    'a[1]': 2,
    'a[2]': 3,
    b: 4,
    'c[d]': 5,
    'c[e][ea]': 'asdf',
    'c[f]': true,
    'c[g]': false,
    'c[h]': '',
    i: 7,
  }
  const expected = {
    a: [1, 2, 3],
    b: 4,
    c: {
      d: 5,
      e: {ea: 'asdf'},
      f: true,
      g: false,
      h: '',
    },
    i: 7,
  }
  deepEqual(unflatten(input), expected)
})

test('prototype pollution protection', () => {
  const dangerous_input = {
    '__proto__[admin]': true,
  }

  const safe_result = Object.create(null)
  // eslint-disable-next-line no-proto
  safe_result.__proto__ = {admin: true}

  const user = {name: 'Dale'}
  deepEqual(user.admin, undefined)
  const result = unflatten(dangerous_input)
  deepEqual(result, safe_result, 'unflatten works')
  deepEqual(result.admin, undefined, '__proto__ is just an object property')
  deepEqual(user.admin, undefined, 'Object.prototype is not polluted')
})
