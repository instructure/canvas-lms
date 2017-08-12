/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import SubmissionCell from 'compiled/gradezilla/SubmissionCell';

export default class AssignmentCellFormatter {
  constructor (gradebook) {
    this.options = {
      getAssignment (assignmentId) {
        return gradebook.getAssignment(assignmentId);
      },
      getStudent (studentId) {
        return gradebook.student(studentId);
      },
      getSubmissionState (submission) {
        return gradebook.submissionStateMap.getSubmissionState(submission);
      }
    };
  }

  render = (row, cell, submission /* value */, _columnDef, student /* dataContext */) => {
    if (!student.loaded || !student.initialized) {
      return '<div class="cell-content gradebook-cell"></div>';
    }

    const submissionState = this.options.getSubmissionState(submission);
    if (submissionState.hideGrade) {
      return '<div class="cell-content gradebook-cell grayed-out cannot_edit"></div>';
    }

    const assignment = this.options.getAssignment(submission.assignment_id);

    const options = {
      isLocked: submissionState.locked
    };

    const GradingTypeSubmissionCell = (SubmissionCell[assignment.grading_type] || SubmissionCell);
    const gradingTypeFormatter = GradingTypeSubmissionCell.formatter.bind(GradingTypeSubmissionCell);
    return gradingTypeFormatter(row, cell, submission, assignment, student, options);
  };
}
