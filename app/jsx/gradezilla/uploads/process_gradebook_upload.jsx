define([
  'underscore',
  'jquery',
  'i18n!gradezilla_upload',
  'compiled/userSettings'
], function(_, $, I18n, userSettings) {
  let ProcessGradebookUpload = {
    upload: function(gradebook) {
      if(gradebook != null && _.isArray(gradebook.assignments) && _.isArray(gradebook.students)) {
        const createAssignmentsResponses = this.createAssignments(gradebook);

        return $.when(...createAssignmentsResponses).then((...responses) => {
          this.uploadGradeData(gradebook, responses);
        });
      }
    },

    createAssignments: function(gradebook) {
      const newAssignments = this.getNewAssignmentsFromGradebook(gradebook);
      return newAssignments.map(assignment => this.createIndividualAssignment(assignment));
    },

    getNewAssignmentsFromGradebook: function(gradebook) {
      return gradebook.assignments.filter(a => a.id != null && a.id <= 0);
    },

    createIndividualAssignment: function(assignment) {
      return $.ajaxJSON(ENV.create_assignment_path, 'POST', JSON.stringify({
        assignment: {
          name: assignment.title,
          points_possible: assignment.points_possible,
          published: true
        }
      }), null, null, {contentType: 'application/json'});
    },

    uploadGradeData: function(gradebook, responses) {
      const gradeData = this.populateGradeData(gradebook, responses);

      if (_.isEmpty(gradeData)) {
        this.goToGradebook();
      } else {
        this.submitGradeData(gradeData).then((progress) => {
          alert(I18n.t("Your file is being uploaded to Gradebook, and you can leave this page at any time. If you have a large CSV file, your changes may take a few minutes to update. To prevent overwriting any data, please confirm the upload has completed and Gradebook is correct before making additional changes."));
          this.monitorProgress(progress);
        });
      }
    },

    populateGradeData: function(gradebook, responses) {
      const assignmentMap = this.mapLocalAssignmentsToDatabaseAssignments(gradebook, responses);

      let gradeData = {};
      gradebook.students.forEach(student => this.populateGradeDataPerStudent(student, assignmentMap, gradeData));
      return gradeData;
    },

    mapLocalAssignmentsToDatabaseAssignments: function(gradebook, responses) {
      const newAssignments = this.getNewAssignmentsFromGradebook(gradebook);

      if (newAssignments.length === 1) {
        responses = [responses];
      }

      let assignmentMap = {};

      _(newAssignments).zip(responses).forEach(fake_and_created => {
        var [fake, [created,]] = fake_and_created;
        assignmentMap[fake.id] = created.id;
      });

      return assignmentMap;
    },

    populateGradeDataPerStudent: function(student, assignmentMap, gradeData) {
      student.submissions.forEach(submission =>
        this.populateGradeDataPerSubmission(submission, student.previous_id, assignmentMap, gradeData));
    },

    populateGradeDataPerSubmission: function(submission, studentId, assignmentMap, gradeData) {
      const assignmentId = assignmentMap[submission.assignment_id] || submission.assignment_id;

      if (assignmentId <= 0) return; // unrecognized and ignored assignments
      if (submission.original_grade === submission.grade) return; // no change

      gradeData[assignmentId] = gradeData[assignmentId] || {};

      gradeData[assignmentId][studentId] = ((submission.grade || '').toUpperCase() === 'EX') ?
        {excuse: true} :
        {posted_grade: submission.grade};
    },

    submitGradeData: function(gradeData) {
      return $.ajaxJSON(ENV.bulk_update_path, 'POST', JSON.stringify({grade_data: gradeData}),
        null, null, {contentType: 'application/json'});
    },

    monitorProgress: function(progress) {
      if (progress.workflow_state === 'completed') {
        userSettings.contextSet('gradebookUploadComplete', true);
        this.goToGradebook();
      } else if (progress.workflow_state === 'failed') {
        this.goToGradebook();
      } else {
        this.checkProgress(progress);
      }
    },

    checkProgress: function(progress) {
      setTimeout(() => {
        return $.ajaxJSON(`/api/v1/progress/${progress.id}`, "GET")
          .then((progress) => { this.monitorProgress(progress); });
      }, 2000);
    },

    goToGradebook: function() {
      $('#gradebook_grid_form').text(I18n.t('Done.'));
      window.location = ENV.gradebook_path;
    }
  };

  return ProcessGradebookUpload;
});
