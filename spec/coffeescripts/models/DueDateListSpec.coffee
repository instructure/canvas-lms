#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'compiled/models/DueDateList'
  'compiled/models/Assignment'
  'compiled/models/AssignmentOverride'
  'compiled/collections/AssignmentOverrideCollection'
  'compiled/models/Section'
  'compiled/collections/SectionCollection'
  'underscore'
], ( DueDateList, Assignment, AssignmentOverride, AssignmentOverrideCollection,
Section, SectionList, _ ) ->

  QUnit.module "DueDateList",
    setup: ->
      @date = Date.now()
      @assignment = new Assignment
        due_at: @date
        unlock_at: @date
        lock_at: @date
      @partialOverrides = new AssignmentOverrideCollection [
        new AssignmentOverride(course_section_id: '1')
        new AssignmentOverride(course_section_id: '2')
      ]
      @completeOverrides = new AssignmentOverrideCollection [
        new AssignmentOverride(course_section_id: '1')
        new AssignmentOverride(course_section_id: '2')
        new AssignmentOverride(course_section_id: '3')
      ]
      @sections = new SectionList [
        new Section id: '1', name: "CourseSection1"
        new Section id: '2', name: "CourseSection2"
        new Section id: '3', name: "CourseSection3"
      ]
      @partialOverridesList = new DueDateList @partialOverrides, @sections, @assignment
      @completeOverridesList = new DueDateList @completeOverrides, @sections, @assignment

  test """
  #containsSectionsWithoutOverrides returns true when a section's id
  does not belong to an AssignmentOverride and there isn't an
  override representing a default due date present
  """, ->
    @partialOverrides.pop() # remove the default that got added in the constructor
    strictEqual @partialOverridesList.containsSectionsWithoutOverrides(), true

  test """
  #containsSectionsWithoutOverrides returns false when overrides contain
  an override representing the default due date
  """, ->
    overridesWithDefaultDueDate =
      new AssignmentOverrideCollection(@partialOverrides.toJSON())
    overridesWithDefaultDueDate.add AssignmentOverride.defaultDueDate()
    dueDateList =
      new DueDateList overridesWithDefaultDueDate, @sections, @assignment
    strictEqual dueDateList.containsSectionsWithoutOverrides(), false

  test """
  #containsSectionsWithoutOverrides returns false if all sections belong to
  an assignment override
  """, ->
    strictEqual @completeOverridesList.containsSectionsWithoutOverrides(), false

  test """
  constructor adds an override representing the default due date using the
  assignment's due date, lock_at, and unlock_at, if an assignment is given
  and overrides don't already cover all sections
  """, ->
    strictEqual @partialOverridesList.overrides.length, 3
    override = @partialOverridesList.overrides.pop()
    strictEqual override.get('due_at'), @date
    strictEqual override.get('unlock_at'), @date
    strictEqual override.get('lock_at'), @date

  test """
    constructor adds a section to the list of sections representing the
    assignment's default due date if an assignment is given
  """, ->
    strictEqual @partialOverridesList.sections.length, 4
    strictEqual @partialOverridesList.sections.shift().id,Section.defaultDueDateSectionID

  test """
    constructor adds a section to the list of sections as an option even if all
    sections are already covered by overrids
  """, ->
    strictEqual @completeOverridesList.sections.length, 4
    strictEqual @completeOverridesList.sections.shift().id,Section.defaultDueDateSectionID

  test """
  constructor adds a default due date section if the section list passed
  is empty
  """, ->
    dueDateList = new DueDateList @partialOverrides, new SectionList([]), @assignment
    strictEqual dueDateList.sections.length, 1
