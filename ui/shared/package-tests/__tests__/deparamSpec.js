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

import deparam from 'deparam'

const params_str =
  'a[0]=4&a[1]=5&a[2]=6&b[x][]=7&b[y]=8&b[z][0]=9&b[z][1]=0&b[z][2]=true&b[z][3]=false&b[z][4]=undefined&b[z][5]=&c=1'
const params_obj = {
  a: ['4', '5', '6'],
  b: {
    x: ['7'],
    y: '8',
    z: ['9', '0', 'true', 'false', 'undefined', ''],
  },
  c: '1',
}
const params_obj_coerce = {
  a: [4, 5, 6],
  b: {
    x: [7],
    y: 8,
    z: [9, 0, true, false, undefined, ''],
  },
  c: 1,
}

QUnit.module('deparam')

test('deparam', () => {
  deepEqual(deparam(), {}, 'deparam()')
  deepEqual(deparam(params_str), params_obj, 'deparam( String )')
  deepEqual(deparam(params_str, true), params_obj_coerce, 'deparam( String, true )')
})

test('prototype pollution protection', () => {
  const dangerous_input =
    'a=1&__proto__%5Bdiv%5D%5B0%5D=1&__proto__%5Bdiv%5D%5B1%5D=%3Cimg/src/onerror%3dalert(document.domain)%3E&__proto__%5Bdiv%5D%5B2%5D=1'

  const safe_result = Object.create(null)
  safe_result.a = '1'
  // eslint-disable-next-line no-proto
  safe_result.__proto__ = {
    div: ['1', '<img/src/onerror=alert(document.domain)>', '1'],
  }

  const obj = {}
  deepEqual(obj.div, undefined)
  const result = deparam(dangerous_input)
  deepEqual(result, safe_result, 'deparam works')
  deepEqual(result.div, undefined, '__proto__ is just an object property')
  deepEqual(obj.div, undefined, 'Object.prototype is not polluted')
})
