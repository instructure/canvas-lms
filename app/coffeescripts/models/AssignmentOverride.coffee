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
  '../models/Section'
  'i18n!assignments',
], (Backbone, _, $, Section, I18n) ->

  class AssignmentOverride extends Backbone.Model

    defaults:
      due_at_overridden: true
      due_at: null
      all_day: false
      all_day_date: null

      unlock_at_overridden: true
      unlock_at: null

      lock_at_overridden: true
      lock_at: null

    @conditionalRelease:
      name: I18n.t("Mastery Paths")
      noop_id: '1'

    initialize: ->
      super
      @on 'change:course_section_id', @clearID, this

    # This method exists because the api cannot currently update the
    # course_section_id for an assignment override.
    clearID: ->
      @set 'id', undefined

    parse: ( {assignment_override} ) ->
      assignment_override

    # Re-apply the original assignment_override namespace
    # since rails is expecting it.
    toJSON: ->
      assignment_override: super

    @defaultDueDate: ( options ) ->
      options ?= {}
      opts = _.extend options,
        {course_section_id: Section.defaultDueDateSectionID}
      new AssignmentOverride opts

    isBlank: => not @get('due_at')?

    getCourseSectionID: => @get('course_section_id')

    representsDefaultDueDate: =>
      @getCourseSectionID() is Section.defaultDueDateSectionID

    combinedDates: =>
      # using this as a key to sort overrides
      # into rows in the due date picker
      override_id = if @get("id") is undefined then null else @get("id")
      "#{@get("due_at") + @get("unlock_at") + @get("lock_at") + override_id}"