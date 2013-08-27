define [
  'jquery'
  'underscore'
  'Backbone'
  'sfu_course_form/compiled/views/courses/CourseListView'
  'sfu_course_form/compiled/views/courses/SelectableCourseView'
], ($, _, Backbone, CourseListView, SelectableCourseView) ->

  class SelectableCourseListView extends CourseListView

    renderOne: (course) ->
      courseView = new SelectableCourseView({model: course})
      this.$el.append courseView.render().el
