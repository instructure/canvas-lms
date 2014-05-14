define [
  'jquery'
  'underscore'
  'Backbone'
  'jst/quiz_reports/quizReportGenerator'
  'compiled/models/QuizReport'
], ($, _, {View}, quizReportGenerator, QuizReport) ->

  class QuizReportGenerator extends View
    template: quizReportGenerator

    initialize: ->
      super
      if progress = @model.get('progress')
        @model.progressModel.set progress
      @model.progressModel.on 'change', @render
      @model.on 'progressResolved', @reportReady

    events:
      'click .create-report': ->
        @autoDownload = true # if they refresh the page, we don't want to auto-download once the progress bar completes
        @model.save({}, {type: 'POST'})

    reportReady: =>
      @render()
      @triggerDownload() if @autoDownload

    triggerDownload: ->
      url = @model.get('file').url
      $(document.body).append $('<iframe>', style: 'display:none', src: url)

