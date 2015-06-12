define [
  'Backbone'
  'underscore'
  'jquery'
  'compiled/models/AssignmentOverride'
  'compiled/models/Section'
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
