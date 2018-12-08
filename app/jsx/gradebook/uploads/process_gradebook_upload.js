/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import _ from 'underscore'
import $ from 'jquery'
import I18n from 'i18n!gradebook_upload'
import 'jquery.ajaxJSON'

  const successMessage = I18n.t(
    'You will be redirected to Gradebook while your file is being uploaded. ' +
      'If you have a large CSV file, your changes may take a few minutes to update. ' +
      'To prevent overwriting any data, please confirm the upload has completed and ' +
      'Gradebook is correct before making additional changes.'
  );

  const ProcessGradebookUpload = {
    upload (gradebook) {
      if (gradebook != null && (_.isArray(gradebook.assignments) || _.isArray(gradebook.custom_columns)) && _.isArray(gradebook.students)) {
        if (gradebook.custom_columns && gradebook.custom_columns.length > 0) {
          this.uploadCustomColumnData(gradebook);
        }

        const createAssignmentsResponses = this.createAssignments(gradebook);
        return $.when(...createAssignmentsResponses).then((...responses) => {
          this.uploadGradeData(gradebook, responses);
        });
      }
      return undefined;
    },

    uploadCustomColumnData (gradebook) {
      const customColumnData = gradebook.students.reduce((accumulator, student) => {
        const student_id = Number.parseInt(student.id, 10);
        if (!(student_id in accumulator)) {
          accumulator[student_id] = student.custom_column_data // eslint-disable-line no-param-reassign
        }
        return accumulator;
      }, {});

      if (!_.isEmpty(customColumnData)) {
        this.parseCustomColumnData(customColumnData);
      }

      if (!gradebook.assignments.length) {
        alert(successMessage); // eslint-disable-line no-alert
        this.goToGradebook();
      }
    },

    parseCustomColumnData (customColumnData) {
      const data = [];
      Object.keys(customColumnData).forEach(studentId => {
        customColumnData[studentId].forEach((column) => {
          data.push({
            column_id: Number.parseInt(column.column_id, 10),
            user_id: studentId,
            content: column.new_content
          })
        });
      })

      this.submitCustomColumnData(data);
      return data;
    },

    submitCustomColumnData (data) {
      return $.ajaxJSON(ENV.bulk_update_custom_columns_path,
        'PUT',
        JSON.stringify({column_data: data}),
        null,
        null,
        {contentType: 'application/json'});
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
        },
        calculate_grades: false
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

export default ProcessGradebookUpload
