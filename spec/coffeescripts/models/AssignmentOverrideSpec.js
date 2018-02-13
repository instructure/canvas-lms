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
  'compiled/models/AssignmentOverride'
  'compiled/models/Assignment'
], ( AssignmentOverride, Assignment ) ->

  QUnit.module "AssignmentOverride",
    setup: ->
      @clock = sinon.useFakeTimers()

    teardown: -> @clock.restore()

  test "#representsDefaultDueDate returns true if course_section_id == '0'", ->
    override = new AssignmentOverride course_section_id: '0'
    strictEqual override.representsDefaultDueDate(), true

  test "#representsDefaultDueDate returns false if course_section_id != '0'", ->
    override = new AssignmentOverride course_section_id: '11'
    strictEqual override.representsDefaultDueDate(), false

  test "#AssignmentOverride.defaultDueDate class method returns an AssignmentOverride that represents the default due date", ->
    override = AssignmentOverride.defaultDueDate()
    strictEqual override.representsDefaultDueDate(), true

  test "updates id to undefined if course_section_changes", ->
    override = new AssignmentOverride id: 1, course_section_id: 1
    override.set 'course_section_id', 3
    strictEqual override.toJSON().assignment_override.id ,undefined

  test "#combinedDates returns unique values for overrides with the same due date", ->
    due_date = new Date
    override1 = new AssignmentOverride id: 1, due_at: due_date.toISOString()
    override2 = new AssignmentOverride id: 2, due_at: due_date.toISOString()
    notEqual override1.combinedDates(), override2.combinedDates()
