define [
  'ember'
  'ic-ajax'
  'i18n!quiz_statistics'
  'jquery.instructure_date_and_time' # fudgeDateForProfileTimezone, friendlyDatetime
], (Ember, ajax, I18n) ->
  {friendlyDatetime, fudgeDateForProfileTimezone} = Ember.$

  # This controller handles the generation of a CSV quiz report (student or item
  # analysis), tracks the progress of the generation, and auto-downloads the CSV
  # when it becomes available.
  #
  # Auto-downloading will be cancelled if the teacher refreshes the page before
  # the report is generated to minimize annoyance.
  Ember.ObjectController.extend
    isLocked: Ember.computed.alias('busy')

    readableTypeLabel: (->
      if @get('reportType') == 'item_analysis'
        I18n.t('item_analysis', 'Item Analysis')
      else
        I18n.t('student_analysis', 'Student Analysis')
    ).property('reportType')

    generatedAtLabel: (->
      I18n.t('generated_at', 'Generated at %{date}', {
        date: friendlyDatetime(fudgeDateForProfileTimezone(@get('file.created_at')))
      })
    ).property('file.created_at')

    isGenerating: (->
      Ember.A(['queued', 'running']).contains(@get('progress.workflowState'))
    ).property('progress.workflowState')

    generationStatusLabel: (->
      workflowState = @get('progress.workflowState')

      if @get 'isGenerating'
        I18n.t 'generating', 'Report is being generated...'
      else if workflowState == 'completed'
        I18n.t 'generated', 'Report is ready.'
      else if workflowState == 'failed'
        I18n.t 'generation_failed', 'Something went wrong, please try again later.'
      else
        I18n.t 'generatable', 'Report has never been generated.'
    ).property('progress.workflowState')

    actions:
      generate: ->
        return false if @get('isLocked')

        @lock()

        url = @get('quiz.links.quizReports')
        options =
          type: 'POST'
          data:
            quiz_report:
              report_type: @get('reportType')
              includes_all_versions: true

        # We'll use a transient flag to support auto-download.
        @autoDownload = true

        ajax.raw(url, options).then((reportGenerationXHR) =>
          @trackProgress(reportGenerationXHR.response.progress_url)
        ).catch(=> @unlock())

    trackProgress: (progressUrl) ->
      ajax.raw(progressUrl).then((progressResult) =>
        @set 'progress', @store.push('progress', progressResult.response)
        @get('progress').trackCompletion(1000).then =>
          @pullGeneratedReport()
      ).catch(=> @unlock())

    pullGeneratedReport: ->
      # Refresh the model to get the generated file data.
      @get('model').reload({ include: [ 'file' ] }).then(=>
        @triggerDownload() if @autoDownload
      ).finally(=> @unlock())

    triggerDownload: ->
      Ember.$('<iframe />', {
        style: 'display: none;',
        src: @get('file.url')
      }).appendTo(document.body)

    lock: ->
      @set 'busy', true

    unlock: ->
      @set 'busy', false
