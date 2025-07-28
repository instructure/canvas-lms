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

import {nameParts} from '../user_utils'

describe('UserNameParts', () => {
  test('should infer name parts', () => {
    expect(nameParts('Cody Cutrer')).toEqual(['Cody', 'Cutrer', null])
    expect(nameParts('  Cody  Cutrer   ')).toEqual(['Cody', 'Cutrer', null])
    expect(nameParts('Cutrer, Cody')).toEqual(['Cody', 'Cutrer', null])
    expect(nameParts('Cutrer, Cody Houston')).toEqual(['Cody Houston', 'Cutrer', null])
    expect(nameParts('St. Clair, John')).toEqual(['John', 'St. Clair', null])
    expect(nameParts('John St. Clair')).toEqual(['John St.', 'Clair', null])
    expect(nameParts('Jefferson Thomas Cutrer, IV')).toEqual(['Jefferson Thomas', 'Cutrer', 'IV'])
    expect(nameParts('Jefferson Thomas Cutrer IV')).toEqual(['Jefferson Thomas', 'Cutrer', 'IV'])
    expect(nameParts(null)).toEqual([null, null, null])
    expect(nameParts('Bob')).toEqual(['Bob', null, null])
    expect(nameParts('Ho, Chi, Min')).toEqual(['Chi Min', 'Ho', null])
    expect(nameParts('Ho Chi Min')).toEqual(['Ho Chi', 'Min', null])
    expect(nameParts('')).toEqual([null, null, null])
    expect(nameParts('John Doe')).toEqual(['John', 'Doe', null])
    expect(nameParts('Junior')).toEqual(['Junior', null, null])
  })

  test('should use prior_surname', () => {
    expect(nameParts('John St. Clair', 'St. Clair')).toEqual(['John', 'St. Clair', null])
    expect(nameParts('John St. Clair', 'Cutrer')).toEqual(['John St.', 'Clair', null])
    expect(nameParts('St. Clair', 'St. Clair')).toEqual([null, 'St. Clair', null])
  })

  test('should infer surname with no given name', () => {
    expect(nameParts('St. Clair,')).toEqual([null, 'St. Clair', null])
  })
})
