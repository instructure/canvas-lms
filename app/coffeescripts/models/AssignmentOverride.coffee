define [
  'Backbone'
  'underscore'
  'jquery'
  'compiled/models/Section'
], (Backbone, _, $, Section) ->

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

    parse: ( {assignment_override} ) ->
      assignment_override

    # Re-apply the original assignment_override namespace
    # since rails is expecting it.
    toJSON: ->
      assignment_override: super

    @defaultDueDate: ( options ) ->
      options ?= {}
      opts = _.extend options, { course_section_id: Section.defaultDueDateSectionID }
      new AssignmentOverride opts

    isBlank: => not @get('due_at')?

    getCourseSectionID: => @get('course_section_id')

    representsDefaultDueDate: =>
      @getCourseSectionID() is Section.defaultDueDateSectionID

