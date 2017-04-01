/**
 * Copyright (C) 2015 - 2017 Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'underscore',
  'jquery',
  'i18n!gradebook_upload',
  'jquery.ajaxJSON'
], (_, $, I18n) => {
  const successMessage = I18n.t(
    'You will be redirected to Gradebook while your file is being uploaded. ' +
      'If you have a large CSV file, your changes may take a few minutes to update. ' +
      'To prevent overwriting any data, please confirm the upload has completed and ' +
      'Gradebook is correct before making additional changes.'
  );

  const ProcessGradebookUpload = {
    upload (gradebook) {
      if (gradebook != null && _.isArray(gradebook.assignments) && _.isArray(gradebook.students)) {
        const createAssignmentsResponses = this.createAssignments(gradebook);

        return $.when(...createAssignmentsResponses).then((...responses) => {
          this.uploadGradeData(gradebook, responses);
        });
      }
      return undefined;
    },

    createAssignments (gradebook) {
      const newAssignments = this.getNewAssignmentsFromGradebook(gradebook);
      return newAssignments.map(assignment => this.createIndividualAssignment(assignment));
    },

    getNewAssignmentsFromGradebook (gradebook) {
      return gradebook.assignments.filter(a => a.id != null && a.id <= 0);
    },

    createIndividualAssignment (assignment) {
      return $.ajaxJSON(ENV.create_assignment_path, 'POST', JSON.stringify({
        assignment: {
          name: assignment.title,
          points_possible: assignment.points_possible,
          published: true
        }
      }), null, null, {contentType: 'application/json'});
    },

    uploadGradeData (gradebook, responses) {
      const gradeData = this.populateGradeData(gradebook, responses);

      if (_.isEmpty(gradeData)) {
        this.goToGradebook();
      } else {
        this.submitGradeData(gradeData).then((progress) => {
          alert(successMessage); // eslint-disable-line no-alert
          ProcessGradebookUpload.goToGradebook();
        });
      }
    },

    populateGradeData (gradebook, responses) {
      const assignmentMap = this.mapLocalAssignmentsToDatabaseAssignments(gradebook, responses);

      const gradeData = {};
      gradebook.students.forEach(student => this.populateGradeDataPerStudent(student, assignmentMap, gradeData));
      return gradeData;
    },

    mapLocalAssignmentsToDatabaseAssignments (gradebook, responses) {
      const newAssignments = this.getNewAssignmentsFromGradebook(gradebook);
      let responsesLists = responses;

      if (newAssignments.length === 1) {
        responsesLists = [responses];
      }

      const assignmentMap = {};

      _(newAssignments).zip(responsesLists).forEach((fakeAndCreated) => {
        const [assignmentStub, response] = fakeAndCreated;
        const [createdAssignment] = response;
        assignmentMap[assignmentStub.id] = createdAssignment.id;
      });

      return assignmentMap;
    },

    populateGradeDataPerStudent (student, assignmentMap, gradeData) {
      student.submissions.forEach((submission) => {
        this.populateGradeDataPerSubmission(submission, student.previous_id, assignmentMap, gradeData);
      });
    },

    populateGradeDataPerSubmission (submission, studentId, assignmentMap, gradeData) {
      const assignmentId = assignmentMap[submission.assignment_id] || submission.assignment_id;

      if (assignmentId <= 0) return; // unrecognized and ignored assignments
      if (submission.original_grade === submission.grade) return; // no change

      gradeData[assignmentId] = gradeData[assignmentId] || {}; // eslint-disable-line no-param-reassign

      if (String(submission.grade || '').toUpperCase() === 'EX') {
        gradeData[assignmentId][studentId] = { excuse: true }; // eslint-disable-line no-param-reassign
      } else {
        gradeData[assignmentId][studentId] = { // eslint-disable-line no-param-reassign
          posted_grade: submission.grade
        };
      }
    },

    submitGradeData (gradeData) {
      return $.ajaxJSON(ENV.bulk_update_path, 'POST', JSON.stringify({grade_data: gradeData}),
        null, null, {contentType: 'application/json'});
    },

    goToGradebook () {
      $('#gradebook_grid_form').text(I18n.t('Done.'));
      window.location = ENV.gradebook_path;
    }
  };

  return ProcessGradebookUpload;
});
