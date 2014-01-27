define [
  'jquery'
  'underscore'
  'Backbone'
  'sfu_course_form/compiled/views/courses/CourseView'
], ($, _, Backbone, CourseView) ->

  class SelectableCourseView extends CourseView

    template: _.template '<div><input type="checkbox" id="chk-course-<%= cid %>-<%= sis_source_id %>" <% if (selected) { %>checked="checked"<% } %> /> <label for="chk-course-<%= cid %>-<%= sis_source_id %>"><span class="term tag"><%= term %></span> <%= displayName %><% if (sectionTutorials.length) { %></div><div class="tutorial_sections">&mdash; includes tutorial sections: <%= sectionTutorials.join(", ") %></div><% } %></label>'

    render: ->
      # cid maintains checkbox uniqueness when multiple courses with the same sis_source_id are present
      # (e.g. when user searches for exactly the same courses as the ones suggested)
      this.$el.html @template $.extend @model.toJSON(), {cid: @model.cid}
      this

    events: {
      'change input': 'handleChange'
    }

    handleChange: (event) ->
      @model.selected = event.target.checked
      $(document).trigger('selectablecoursechange', [@model, event.target.checked])
