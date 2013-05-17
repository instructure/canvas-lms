define [
  'Backbone'
  'underscore'
  'jquery'
], ({Model}, _, $) ->

  class QuickStartAssignment extends Model

    url: ->
      "/api/v1/courses/#{@get 'course_id'}/assignments"

    defaults:
      name: 'No Title'
      due_at: null
      points_possible: null
      grading_type: 'points'
      submission_types: 'online_upload,online_text_entry'
      course_id: null

    toJSON: ->
      assignment: super

