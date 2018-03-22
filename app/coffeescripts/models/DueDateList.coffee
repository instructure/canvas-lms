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
  'Backbone'
  'underscore'
  '../models/AssignmentOverride'
  '../models/Section'
], ({Model}, _, AssignmentOverride, Section) ->

  class DueDateList

    constructor: (@overrides, @sections, @assignment) ->
      @courseSectionsLength = @sections.length
      @sections.add Section.defaultDueDateSection()

      @_addOverrideForDefaultSectionIfNeeded()

    getDefaultDueDate: =>
      @overrides.getDefaultDueDate()

    overridesContainDefault: =>
      @overrides.containsDefaultDueDate()

    containsSectionsWithoutOverrides: =>
      return false if @overrides.containsDefaultDueDate()
      @sectionsWithOverrides().length < @courseSectionsLength

    sectionsWithOverrides: =>
      @sections.select (section) =>
        section.id in @_overrideSectionIDs() &&
          section.id isnt @defaultDueDateSectionId

    sectionsWithoutOverrides: =>
      @sections.select (section) =>
        section.id not in @_overrideSectionIDs() &&
          section.id isnt @defaultDueDateSectionId

    defaultDueDateSectionId: Section.defaultDueDateSectionID

    # --- private helpers ---

    _overrideSectionIDs: => @overrides.courseSectionIDs()

    _onlyVisibleToOverrides: =>
      @assignment.isOnlyVisibleToOverrides()

    _addOverrideForDefaultSectionIfNeeded: =>
      return if @_onlyVisibleToOverrides()
      override = AssignmentOverride.defaultDueDate
        due_at: @assignment.get('due_at')
        lock_at: @assignment.get('lock_at')
        unlock_at: @assignment.get('unlock_at')
      @overrides.add override
