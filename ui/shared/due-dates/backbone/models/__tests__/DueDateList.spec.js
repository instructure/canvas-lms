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

import DueDateList from '../DueDateList'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import AssignmentOverride from '@canvas/assignments/backbone/models/AssignmentOverride'
import AssignmentOverrideCollection from '@canvas/assignments/backbone/collections/AssignmentOverrideCollection'
import Section from '@canvas/sections/backbone/models/Section'
import SectionList from '@canvas/sections/backbone/collections/SectionCollection'

describe('DueDateList', () => {
  let date,
    assignment,
    partialOverrides,
    completeOverrides,
    sections,
    partialOverridesList,
    completeOverridesList

  beforeEach(() => {
    date = Date.now()
    assignment = new Assignment({
      due_at: date,
      unlock_at: date,
      lock_at: date,
    })
    partialOverrides = new AssignmentOverrideCollection([
      new AssignmentOverride({course_section_id: '1'}),
      new AssignmentOverride({course_section_id: '2'}),
    ])
    completeOverrides = new AssignmentOverrideCollection([
      new AssignmentOverride({course_section_id: '1'}),
      new AssignmentOverride({course_section_id: '2'}),
      new AssignmentOverride({course_section_id: '3'}),
    ])
    sections = new SectionList([
      new Section({id: '1', name: 'CourseSection1'}),
      new Section({id: '2', name: 'CourseSection2'}),
      new Section({id: '3', name: 'CourseSection3'}),
    ])
    partialOverridesList = new DueDateList(partialOverrides, sections, assignment)
    completeOverridesList = new DueDateList(completeOverrides, sections, assignment)
  })

  test(`containsSectionsWithoutOverrides returns true when a section's id does not belong to an AssignmentOverride and there isn't an override representing a default due date present`, () => {
    partialOverrides.pop() // remove the default that got added in the constructor
    expect(partialOverridesList.containsSectionsWithoutOverrides()).toBe(true)
  })

  test(`containsSectionsWithoutOverrides returns false when overrides contain an override representing the default due date`, () => {
    const overridesWithDefaultDueDate = new AssignmentOverrideCollection(partialOverrides.toJSON())
    overridesWithDefaultDueDate.add(AssignmentOverride.defaultDueDate())
    const dueDateList = new DueDateList(overridesWithDefaultDueDate, sections, assignment)
    expect(dueDateList.containsSectionsWithoutOverrides()).toBe(false)
  })

  test(`containsSectionsWithoutOverrides returns false if all sections belong to an assignment override`, () => {
    expect(completeOverridesList.containsSectionsWithoutOverrides()).toBe(false)
  })

  test(`constructor adds an override representing the default due date using the assignment's due date, lock_at, and unlock_at, if an assignment is given and overrides don't already cover all sections`, () => {
    expect(partialOverridesList.overrides.length).toBe(3)
    const override = partialOverridesList.overrides.pop()
    expect(override.get('due_at')).toBe(date)
    expect(override.get('unlock_at')).toBe(date)
    expect(override.get('lock_at')).toBe(date)
  })

  test(`constructor adds a section to the list of sections representing the assignment's default due date if an assignment is given`, () => {
    expect(partialOverridesList.sections.length).toBe(4)
    expect(partialOverridesList.sections.shift().id).toBe(Section.defaultDueDateSectionID)
  })

  test(`constructor adds a section to the list of sections as an option even if all sections are already covered by overrides`, () => {
    expect(completeOverridesList.sections.length).toBe(4)
    expect(completeOverridesList.sections.shift().id).toBe(Section.defaultDueDateSectionID)
  })

  test(`constructor adds a default due date section if the section list passed is empty`, () => {
    const dueDateList = new DueDateList(partialOverrides, new SectionList([]), assignment)
    expect(dueDateList.sections.length).toBe(1)
  })
})
