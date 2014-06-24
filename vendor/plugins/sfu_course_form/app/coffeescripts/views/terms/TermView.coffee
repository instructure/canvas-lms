define [
  'jquery'
  'underscore'
  'Backbone'
  'sfu_course_form/compiled/views/courses/SelectableCourseListView'
], ($, _, Backbone, SelectableCourseListView) ->

  class TermView extends Backbone.View

    tagName: 'li'

    template: _.template '<span class="term tag"><%= name %></span>'

    render: ->
      courseListView = new SelectableCourseListView({collection: @model.courses})
      this.$el.html @template @model.toJSON()
      this.$el.append courseListView.render().el
      this
