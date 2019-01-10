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

// xsslint safeString.method I18n.t

import I18n from 'i18n!gradebook'
import htmlEscape from 'str/htmlEscape';
import { extractDataTurnitin } from 'compiled/gradezilla/Turnitin';
import GradeFormatHelper from '../../../../gradebook/shared/helpers/GradeFormatHelper';
import {classNamesForAssignmentCell} from './CellStyles'

function getTurnitinState (submission) {
  const turnitin = extractDataTurnitin(submission);
  if (turnitin) {
    return htmlEscape(turnitin.state);
  }
  return null;
}

function needsGrading(submission, pendingGradeInfo) {
  if (pendingGradeInfo && pendingGradeInfo.grade != null) {
    return false
  }

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

function renderStartContainer(options) {
  let content = ''
  if (options.invalid) {
    content +=
      '<div class="Grid__AssignmentRowCell__InvalidGrade"><i class="icon-warning"></i></div>'
  }
  // xsslint safeString.identifier content
  return `<div class="Grid__AssignmentRowCell__StartContainer">${content}</div>`
}

function renderTemplate(grade, options = {}) {
  let classNames = ['Grid__AssignmentRowCell', 'gradebook-cell']
  let content = grade

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
    // xsslint safeString.property turnitinState
    content += `<span class="gradebook-cell-turnitin ${options.turnitinState}-score" />`;
  }

  // xsslint safeString.identifier content
  // xsslint safeString.function renderStartContainer
  return `<div class="${htmlEscape(classNames.join(' '))}">
    ${renderStartContainer(options)}
    <div class="Grid__AssignmentRowCell__Content">
      <span class="Grade">${content}</span>
    </div>
    <div class="Grid__AssignmentRowCell__EndContainer"></div>
  </div>`
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
      getPendingGradeInfo(submission) {
        return gradebook.getPendingGradeInfo(submission)
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

    const assignmentData = {
      id: assignment.id,
      muted: assignment.muted,
      pointsPossible: assignment.points_possible,
      submissionTypes: assignment.submission_types
    };

    const submissionData = {
      dropped: submission.drop,
      excused: submission.excused,
      grade: assignment.grading_type === 'pass_fail' ? submission.rawGrade : submission.grade,
      late: submission.late,
      missing: submission.missing,
      resubmitted: submission.grade_matches_current_submission === false,
      score: submission.score
    };

    const pendingGradeInfo = this.options.getPendingGradeInfo({
      assignmentId: assignment.id,
      userId: student.id
    })
    if (pendingGradeInfo) {
      submissionData.grade = pendingGradeInfo.grade
      submissionData.excused = pendingGradeInfo.excused
    }

    const options = {
      classNames: classNamesForAssignmentCell(assignmentData, submissionData),
      dimmed: student.isInactive || student.isConcluded || submissionState.locked,
      disabled: student.isConcluded || submissionState.locked,
      hidden: submissionState.hideGrade,
      invalid: !!pendingGradeInfo && !pendingGradeInfo.valid,
      turnitinState: getTurnitinState(submission)
    };

    if (needsGrading(submission, pendingGradeInfo)) {
      const text = `<span class="screenreader-only">${I18n.t('Needs Grading')}</span>`
      const icon = '<i class="icon-not-graded icon-Line"></i>'
      return renderTemplate(`${text}${icon}`, options)
    }

    if (assignment.grading_type === 'pass_fail') {
      if (submissionData.grade === 'complete') {
        const text = `<span class="screenreader-only">${I18n.t('Complete')}</span>`
        const icon = '<i class="icon-check icon-Solid Grade--complete"></i>'
        return renderTemplate(`${text}${icon}`, options)
      }

      if (submissionData.grade === 'incomplete') {
        const text = `<span class="screenreader-only">${I18n.t('Incomplete')}</span>`
        const icon = '<i class="icon-x icon-Solid Grade--incomplete"></i>'
        return renderTemplate(`${text}${icon}`, options)
      }
    }

    let grade
    if (pendingGradeInfo) {
      grade = GradeFormatHelper.formatGradeInfo(pendingGradeInfo)
    } else {
      grade = formatGrade(submissionData, assignment, this.options)
    }

    return renderTemplate(htmlEscape(grade), options)
  };
}
