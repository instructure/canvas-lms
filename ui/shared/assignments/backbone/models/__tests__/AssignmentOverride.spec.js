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

import AssignmentOverride from '../AssignmentOverride'
import '../Assignment'

describe('AssignmentOverride', () => {
  let clock

  beforeEach(() => {
    clock = jest.spyOn(global, 'Date').mockImplementation(() => ({
      toISOString: jest.fn(() => '2022-01-01T00:00:00.000Z'),
    }))
  })

  afterEach(() => {
    clock.mockRestore()
  })

  test("#representsDefaultDueDate returns true if course_section_id == '0'", () => {
    const override = new AssignmentOverride({course_section_id: '0'})
    expect(override.representsDefaultDueDate()).toBe(true)
  })

  test("#representsDefaultDueDate returns false if course_section_id != '0'", () => {
    const override = new AssignmentOverride({course_section_id: '11'})
    expect(override.representsDefaultDueDate()).toBe(false)
  })

  test('#AssignmentOverride.defaultDueDate class method returns an AssignmentOverride that represents the default due date', () => {
    const override = AssignmentOverride.defaultDueDate()
    expect(override.representsDefaultDueDate()).toBe(true)
  })

  test('updates id to undefined if course_section_changes', () => {
    const override = new AssignmentOverride({
      id: 1,
      course_section_id: 1,
    })
    override.set('course_section_id', 3)
    expect(override.toJSON().assignment_override.id).toBeUndefined()
  })

  test('#combinedDates returns unique values for overrides with the same due date', () => {
    const due_date = new Date()
    const override1 = new AssignmentOverride({
      id: 1,
      due_at: due_date.toISOString(),
    })
    const override2 = new AssignmentOverride({
      id: 2,
      due_at: due_date.toISOString(),
    })
    expect(override1.combinedDates()).not.toBe(override2.combinedDates())
  })
})
