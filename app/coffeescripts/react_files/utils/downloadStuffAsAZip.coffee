define [
  'underscore'
  'i18n!react_files'
  'jquery'
  'compiled/models/Progress'
  'compiled/models/Folder'
], (_, I18n, $, Progress, Folder) ->

  downloadStuffAsAZip = (filesAndFolders, {contextType, contextId}) ->
    files = []
    folders = []
    for item in filesAndFolders
      if item instanceof Folder
        folders.push(item.id)
      else
        files.push(item.id)

    url = "/api/v1/#{contextType}/#{contextId}/content_exports"

    # This gives at least 2.5 seconds between updates of the status for screenreaders,
    # this should allow them to get the full message before it triggers another
    # reading of the message.  Technically, if the screenreader read speed is set
    # such that this is slower it won't work as intended.  But, most experienced
    # SR users set it much higher speed (300 wpm according to http://webaim.org/techniques/screenreader/)
    # This works well for the default read speed which is around 180 wpm.
    screenreaderMessageWaitTimeMS = 2500
    throttledSRMessage = _.throttle($.screenReaderFlashMessageExclusive, screenreaderMessageWaitTimeMS, leading: false)

    # TODO: handle progress events with nicer UI
    $progressIndicator = $('<div style="position: fixed; top: 4px; left: 50%; margin-left: -120px; width: 240px; z-index: 11; text-align: center; box-sizing: border-box; padding: 8px;" class="alert alert-info">')
    onProgress = (progessAPIResponse) ->
      message = I18n.t('progress_message', 'Preparing download: %{percent}% complete', {percent: progessAPIResponse.completion})
      $progressIndicator.appendTo('body').text(message)
      throttledSRMessage(message)

    data =
      export_type: 'zip'
      select:
        files:files
        folders: folders

    $(window).on 'beforeunload', promptBeforeLeaving = ->
      I18n.t('If you leave, the zip file download currently being prepared will be canceled.')

    $.post(url, data)
      .pipe (progressObject) ->
        new Progress(url: progressObject.progress_url).poll().progress(onProgress)
      .pipe (progressObject) ->
        contentExportId = progressObject.context_id
        $.get("#{url}/#{contentExportId}")
      .pipe (response) ->
        $(window).off('beforeunload', promptBeforeLeaving)
        if response.workflow_state is 'exported'
          window.location = response.attachment.url
        else
          $.flashError I18n.t('An error occurred trying to prepare download, please try again.')
      .fail ->
        $.flashError I18n.t('An error occurred trying to prepare download, please try again.')
      .always ->
        $(window).off('beforeunload', promptBeforeLeaving)
        $progressIndicator.remove()
