define [
  'jquery'
  'underscore'
  'compiled/models/progressable'
  'Backbone'
  'jquery.instructure_date_and_time'
], ($, _, progressable, {Model}) ->

  class QuizReport extends Model
    @mixin progressable

    url: ->
      @get('url')

    # You can use this endpoint to generate the CSV attachment by POSTing to it.
    baseUrl: ->
      @url().replace(RegExp("/#{@get('id')}$"), '')

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
