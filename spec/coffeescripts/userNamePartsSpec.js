/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import {nameParts} from 'user_utils'

QUnit.module('UserNameParts')

test('should infer name parts', () => {
  deepEqual(nameParts('Cody Cutrer'), ['Cody', 'Cutrer', null])
  deepEqual(nameParts('  Cody  Cutrer   '), ['Cody', 'Cutrer', null])
  deepEqual(nameParts('Cutrer, Cody'), ['Cody', 'Cutrer', null])
  deepEqual(nameParts('Cutrer, Cody Houston'), ['Cody Houston', 'Cutrer', null])
  deepEqual(nameParts('St. Clair, John'), ['John', 'St. Clair', null])
  deepEqual(nameParts('John St. Clair'), ['John St.', 'Clair', null])
  deepEqual(nameParts('Jefferson Thomas Cutrer, IV'), ['Jefferson Thomas', 'Cutrer', 'IV'])
  deepEqual(nameParts('Jefferson Thomas Cutrer IV'), ['Jefferson Thomas', 'Cutrer', 'IV'])
  deepEqual(nameParts(null), [null, null, null])
  deepEqual(nameParts('Bob'), ['Bob', null, null])
  deepEqual(nameParts('Ho, Chi, Min'), ['Chi Min', 'Ho', null])
  deepEqual(nameParts('Ho Chi Min'), ['Ho Chi', 'Min', null])
  deepEqual(nameParts(''), [null, null, null])
  deepEqual(nameParts('John Doe'), ['John', 'Doe', null])
  deepEqual(nameParts('Junior'), ['Junior', null, null])
})

test('should use prior_surname', () => {
  deepEqual(nameParts('John St. Clair', 'St. Clair'), ['John', 'St. Clair', null])
  deepEqual(nameParts('John St. Clair', 'Cutrer'), ['John St.', 'Clair', null])
  deepEqual(nameParts('St. Clair', 'St. Clair'), [null, 'St. Clair', null])
})

test('should infer surname with no given name', () => {
  deepEqual(nameParts('St. Clair,'), [null, 'St. Clair', null])
})
