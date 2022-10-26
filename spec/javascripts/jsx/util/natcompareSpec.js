/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import natcompare from '@canvas/util/natcompare'

const valuesToSort = [
  {id: 1, name: 'john, john'},
  {id: 2, name: 'abel'},
  {id: 3, name: 'John, John'},
  {id: 4, name: 'abel'},
  {id: 5, name: 'johnson, john'},
  {id: 6, name: 'âbel'},
  {id: 7, name: 'Abel'},
  {id: 8, name: 'joh, jonny'},
  {id: 9, name: 'joh  jonny'},
]

QUnit.module('sorts values properly when used to compare strings')

test('puts remaining words in the right order since there are no collisions possible', () => {
  const expectedSortedStrings = [
    'abel',
    'abel',
    'Abel',
    'âbel',
    'joh  jonny',
    'joh, jonny',
    'john, john',
    'John, John',
    'johnson, john',
  ]
  const sortedValueNames = valuesToSort.sort(natcompare.byKey('name')).map(item => item.name)

  deepEqual(sortedValueNames, expectedSortedStrings)
})
