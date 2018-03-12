/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import DaySubCollection from 'compiled/collections/DaySubstitutionCollection'

QUnit.module('DaySubstitutionCollection')

test('toJSON contains nested day_substitution objects', () => {
  const collection = new DaySubCollection()
  collection.add({one: 'bar'})
  collection.add({two: 'baz'})
  const json = collection.toJSON()
  equal(json.one, 'bar', 'nested one correctly')
  equal(json.two, 'baz', 'nexted two correctly')
})
