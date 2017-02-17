define(["jquery", "i18n!gradebook_uploads", "spin.js/jquery.spin"],
       ($, I18n) => {
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

  return waitForProcessing;
});
