require [
  'i18n!zip_file_imports' # I18n
  'jquery' # $
  'str/htmlEscape'
  'jquery.ajaxJSON' # getJSON
  'jquery.instructure_forms' # ajaxJSONFiles
  'jqueryui/dialog'
  'compiled/jquery.rails_flash_notifications'
  'jqueryui/progressbar' # /\.progressbar/
], (I18n, $, htmlEscape) ->

  $(document).ready ->
    $zipFile = $("#zip_file_import_form #zip_file")
    $zipFile.change ->
      val = $(this).val()
      if val && !val.match(/\.zip$/)
        $("#zip_only_message").show()
        $("#upload_form .submit_button").attr 'disabled', true
      else
        $("#zip_only_message").hide()
        $("#upload_form .submit_button").attr 'disabled', false
    $zipFile.change()

    $("#uploading_progressbar").progressbar()
    $("#zip_file_import_form").submit ->
      $("#uploading_please_wait_dialog").dialog
        bgiframe: true
        width: 400
        modal: true
        closeOnEscape: false
        dialogClass: "ui-dialog-no-close-button"
      return true

    $frame = $("<iframe id='import_frame' name='import_frame'/>")
    $("body").append $frame.hide()
    $("#zip_file_import_form").attr 'target', 'import_frame'
    $("#zip_file_import_form").submit (event) ->
      event.preventDefault()

      $("#uploading_progressbar").progressbar 'value', 0

      pollURL = null

      $("#zip_file_import_form .errors").hide()
      importFailed = (errors) ->
        $div = $("<div class='errors' style='color: #a00; font-weight: bold;'/>")
        error_message = I18n.t 'errors.extracting_file', "There were some errors extracting the zip file.  Please try again"
        $div.text error_message
        $.flashError error_message
        $("#zip_import_batch_id").val $("#zip_import_batch_id").val() + "0"
        $ul = $("<ul class='errors'/>")
        for idx in errors
          error = errors[idx]
          $li = $("<li/>")
          $li.text error
          $ul.append $li
        $("#zip_file_import_form .errors").hide()
        $("#zip_file_import_form").prepend($ul).prepend($div)
        $("#uploading_please_wait_dialog").dialog 'close'

      pollImport = ->
        $.getJSON pollURL, (data) ->
          zfi = data.zip_file_import
          if zfi == null
            pollImport.blankCount = pollImport.blankCount || 0
            pollImport.blankCount++
            if pollImport.blankCount > 10
              importFailed [I18n.t('errors.server_status', "The server stopped returning a valid status")]
            else
              setTimeout pollImport, 2000
          else if zfi.data && zfi.data.errors
            importFailed zfi.data.errors
          else if zfi.workflow_state == 'failed'
            importFailed []
          else if zfi.workflow_state == 'imported'
            $("#uploading_progressbar").progressbar 'value', 100
            $("#uploading_please_wait_dialog").prepend htmlEscape I18n.t('notices.uploading_complete', "Uploading complete!")
            location.href = $("#return_to").val()
          else
            pollImport.errorCount = 0
            pollImport.blankCount = 0
            $("#uploading_progressbar").progressbar 'value', (zfi.progress || 0) * 100
            setTimeout pollImport, 2000
        , ->
          pollImport.errorCount = pollImport.errorCount || 0
          pollImport.errorCount++
          if pollImport.errorCount > 10
            importFailed [I18n.t('errors.server_stopped_responding', "The server stopped responding to status requests")]
          else
            setTimeout pollImport, 2000

      params =
        'folder_id': $(this).find("select[name=folder_id]").val()
        'format': 'json'

      $.ajaxJSONFiles(
        $(this).attr('action')
        'POST'
        params
        $(this).find "#zip_file"
        (data) ->
          zip_import_id = data.zip_file_import.id
          pollURL = $(".zip_file_import_status_url").attr 'href'
          pollURL = $.replaceTags pollURL, 'id', zip_import_id

          pollImport()
        (data) ->
          $dialog.text I18n.t('errors.uploading', "There were errors uploading the zip file.")
      )
