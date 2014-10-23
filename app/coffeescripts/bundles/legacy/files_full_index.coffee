require [
  "INST",
  "i18n!files.full_index",
  "jquery",
  'str/htmlEscape',
  "jquery.ajaxJSON",
  "jquery.instructure_date_and_time",
  "jqueryui/dialog",
  "jqueryui/progressbar",
], (INST, I18n, $, htmlEscape) ->
  INST.downloadFolderFiles = (url) ->
    cancelled = false
    $("#download_folder_files_dialog .status_box .status").text I18n.t("messages.gathering_data", "Gathering data...")
    $("#download_folder_files_dialog").dialog
      title: I18n.t("titles.download_folder_contents", "Download Folder Contents")
      close: ->
        cancelled = true

    $("#download_folder_files_dialog .progress").progressbar value: 0
    checkForChange = ->
      return if cancelled or $("#download_folder_files_dialog:visible").length is 0
      $("#download_folder_files_dialog .status_loader").css "visibility", "visible"
      lastProgress = null
      $.ajaxJSON url, "GET", {}, ((data) ->
        if data and data.attachment
          attachment = data.attachment
          if attachment.workflow_state is "zipped"
            $("#download_folder_files_dialog .progress").progressbar "value", 100
            html = htmlEscape(I18n.t("messages.zip_finished", "Finished!  Redirecting to File..."))
            html += "<br/><a href='" + htmlEscape(url) + "'><b>"
            html += htmlEscape(I18n.t("links.download_zip", "Click here to download %{size}", {size: attachment.readable_size}))
            html += "</b></a>"
            $("#download_folder_files_dialog .status").html html
            $("#download_folder_files_dialog .status_loader").css "visibility", "hidden"
            location.href = url
            return
          else
            progress = parseInt(attachment.file_state, 10)
            progress = 0  if isNaN(progress)
            progress += 5
            $("#download_folder_files_dialog .progress").progressbar "value", progress
            $("#download_folder_files_dialog .status").text (if progress >= 95 then I18n.t("messages.creating_zip", "Creating zip file...") else I18n.t("messages.gathering_files_with_progress", "Gathering Files (%{progress}%)...", {progress: progress}))
            if progress <= 5 or progress is lastProgress
              $.ajaxJSON url + "?compile=1", "GET", {}, (->
              ), ->

            lastProgress = progress
        $("#download_folder_files_dialog .status_loader").css "visibility", "hidden"
        setTimeout checkForChange, 3000
      ), (data) ->
        $("#download_folder_files_dialog .status_loader").css "visibility", "hidden"
        setTimeout checkForChange, 1000

    checkForChange()
