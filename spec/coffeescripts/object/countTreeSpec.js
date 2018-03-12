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

import countTree from 'compiled/object/countTree'

QUnit.module('countTree')

test('counts a tree', () => {
  let obj = {a: [{a: [{a: [{}]}]}]}
  equal(countTree(obj, 'a'), 3)
  equal(countTree(obj, 'foo'), 0)
  obj = {
    a: [
      {a: [ // 1
        {a: [ // 2
          {a:[ // 3
            {}, // 4
            {} // 5
          ]},
          {a:[ // 6
            {}, // 7
            {} // 8
          ]}
        ]},
        {}, // 9
        {} // 10
      ]},
      {
        a: [] // empty
      } // 11
    ]
  }
  equal(countTree(obj, 'a'), 11)
})
