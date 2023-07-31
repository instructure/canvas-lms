/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import AssignmentGroupGradeCalculator from '@canvas/grading/AssignmentGroupGradeCalculator'

export const convertSubmissionToDroppableSubmission = (assignment, submission) => {
  return {
    score: submission?.score || 0,
    grade: submission?.grade || 0,
    total: assignment?.pointsPossible,
    assignment_id: assignment?._id,
    workflow_state: assignment?.state,
    excused: submission?.late || false,
    id: submission?._id || null,
    submission: {assignment_id: assignment?._id},
  }
}

export const camelCaseToSnakeCase = str => {
  return str.replace(/([A-Z])/g, (_match, letter) => `_${letter.toLowerCase()}`).replace(/^_/, '')
}

export const convertAssignmentGroupRules = assignmentGroup => {
  if (
    !assignmentGroup?.rules ||
    (assignmentGroup?.rules?.dropLowest === null &&
      assignmentGroup?.rules?.dropHighest === null &&
      assignmentGroup?.rules?.neverDrop === null)
  )
    return {}
  const rules = {}
  Object.keys(assignmentGroup?.rules).forEach(key => {
    rules[camelCaseToSnakeCase(key)] = assignmentGroup.rules[key]
  })

  if (rules.never_drop !== null) {
    rules.never_drop = rules.never_drop.map(assignment => assignment._id)
  }
  return rules
}

export const convertToSubmissionCriteria = (submission, assignmentId, state) => {
  return {
    score: submission?.score || 0,
    grade: submission?.grade || 0,
    assignment_id: assignmentId,
    workflow_state: state,
    excused: submission?.excused || false,
    id: submission?._id || 'unsubmitted',
  }
}

export const convertAssignment = assignment => {
  return {
    id: assignment._id,
    allowed_attempts: assignment.allowedAttempts,
    created_at: assignment.createdAt,
    html_url: assignment.htmlUrl,
    grade_group_students_individually: assignment.gradeGroupStudentsIndividually,
    grades_published: assignment.gradesPublished,
    grading_type: assignment.gradingType,
    group_category_id: assignment.groupCategoryId,
    has_submitted_submissions: assignment.hasSubmittedSubmissions,
    lock_at: assignment.lockAt,
    name: assignment.name,
    omit_from_final_grade: assignment.omitFromFinalGrade,
    points_possible: assignment.pointsPossible,
    position: assignment.position,
    published: assignment.published,
    state: assignment.state,
    unlock_at: assignment.unlockAt,
    updated_at: assignment.updatedAt,
  }
}

export const convertAssignmentGroup = assignmentGroup => {
  return {
    group_weight: assignmentGroup.groupWeight,
    id: assignmentGroup._id,
    integration_data: null,
    name: assignmentGroup.name,
    position: assignmentGroup.position,
    rules: convertAssignmentGroupRules(assignmentGroup),
    sis_source_id: assignmentGroup.sis_source_id,
  }
}

export const calculateAssignmentGroupGrade = (
  assignments,
  assignmentGroup,
  ignoreUnpostedAnonymous
) => {
  const convertedSubmissions = assignments.map(assignment => {
    return convertToSubmissionCriteria(
      assignment.submissionsConnection.nodes[0],
      assignment._id,
      assignment.state
    )
  })

  const convertedAssignmentGroup = convertAssignmentGroup(assignmentGroup)

  const convertedAssignments = assignments.map(assignment => {
    return convertAssignment(assignment)
  })

  return AssignmentGroupGradeCalculator.calculate(
    convertedSubmissions,
    {...convertedAssignmentGroup, assignments: convertedAssignments},
    ignoreUnpostedAnonymous
  )
}
