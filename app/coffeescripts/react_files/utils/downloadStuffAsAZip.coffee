define [
  'i18n!react_files'
  'jquery'
  'compiled/models/Progress'
  'compiled/models/Folder'
], (I18n, $, Progress, Folder) ->

  downloadStuffAsAZip = (filesAndFolders, {contextType, contextId}) ->
    files = []
    folders = []
    for item in filesAndFolders
      if item instanceof Folder
        folders.push(item.id)
      else
        files.push(item.id)

    url = "/api/v1/#{contextType}/#{contextId}/content_exports"

    # TODO: handle progress events with nicer UI
    $progressIndicator = $('<div style="position: fixed; top: 4px; left: 50%; margin-left: -120px; width: 240px; z-index: 11; text-align: center; box-sizing: border-box; padding: 8px;" class="alert alert-info">')
    onProgress = (progessAPIResponse) ->
      message = I18n.t('progress_message', 'Preparing download: %{percent}% complete', {percent: progessAPIResponse.completion})
      $progressIndicator.appendTo('body').text(message)
      $.screenReaderFlashMessage(message)

    data =
      export_type: 'zip'
      select:
        files:files
        folders: folders
    $.post(url, data)
      .pipe (progressObject) ->
        new Progress(url: progressObject.progress_url).poll().progress(onProgress)
      .pipe (progressObject) ->
        contentExportId = progressObject.context_id
        $.get("#{url}/#{contentExportId}")
      .pipe (response) ->
        window.location = response.attachment.url
      .fail ->
        $.flashError I18n.t('progress_error', 'An error occured trying to prepare download, please try again.')
      .always ->
        $progressIndicator.remove()
