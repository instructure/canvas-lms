define([
  'INST' /* INST */,
  'i18n!submissions',
  'jquery' /* $ */,
  'str/htmlEscape',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jqueryui/dialog',
  'jqueryui/progressbar' /* /\.progressbar/ */
], function(INST, I18n, $, htmlEscape) {

  INST.downloadSubmissions = function(url) {
    var cancelled = false;
    var title = ENV.SUBMISSION_DOWNLOAD_DIALOG_TITLE;
    title = title || I18n.t('#submissions.download_submissions',
                            'Download Assignment Submissions');
    $("#download_submissions_dialog").dialog({
      title: title,
      close: function() {
        cancelled = true;
      }
    });
    $("#download_submissions_dialog .progress").progressbar({value: 0});
    var checkForChange = function() {
      if(cancelled || $("#download_submissions_dialog:visible").length == 0) { return; }
      $("#download_submissions_dialog .status_loader").css('visibility', 'visible');
      var lastProgress = null;
      $.ajaxJSON(url, 'GET', {}, function(data) {
        if(data && data.attachment) {
          var attachment = data.attachment;
          if(attachment.workflow_state == 'zipped') { 
            $("#download_submissions_dialog .progress").progressbar('value', 100);
            var message = I18n.t("#submissions.finished_redirecting", "Finished!  Redirecting to File...");
            var link = "<a href=\"" + htmlEscape(url) + "\"><b> " + htmlEscape(I18n.t("#submissions.click_to_download", "Click here to download %{size_of_file}", {size_of_file: attachment.readable_size})) + "</b></a>"
            $("#download_submissions_dialog .status").html(htmlEscape(message) + "<br>" + $.raw(link));
            $("#download_submissions_dialog .status_loader").css('visibility', 'hidden');
            location.href = url;
            return;
          } else {
            var progress = parseInt(attachment.file_state, 10);
            if(isNaN(progress)) { progress = 0; }
            progress += 5
            $("#download_submissions_dialog .progress").progressbar('value', progress);
            var message = null;
            if(progress >= 95){
              message = I18n.t("#submissions.creating_zip", "Creating zip file...");
            } else {
              message = I18n.t("#submissions.gathering_files_progress", "Gathering Files (%{progress})...", {progress: I18n.toPercentage(progress)});
            }
            $("#download_submissions_dialog .status").text(message);
            if(progress <= 5 || progress == lastProgress) {
              $.ajaxJSON(url + "&compile=1", 'GET', {}, function() {}, function() {});
            }
            lastProgress = progress;
          }
        }
        $("#download_submissions_dialog .status_loader").css('visibility', 'hidden');
        setTimeout(checkForChange, 3000);
      }, function(data) {
        $("#download_submissions_dialog .status_loader").css('visibility', 'hidden');
        setTimeout(checkForChange, 1000);
      });
    }
    checkForChange();
  };
});
