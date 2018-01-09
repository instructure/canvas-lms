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
  'jquery'
  '../models/AssignmentOverride'
  '../models/Section'
], (Backbone, _, $, AssignmentOverride, Section) ->

  # Class Summary
  #   Assignments can have overrides ie DueDates.
  class AssignmentOverrideCollection extends Backbone.Collection

    model: AssignmentOverride

    courseSectionIDs: => @pluck 'course_section_id'

    comparator: ( override ) -> override.id

    getDefaultDueDate: =>
      @detect ( override ) ->
        override.getCourseSectionID() is Section.defaultDueDateSectionID

    containsDefaultDueDate: =>
      !!@getDefaultDueDate()

    blank: =>
      @select ( override ) -> override.isBlank()

    toJSON: =>
      json = @reject ( override ) -> override.representsDefaultDueDate()
      _.map json, ( override ) -> override.toJSON().assignment_override

    datesJSON: =>
      @map ( override ) -> override.toJSON().assignment_override

    isSimple: =>
      _.difference(@courseSectionIDs(), [Section.defaultDueDateSectionID]).length == 0
