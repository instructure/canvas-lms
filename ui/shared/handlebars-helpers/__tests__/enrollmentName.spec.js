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

import enrollmentName from '../enrollmentName'

describe('enrollmentName', () => {
  test('it converts a role name to the name', () => {
    expect(enrollmentName('StudentEnrollment')).toEqual('Student')
    expect(enrollmentName('TeacherEnrollment')).toEqual('Teacher')
    expect(enrollmentName('TaEnrollment')).toEqual('TA')
    expect(enrollmentName('ObserverEnrollment')).toEqual('Observer')
    expect(enrollmentName('DesignerEnrollment')).toEqual('Designer')
    expect(enrollmentName('no match')).toEqual('no match')
  })
})
