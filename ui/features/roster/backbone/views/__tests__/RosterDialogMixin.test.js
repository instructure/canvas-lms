/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import RosterDialogMixin from '../RosterDialogMixin'

ENV = {
  SECTIONS: [
    {id: 1, name: 'Math'},
    {id: 2, name: 'Science'},
    {id: 3, name: 'History'},
  ],
}

describe('RosterDialogMixin', () => {
  it('should sort sections alphabetically', () => {
    const mixinInstance = Object.create(RosterDialogMixin)
    mixinInstance.model = {
      enrollments: [
        {id: 1, course_section_id: 2},
        {id: 2, course_section_id: 1},
        {id: 3, course_section_id: 3},
      ],
      get(key) {
        return this[key]
      },
      set(data) {
        Object.assign(this, data)
        return this
      },
    }

    const addEnrollments = []
    const removeEnrollments = []

    mixinInstance.updateEnrollments(addEnrollments, removeEnrollments)

    const expectedSections = [
      {id: 3, name: 'History'},
      {id: 1, name: 'Math'},
      {id: 2, name: 'Science'},
    ]
    expect(mixinInstance.model.sections).toEqual(expectedSections)
  })
})
