define [
  'Backbone'
  'underscore'
  'jst/assignments/SectionDropdownView'
], (Backbone, _, template) ->
  # Class Summary
  #  Creates a dropdown of sections that can be
  #  selected for any form.
  class SectionDropdownView extends Backbone.View
    template: template
    tagName: 'select'

    events:
      'change': 'updateCourseSectionID'

    @optionProperty 'sections'
    @optionProperty 'override'

    toJSON: =>
      override: @override.toJSON().assignment_override
      sections:  _.map(@sections, (section) -> section.toJSON() )

    updateCourseSectionID: =>
      @override.set 'course_section_id', @$el.val()