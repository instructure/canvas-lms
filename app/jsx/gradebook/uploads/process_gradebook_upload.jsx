/** @jsx React.DOM */

define(['underscore', 'i18n!gradebok_upload', 'compiled/userSettings'], function(_, I18n, userSettings) {

  var processGradebookUpload = function(uploadedGradebook) {
    return makeNewAssignments(uploadedGradebook)
    .pipe(submitBulkUpdate)
    .pipe(monitorProgress);
  };


  var makeNewAssignments = function(uploadedGradebook) {
    var newAssignments = uploadedGradebook.assignments.filter(a => a.id <= 0);
    var createAssignmentDfds = newAssignments.map(assignment => {
      return $.ajaxJSON(ENV.create_assignment_path, "POST", {
        assignment: {
          name: assignment.title,
          points_possible: assignment.points_possible,
          published: true
        }
      });
    });

    return $.when.apply(null, createAssignmentDfds).pipe(function(...responses) {
      if (newAssignments.length == 1)
        responses = [responses];

      var createdAssignmentIds = {};
      _(newAssignments).zip(responses).forEach(fake_and_created => {
        var [fake, [created,]] = fake_and_created;
        createdAssignmentIds[fake.id] = created.id;
      });

      return [uploadedGradebook, createdAssignmentIds];
    });
  };

  var submitBulkUpdate = function(argv) {
    var [uploadedGradebook, newAssignmentIds] = argv;
    var bulkGradeData = {};

    uploadedGradebook.students.forEach(student => {
      var userId = student.previous_id;
      student.submissions.forEach(submission => {
        var assignmentId = newAssignmentIds[submission.assignment_id] ||
                           submission.assignment_id;

        if (assignmentId <= 0) return; // unrecognized and ignored assignments
        if (submission.original_grade === submission.grade) return; // no change

        bulkGradeData[assignmentId] = bulkGradeData[assignmentId] || {};
        bulkGradeData[assignmentId][userId] = ((submission.grade || "").toUpperCase() === "EX") ?
          {excuse: true} :
          {posted_grade: submission.grade};
      });
    });

    return $.ajaxJSON(ENV.bulk_update_path, "POST", {grade_data: bulkGradeData})
  };


  var monitorProgress = function(progress) {
    // TODO: pandapush?
    var dfd = $.Deferred();

    alert(I18n.t("Your file is being uploaded to the Gradebook, and you can leave this page at any time. If you have a large CSV file, your changes may take a few minutes to update. To prevent overwriting any data, please confirm the upload has completed and your Gradebook is correct before making additional changes."));

    var amIDoneYet = (progress) => {
      if (progress.workflow_state == "completed" ||
          progress.workflow_state == "failed") {
        $("#gradebook_grid_form").text(I18n.t("Done."));
        dfd.resolve();
        if (progress.workflow_state === "completed") {
          userSettings.contextSet('gradebookUploadComplete', true);
        }
        window.location = ENV.gradebook_path;
      } else {
        setTimeout(function() {
          $.ajaxJSON(`/api/v1/progress/${progress.id}`, "GET")
          .then(amIDoneYet);
        }, 2000);
      }
    };
    amIDoneYet(progress);

    return dfd;
  }

  return processGradebookUpload;
});
