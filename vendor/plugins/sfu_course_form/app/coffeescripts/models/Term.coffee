define [
  'jquery'
  'underscore'
  'Backbone'
  'sfu_course_form/compiled/collections/CourseList'
], ($, _, Backbone, CourseList) ->

  class Term extends Backbone.Model

    initialize: ->
      @courses = new CourseList()
      super

    fetchCourses: (userId) ->
      @courses.userId = userId
      @courses.term = this
      @courses.fetch()
