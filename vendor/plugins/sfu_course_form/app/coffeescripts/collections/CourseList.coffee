define [
  'jquery'
  'underscore'
  'Backbone'
  'sfu_course_form/compiled/models/Course'
], ($, _, Backbone, Course) ->

  class CourseList extends Backbone.Collection

    initialize: (@term) ->
      @on 'reset', ->
        @each ( (course) -> course.term = @term ), this
      super

    fetch: (options) ->
      @trigger 'request'
      Backbone.Collection.prototype.fetch.call(this, options)

    model: Course

    url: -> "/sfu/api/v1/amaint/user/#{@userId}/term/#{@term.get 'sis_source_id'}"

    comparator: (course) -> course.get 'sis_source_id'

    addUnique: (course) ->
      @add(course) if @every (existingCourse) ->
        existingCourse.get('sis_source_id') != course.get('sis_source_id')

    terms: -> _.uniq @map (course) -> course.term
