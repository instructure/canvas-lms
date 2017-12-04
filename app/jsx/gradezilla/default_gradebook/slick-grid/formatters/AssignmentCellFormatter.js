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

import htmlEscape from 'str/htmlEscape';
import SubmissionCell from 'compiled/gradezilla/SubmissionCell';
import { extractDataTurnitin } from 'compiled/gradezilla/Turnitin';
import GradeFormatHelper from '../../../../gradebook/shared/helpers/GradeFormatHelper';
import { classNamesForAssignmentCell } from '../../../../gradezilla/default_gradebook/slick-grid/shared/CellStyles';

function getTurnitinState (submission) {
  const turnitin = extractDataTurnitin(submission);
  if (turnitin) {
    return htmlEscape(turnitin.state);
  }
  return null;
}

function needsGrading (submission) {
  if (submission.excused || !submission.submission_type) {
    return false;
  }

  return submission.workflow_state === 'pending_review' || (
    // the submission exists and/or has been graded
    ['submitted', 'graded'].includes(submission.workflow_state) &&
    // the score has been cleared, or the submission has been resubmitted
    (submission.score == null || submission.grade_matches_current_submission === false)
  );
}

function formatGrade (submissionData, assignment, options) {
  const formatOptions = {
    formatType: options.getEnterGradesAsSetting(assignment.id),
    gradingScheme: options.getGradingSchemeData(assignment.id),
    pointsPossible: assignment.points_possible,
    version: 'final'
  };

  return GradeFormatHelper.formatSubmissionGrade(submissionData, formatOptions);
}

function renderTemplate (grade, options = {}) {
  let classNames = ['gradebook-cell'];
  let content = grade;

  if (options.classNames) {
    classNames = [...classNames, ...options.classNames];
  }

  if (options.dimmed) {
    classNames.push('grayed-out');
  }

  if (options.disabled) {
    classNames.push('cannot_edit');
  }

  if (options.turnitinState) {
    classNames.push('turnitin');
    content += `<span class='gradebook-cell-turnitin ${options.turnitinState}-score' />`;
  }

  return `<div class="${htmlEscape(classNames.join(' '))}">${content}</div>`;
}

export default class AssignmentCellFormatter {
  constructor (gradebook) {
    this.options = {
      getAssignment (assignmentId) {
        return gradebook.getAssignment(assignmentId);
      },
      getEnterGradesAsSetting (assignmentId) {
        return gradebook.getEnterGradesAsSetting(assignmentId);
      },
      getGradingSchemeData (assignmentId) {
        return gradebook.getAssignmentGradingScheme(assignmentId).data;
      },
      getStudent (studentId) {
        return gradebook.student(studentId);
      },
      getSubmissionState (submission) {
        return gradebook.submissionStateMap.getSubmissionState(submission);
      },
      getUpdatingSubmission(submission) {
        return gradebook.getUpdatingSubmission(submission)
      }
    };
  }

  render = (row, cell, submission /* value */, _columnDef, student /* dataContext */) => {
    let submissionState;
    if (submission) {
      submissionState = this.options.getSubmissionState(submission);
    }

    if (!student.loaded || !student.initialized || !submissionState) {
      return renderTemplate('');
    }

    if (submissionState.hideGrade) {
      return renderTemplate('', { dimmed: true });
    }

    const assignment = this.options.getAssignment(submission.assignment_id);
    if (assignment.grading_type === 'pass_fail') {
      const options = {
        needsGrading: needsGrading(submission)
      };
      const GradingTypeSubmissionCell = SubmissionCell.pass_fail;
      const gradingTypeFormatter = GradingTypeSubmissionCell.formatter.bind(GradingTypeSubmissionCell);
      return gradingTypeFormatter(row, cell, submission, assignment, student, options);
    }

    const assignmentData = {
      id: assignment.id,
      muted: assignment.muted,
      pointsPossible: assignment.points_possible,
      submissionTypes: assignment.submission_types
    };

    const submissionData = {
      dropped: submission.drop,
      excused: submission.excused,
      grade: submission.grade,
      late: submission.late,
      missing: submission.missing,
      resubmitted: submission.grade_matches_current_submission === false,
      score: submission.score
    };

    const updatingSubmission = this.options.getUpdatingSubmission({
      assignmentId: assignment.id,
      userId: student.id
    })
    if (updatingSubmission) {
      submissionData.excused = updatingSubmission.excused
      submissionData.grade = updatingSubmission.enteredGrade
      submissionData.score = updatingSubmission.enteredScore
    }

    const options = {
      classNames: classNamesForAssignmentCell(assignmentData, submissionData),
      dimmed: student.isInactive || student.isConcluded || submissionState.locked,
      disabled: student.isConcluded || submissionState.locked,
      hidden: submissionState.hideGrade,
      turnitinState: getTurnitinState(submission)
    };

    if (needsGrading(submission)) {
      return renderTemplate('<i class="icon-not-graded"></i>', options);
    }

    const grade = formatGrade(submissionData, assignment, this.options);

    return renderTemplate(grade, options);
  };
}
