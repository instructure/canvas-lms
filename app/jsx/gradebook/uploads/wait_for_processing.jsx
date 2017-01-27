import $ from 'jquery'
import I18n from 'i18n!gradebook_uploads'
import 'spin.js/jquery.spin'
  function waitForProcessing(progress) {
    var dfd = $.Deferred();
    var spinner = $("#spinner").spin();

    var amIDoneYet = (progress) => {
      if (progress.workflow_state == "completed") {
        $.ajaxJSON(ENV.uploaded_gradebook_data_path, "GET").then((uploadedGradebook) => {
          spinner.hide();
          dfd.resolve(uploadedGradebook)
        });
      } else if (progress.workflow_state == "failed") {
        dfd.reject(I18n.t("Invalid CSV file. Grades could not be updated."));
      } else {
        setTimeout(function() {
          $.ajaxJSON(`/api/v1/progress/${progress.id}`, "GET")
          .then(amIDoneYet);
        }, 2000);
      }
    }
    amIDoneYet(progress);

    return dfd;
  }

export default waitForProcessing
