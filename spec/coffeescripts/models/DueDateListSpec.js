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

import DueDateList from '@canvas/due-dates/backbone/models/DueDateList'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import AssignmentOverride from '@canvas/assignments/backbone/models/AssignmentOverride'
import AssignmentOverrideCollection from '@canvas/assignments/backbone/collections/AssignmentOverrideCollection'
import Section from '@canvas/sections/backbone/models/Section'
import SectionList from '@canvas/sections/backbone/collections/SectionCollection'

QUnit.module('DueDateList', {
  setup() {
    this.date = Date.now()
    this.assignment = new Assignment({
      due_at: this.date,
      unlock_at: this.date,
      lock_at: this.date,
    })
    this.partialOverrides = new AssignmentOverrideCollection([
      new AssignmentOverride({course_section_id: '1'}),
      new AssignmentOverride({course_section_id: '2'}),
    ])
    this.completeOverrides = new AssignmentOverrideCollection([
      new AssignmentOverride({course_section_id: '1'}),
      new AssignmentOverride({course_section_id: '2'}),
      new AssignmentOverride({course_section_id: '3'}),
    ])
    this.sections = new SectionList([
      new Section({id: '1', name: 'CourseSection1'}),
      new Section({id: '2', name: 'CourseSection2'}),
      new Section({id: '3', name: 'CourseSection3'}),
    ])
    this.partialOverridesList = new DueDateList(
      this.partialOverrides,
      this.sections,
      this.assignment
    )
    this.completeOverridesList = new DueDateList(
      this.completeOverrides,
      this.sections,
      this.assignment
    )
  },
})

test(`#containsSectionsWithoutOverrides returns true when a section's id does not belong to an AssignmentOverride and there isn't an override representing a default due date present`, function () {
  this.partialOverrides.pop() // remove the default that got added in the constructor
  strictEqual(this.partialOverridesList.containsSectionsWithoutOverrides(), true)
})

test(`#containsSectionsWithoutOverrides returns false when overrides contain an override representing the default due date`, function () {
  const overridesWithDefaultDueDate = new AssignmentOverrideCollection(
    this.partialOverrides.toJSON()
  )
  overridesWithDefaultDueDate.add(AssignmentOverride.defaultDueDate())
  const dueDateList = new DueDateList(overridesWithDefaultDueDate, this.sections, this.assignment)
  strictEqual(dueDateList.containsSectionsWithoutOverrides(), false)
})

test(`#containsSectionsWithoutOverrides returns false if all sections belong to an assignment override`, function () {
  strictEqual(this.completeOverridesList.containsSectionsWithoutOverrides(), false)
})

test(`constructor adds an override representing the default due date using the assignment's due date lock_at, and unlock_at, if an assignment is given and overrides don't already cover all sections`, function () {
  strictEqual(this.partialOverridesList.overrides.length, 3)
  const override = this.partialOverridesList.overrides.pop()
  strictEqual(override.get('due_at'), this.date)
  strictEqual(override.get('unlock_at'), this.date)
  strictEqual(override.get('lock_at'), this.date)
})

test(`constructor adds a section to the list of sections representing the assignment's default due date if an assignment is given`, function () {
  strictEqual(this.partialOverridesList.sections.length, 4)
  strictEqual(this.partialOverridesList.sections.shift().id, Section.defaultDueDateSectionID)
})

test(`constructor adds a section to the list of sections as an option even if all sections are already covered by overrids`, function () {
  strictEqual(this.completeOverridesList.sections.length, 4)
  strictEqual(this.completeOverridesList.sections.shift().id, Section.defaultDueDateSectionID)
})

test(`constructor adds a default due date section if the section list passed is empty`, function () {
  const dueDateList = new DueDateList(this.partialOverrides, new SectionList([]), this.assignment)
  strictEqual(dueDateList.sections.length, 1)
})
