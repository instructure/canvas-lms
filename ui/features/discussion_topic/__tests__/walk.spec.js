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

import walk from '../array-walk'

describe('arr/walk', () => {
  test('walks a tree object', () => {
    const arr = [{name: 'a'}, {name: 'b'}]
    const prop = 'none'
    let str = ''
    walk(arr, prop, item => (str += item.name))
    expect(str).toBe('ab')

    let a = [{}]
    walk(a, 'nuthin', (item, arr) => expect(arr).toBe(a))

    a = [
      {
        a: [
          {
            a: [
              {
                a: [{}, {}],
              },
              {
                a: [{}, {}],
              },
            ],
          },
          {},
          {},
        ],
      },
      {
        a: [],
      },
    ]

    let c = 0
    walk(a, 'a', () => c++)
    expect(c).toBe(11)
  })
})
