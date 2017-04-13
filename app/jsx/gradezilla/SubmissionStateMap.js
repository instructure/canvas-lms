/*
 * Copyright (C) 2016 - 2017 Instructure, Inc.
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

import _ from 'underscore';
import GradingPeriodsHelper from 'jsx/grading/helpers/GradingPeriodsHelper';

const TOOLTIP_KEYS = {
  UNPUBLISHED_ASSIGNMENT: 'unpublished_assignment',
  NOT_IN_ANY_GP: 'not_in_any_grading_period',
  IN_ANOTHER_GP: 'in_another_grading_period',
  IN_CLOSED_GP: 'in_closed_grading_period',
  NONE: null
};

function submissionGradingPeriodInformation (assignment, student) {
  const submissionInfo = assignment.effectiveDueDates[student.id] || {};
  return {
    gradingPeriodID: submissionInfo.grading_period_id,
    inClosedGradingPeriod: submissionInfo.in_closed_grading_period
  };
}

function visibleToStudent (assignment, student) {
  if (!assignment.only_visible_to_overrides) return true;
  return _.contains(assignment.assignment_visibility, student.id);
}

function cellMappingsForMultipleGradingPeriods (assignment, student, selectedGradingPeriodID, isAdmin) {
  const specificPeriodSelected = !GradingPeriodsHelper.isAllGradingPeriods(selectedGradingPeriodID);
  const { gradingPeriodID, inClosedGradingPeriod } = submissionGradingPeriodInformation(assignment, student);

  if (specificPeriodSelected && !gradingPeriodID) {
    return { locked: true, hideGrade: true, tooltip: TOOLTIP_KEYS.NOT_IN_ANY_GP };
  } else if (specificPeriodSelected && selectedGradingPeriodID !== gradingPeriodID) {
    return { locked: true, hideGrade: true, tooltip: TOOLTIP_KEYS.IN_ANOTHER_GP };
  } else if (!isAdmin && inClosedGradingPeriod) {
    return { locked: true, hideGrade: false, tooltip: TOOLTIP_KEYS.IN_CLOSED_GP };
  } else {
    return { locked: false, hideGrade: false, tooltip: TOOLTIP_KEYS.NONE };
  }
}


function cellMapForSubmission (assignment, student, hasGradingPeriods, selectedGradingPeriodID, isAdmin) {
  if (!assignment.published) {
    return { locked: true, hideGrade: true, tooltip: TOOLTIP_KEYS.UNPUBLISHED_ASSIGNMENT };
  } else if (!visibleToStudent(assignment, student)) {
    return { locked: true, hideGrade: true, tooltip: TOOLTIP_KEYS.NONE };
  } else if (hasGradingPeriods) {
    return cellMappingsForMultipleGradingPeriods(assignment, student, selectedGradingPeriodID, isAdmin);
  } else {
    return { locked: false, hideGrade: false, tooltip: TOOLTIP_KEYS.NONE };
  }
}

class SubmissionState {
  constructor ({ hasGradingPeriods, selectedGradingPeriodID, isAdmin }) {
    this.hasGradingPeriods = hasGradingPeriods;
    this.selectedGradingPeriodID = selectedGradingPeriodID;
    this.isAdmin = isAdmin;
    this.submissionCellMap = {};
    this.submissionMap = {};
  }

  setup (students, assignments) {
    students.forEach((student) => {
      this.submissionCellMap[student.id] = {};
      this.submissionMap[student.id] = {};
      _.each(assignments, (assignment) => {
        this.setSubmissionCellState(student, assignment, student[`assignment_${assignment.id}`]);
      });
    });
  }

  setSubmissionCellState (student, assignment, submission = { assignment_id: assignment.id, user_id: student.id }) {
    this.submissionMap[student.id][assignment.id] = submission;
    const params = [
      assignment,
      student,
      this.hasGradingPeriods,
      this.selectedGradingPeriodID,
      this.isAdmin
    ];

    this.submissionCellMap[student.id][assignment.id] = cellMapForSubmission(...params);
  }

  getSubmission (userId, assignmentId) {
    return (this.submissionMap[userId] || {})[assignmentId];
  }

  getSubmissionState ({ user_id: userId, assignment_id: assignmentId }) {
    return (this.submissionCellMap[userId] || {})[assignmentId];
  }
}

export default SubmissionState;
