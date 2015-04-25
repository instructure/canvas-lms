define [
  'i18n!submissions'
  'ember'
  '../register'
  '../templates/components/ic-submission-download-dialog'
  'jqueryui/progressbar'
  'jqueryui/dialog'
], (I18n, Ember, register) ->


  # example usage:
  #
  #   {{
  #     ic-submission-download-dialog
  #     assignmentUrl=assignment_url
  #   }}


  register 'component', 'ic-submission-download-dialog', Ember.Component.extend

    isOpened: false

    isChecking: true

    attachment: {}

    percentComplete: 0

    hideIndicator: Ember.computed.not('isChecking')

    showFileLink: Ember.computed.equal('status', 'finished')

    sizeOfFile: Ember.computed.alias('attachment.readable_size')

    dialogTitle: I18n.t('download_submissions_title', 'Download Assignment Submissions')

    bindFunctions: (->
      @reviewProgress = @reviewProgress.bind(this)
      @progressError = @progressError.bind(this)
      @checkForChange = @checkForChange.bind(this)
    ).on('init')

    status: (->
      if @fileReady()
        'finished'
      else if @get('percentComplete') >= 95
        'zipping'
      else
        'starting'
    ).property('attachment', 'percentComplete', 'isOpened')

    progress: (->
      attachment = @get('attachment')
      new_val = 0
      if attachment && @fileReady()
        new_val = 100
      else if attachment
        new_val = @get('percentComplete')
        new_val += 5 if @get('percentComplete') < 95
        state = parseInt(@get('attachment.file_state'))
        new_val = 0 if isNaN(state)

      @set('percentComplete', new_val)
    ).observes('attachment')

    keepChecking: (->
      true unless @get('percentComplete') == 100 || !@get('isOpened')
    ).property('percentComplete', 'isOpened')

    url: (->
      "#{@get('assignmentUrl')}/submissions?zip=1"
    ).property('assignmentUrl')

    statusText: (->
      switch @get('status')
        when 'starting' then I18n.t 'gathering_files', "Gathering Files (%{progress})...", {progress: I18n.toPercentage(@get('percentComplete'), precision: 0)}
        when 'zipping'  then I18n.t "creating_zip", "Creating zip file..."
        when 'finished' then I18n.t "finished_redirecting", "Finished!  Redirecting to File..."
    ).property('status', 'percentComplete')

    updateProgressBar: (->
      $("#progressbar").progressbar value: @get('percentComplete')
    ).observes('percentComplete')

    downloadCompletedFile: (->
      if @get('percentComplete') == 100
        location.href = @get('url')
    ).observes('percentComplete')

    resetAttachment: (->
      @set('attachment', null)
    ).observes('isOpened')

    closeOnEsc: ( (event) ->
      if event.keyCode == 27 #esc
        @close()
    ).on('keyDown')

    actions:
      openDialog: ->
        @set('isOpened', true)
        @dialogOptions ?=
          title: "Download Assignment Submissions"
          resizable: false
        @$dialog ?= $("#submissions_download_dialog form").dialog(@dialogOptions)
        @$dialog.dialog()
        @checkForChange()

      closeDialog: ->
        @close()

    close: ->
      @$dialog.dialog('close')
      @set('isOpened', false)

    fileReady: ->
      state = @get('attachment.workflow_state')
      state == 'zipped' || state == 'available'

    checkForChange: ->
      @set('isChecking', true)
      $.ajaxJSON(@get('url'), 'GET', {}, @reviewProgress, @progressError)

    reviewProgress: (data) ->
      @set('isChecking', false)
      @set('attachment', data.attachment)
      @setCheckTimeOut 3000

    progressError: ->
      @set('isChecking', false)
      @setCheckTimeOut 1000

    setCheckTimeOut: (time) ->
      if @get('keepChecking')
        setTimeout @checkForChange, time
