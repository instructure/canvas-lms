define [
  'jquery'
  'underscore'
  'compiled/models/progressable'
  'Backbone'
  'jquery.instructure_date_and_time'
], ($, _, progressable, {Model}) ->

  class QuizReport extends Model
    @mixin progressable

    urlRoot: ->
      "/api/v1/courses/#{@get('course_id')}/quizzes/#{@get('quiz_id')}/reports"

    toJSON: ->
      quiz_report: _.pick super,
        'report_type'
        'includes_all_versions'

    present: ->
      data = _.extend {}, @attributes
      if @progressModel.id
        data.progress = @progressModel.toJSON()
      if data.file
        data.dateAndTime = $.datetimeString(data.file.created_at)
      data
