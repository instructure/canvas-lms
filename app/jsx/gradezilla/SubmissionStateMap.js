/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import GradingPeriodsHelper from '../grading/helpers/GradingPeriodsHelper';

function submissionGradingPeriodInformation (assignment, student) {
  const submissionInfo = assignment.effectiveDueDates[student.id] || {};
  return {
    gradingPeriodID: submissionInfo.grading_period_id,
    inClosedGradingPeriod: submissionInfo.in_closed_grading_period
  };
}

function hiddenFromStudent (assignment, student) {
  if (assignment.only_visible_to_overrides) {
    return !_.contains(assignment.assignment_visibility, student.id);
  }
  return false
}

function gradingPeriodInfoForCell (assignment, student, selectedGradingPeriodID) {
  const specificPeriodSelected = !GradingPeriodsHelper.isAllGradingPeriods(selectedGradingPeriodID);
  const { gradingPeriodID, inClosedGradingPeriod } = submissionGradingPeriodInformation(assignment, student);
  const inNoGradingPeriod = !gradingPeriodID;
  const inOtherGradingPeriod = !!gradingPeriodID && specificPeriodSelected &&
    selectedGradingPeriodID !== gradingPeriodID;

  return {
    inNoGradingPeriod,
    inOtherGradingPeriod,
    inClosedGradingPeriod
  };
}

function cellMappingsForMultipleGradingPeriods (assignment, student, selectedGradingPeriodID, isAdmin) {
  const specificPeriodSelected = !GradingPeriodsHelper.isAllGradingPeriods(selectedGradingPeriodID);
  const { gradingPeriodID, inClosedGradingPeriod } = submissionGradingPeriodInformation(assignment, student);
  const gradingPeriodInfo = gradingPeriodInfoForCell(assignment, student, selectedGradingPeriodID);
  let cellMapping;

  if (specificPeriodSelected && (!gradingPeriodID || selectedGradingPeriodID !== gradingPeriodID)) {
    cellMapping = { locked: true, hideGrade: true };
  } else if (!isAdmin && inClosedGradingPeriod) {
    cellMapping = { locked: true, hideGrade: false };
  } else {
    cellMapping = { locked: false, hideGrade: false };
  }

  return { ...cellMapping, ...gradingPeriodInfo };
}

function cellMapForSubmission (assignment, student, hasGradingPeriods, selectedGradingPeriodID, isAdmin) {
  if (!assignment.published || assignment.anonymize_students) {
    return { locked: true, hideGrade: true };
  } else if (assignment.moderated_grading && !assignment.grades_published) {
    return { locked: true, hideGrade: false };
  } else if (hiddenFromStudent(assignment, student)) {
    return { locked: true, hideGrade: true };
  } else if (hasGradingPeriods) {
    return cellMappingsForMultipleGradingPeriods(assignment, student, selectedGradingPeriodID, isAdmin);
  } else {
    return { locked: false, hideGrade: false };
  }
}

function missingSubmission (student, assignment) {
  const submission = {
    assignment_id: assignment.id,
    user_id: student.id,
    excused: false,
    late: false,
    missing: false,
    seconds_late: 0
  };
  const dueDates = assignment.effectiveDueDates[student.id] || {};
  if (dueDates.due_at != null && new Date(dueDates.due_at) < new Date()) {
    submission.missing = true;
  }
  return submission;
}

class SubmissionStateMap {
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

  setSubmissionCellState (student, assignment, submission) {
    this.submissionMap[student.id][assignment.id] = submission || missingSubmission(student, assignment);
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

export default SubmissionStateMap;
