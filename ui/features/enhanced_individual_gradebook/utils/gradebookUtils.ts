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

import {uniq, sortBy} from 'lodash'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import type {
  AssignmentGroupCriteriaMap,
  CamelizedGradingPeriodSet,
  SubmissionGradeCriteria,
} from '@canvas/grading/grading.d'
import {useScope as createI18nScope} from '@canvas/i18n'
import round from '@canvas/round'
import * as tz from '@instructure/moment-utils'
import userSettings from '@canvas/user-settings'

import {ApiCallStatus, GradebookSortOrder} from '../types'
import type {
  AssignmentConnection,
  AssignmentDetailCalculationText,
  AssignmentGradingPeriodMap,
  AssignmentGroupConnection,
  AssignmentSortContext,
  AssignmentSubmissionsMap,
  EnrollmentConnection,
  GradebookOptions,
  GradebookStudentDetails,
  GradebookUserSubmissionDetails,
  SortableAssignment,
  SortableStudent,
  SubmissionConnection,
  SubmissionGradeChange,
} from '../types'
import type {GradingPeriodSet, Submission, WorkflowState} from '../../../api.d'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import {scopeToUser, updateWithSubmissions} from '@canvas/grading/EffectiveDueDates'
import {scoreToGrade, type GradingStandard} from '@instructure/grading-utils'
import {divide, toNumber} from '@canvas/grading/GradeCalculationHelper'
import {REPLY_TO_ENTRY, REPLY_TO_TOPIC} from '../react/components/GradingResults'

const I18n = createI18nScope('enhanced_individual_gradebook')

export function mapAssignmentGroupQueryResults(
  assignmentGroup: AssignmentGroupConnection[],
  assignmentGradingPeriodMap: AssignmentGradingPeriodMap,
): {
  mappedAssignments: SortableAssignment[]
  mappedAssignmentGroupMap: AssignmentGroupCriteriaMap
} {
  return assignmentGroup.reduce(
    (prev, curr) => {
      const assignments = curr.assignmentsConnection.nodes
      const mappedAssignments: SortableAssignment[] = assignments.map(assignment =>
        mapToSortableAssignment(
          assignment,
          curr.position,
          assignmentGradingPeriodMap[assignment.id],
        ),
      )
      prev.mappedAssignments.push(...mappedAssignments)

      const assignmentGroupGradingPeriods: string[] = []

      let totalGroupPoints = 0
      prev.mappedAssignmentGroupMap[curr.id] = {
        name: curr.name,
        assignments: curr.assignmentsConnection.nodes.map(assignment => {
          totalGroupPoints += assignment.pointsPossible
          const currentAssignmentGradingPeriod = assignmentGradingPeriodMap[assignment.id]
          if (currentAssignmentGradingPeriod) {
            assignmentGroupGradingPeriods.push(currentAssignmentGradingPeriod)
          }
          return {
            id: assignment.id,
            name: assignment.name,
            points_possible: assignment.pointsPossible,
            submission_types: assignment.submissionTypes,
            anonymize_students: assignment.anonymizeStudents,
            omit_from_final_grade: assignment.omitFromFinalGrade,
            workflow_state: assignment.workflowState,
          }
        }),
        group_weight: curr.groupWeight,
        rules: {
          drop_lowest: curr.rules.dropLowest,
          drop_highest: curr.rules.dropHighest,
          never_drop: curr.rules.neverDrop,
        },
        id: curr.id,
        position: curr.position,
        integration_data: {},
        sis_source_id: curr.sisId,
        invalid: totalGroupPoints === 0,
        gradingPeriodsIds: uniq(assignmentGroupGradingPeriods),
      }

      return prev
    },
    {
      mappedAssignments: [] as SortableAssignment[],
      mappedAssignmentGroupMap: {} as AssignmentGroupCriteriaMap,
    },
  )
}

export function mapAssignmentSubmissions(submissions: SubmissionConnection[]): {
  assignmentSubmissionsMap: AssignmentSubmissionsMap
  assignmentGradingPeriodMap: AssignmentGradingPeriodMap
} {
  const assignmentGradingPeriodMap: AssignmentGradingPeriodMap = {}
  const assignmentSubmissionsMap = submissions.reduce((submissionMap, submission) => {
    const {assignmentId, id: submissionId} = submission
    if (!submissionMap[assignmentId]) {
      submissionMap[assignmentId] = {}
      assignmentGradingPeriodMap[assignmentId] = submission.gradingPeriodId
    }

    submissionMap[assignmentId][submissionId] = submission
    return submissionMap
  }, {} as AssignmentSubmissionsMap)
  return {assignmentGradingPeriodMap, assignmentSubmissionsMap}
}

export function mapEnrollmentsToSortableStudents(
  enrollments: EnrollmentConnection[],
): SortableStudent[] {
  const mappedEnrollments = enrollments.reduce(
    (prev, enrollment) => {
      const {user, courseSectionId, state} = enrollment
      if (!prev[user.id]) {
        prev[user.id] = {
          ...user,
          sections: [courseSectionId],
          state,
        }
      } else {
        prev[user.id].sections.push(courseSectionId)
      }

      return prev
    },
    {} as {[key: string]: SortableStudent},
  )

  return Object.values(mappedEnrollments)
}

export function studentDisplayName(
  student: SortableStudent | GradebookStudentDetails,
  hideStudentNames: boolean,
): string {
  return hideStudentNames ? (student.hiddenName ?? I18n.t('Student')) : student.sortableName
}

export function sortAssignments(
  assignments: SortableAssignment[],
  sortOrder: GradebookSortOrder,
): SortableAssignment[] {
  switch (sortOrder) {
    case GradebookSortOrder.Alphabetical:
      return sortBy(assignments, 'sortableName')
    case GradebookSortOrder.DueDate:
      return sortBy(assignments, ['sortableDueDate', 'sortableName'])
    case GradebookSortOrder.AssignmentGroup:
      return sortBy(assignments, ['assignmentGroupPosition', 'sortableName'])
    default:
      return assignments
  }
}

export function filterAssignmentsByStudent(
  assignments: SortableAssignment[],
  submissions: GradebookUserSubmissionDetails[],
) {
  const assignmentIdMap = submissions.reduce(
    (prev, curr) => {
      prev[curr.assignmentId] = true
      return prev
    },
    {} as {[key: string]: boolean},
  )
  return assignments.filter(assignment => assignmentIdMap[assignment.id])
}

// This logic was taken directly from ui/features/screenreader_gradebook/jquery/AssignmentDetailsDialog.js
export function computeAssignmentDetailText(
  assignment: AssignmentConnection,
  scores: number[],
): AssignmentDetailCalculationText {
  return {
    max: nonNumericGuard(Math.max(...scores)),
    min: nonNumericGuard(Math.min(...scores)),
    pointsPossible: nonNumericGuard(assignment.pointsPossible, 'N/A'),
    average: nonNumericGuard(round(scores.reduce((a, b) => a + b, 0) / scores.length, 2)),
    median: nonNumericGuard(percentile(scores, 0.5)),
    lowerQuartile: nonNumericGuard(percentile(scores, 0.25)),
    upperQuartile: nonNumericGuard(percentile(scores, 0.75)),
  }
}

export function mapUnderscoreSubmission(submission: Submission): GradebookUserSubmissionDetails {
  const parentSubmission = submission

  // @ts-expect-error
  return {
    assignmentId: submission.assignment_id,
    enteredScore: submission.entered_score,
    excused: submission.excused,
    grade: submission.grade,
    id: submission.id,
    late: submission.late,
    missing: submission.missing,
    redoRequest: submission.redo_request,
    score: submission.score,
    submittedAt: submission.submitted_at,
    userId: submission.user_id,
    submissionType: submission.submission_type,
    state: submission.workflow_state,
    cachedDueDate: submission.cached_due_date,
    deductedPoints: submission.points_deducted,
    enteredGrade: submission.entered_grade,
    gradeMatchesCurrentSubmission: submission.grade_matches_current_submission,
    subAssignmentSubmissions: submission.sub_assignment_submissions
      ? submission.sub_assignment_submissions.map(subAssignmentSubmission => ({
          assignmentId: parentSubmission.assignment_id, // This is in purpose, we don't leak the sub assignment id.
          grade: subAssignmentSubmission.grade,
          gradeMatchesCurrentSubmission: subAssignmentSubmission.grade_matches_current_submission,
          score: subAssignmentSubmission.score,
          subAssignmentTag: subAssignmentSubmission.sub_assignment_tag,
          publishedGrade: subAssignmentSubmission.published_grade,
          publishedScore: subAssignmentSubmission.published_score,
          enteredGrade: subAssignmentSubmission.entered_grade,
          enteredScore: subAssignmentSubmission.entered_score,
          excused: subAssignmentSubmission.excused,
        }))
      : undefined,
  }
}

export function mapToSubmissionGradeChange(submission: Submission): SubmissionGradeChange {
  return {
    assignmentId: submission.assignment_id,
    enteredScore: submission.entered_score,
    excused: submission.excused,
    grade: submission.grade,
    id: submission.id,
    late: submission.late,
    missing: submission.missing,
    score: submission.score,
    submittedAt: submission.submitted_at,
    state: submission.workflow_state,
    userId: submission.user_id,
  }
}

export function gradebookOptionsSetup(env: GlobalEnv) {
  const defaultAssignmentSort: GradebookSortOrder =
    userSettings.contextGet<AssignmentSortContext>('sort_grade_columns_by')?.sortType ??
    GradebookSortOrder.Alphabetical

  const defaultGradebookOptions: GradebookOptions = {
    activeGradingPeriods: env.GRADEBOOK_OPTIONS?.active_grading_periods,
    assignmentEnhancementsEnabled: env.GRADEBOOK_OPTIONS?.assignment_enhancements_enabled,
    changeGradeUrl: env.GRADEBOOK_OPTIONS?.change_grade_url,
    contextId: env.GRADEBOOK_OPTIONS?.context_id,
    contextUrl: env.GRADEBOOK_OPTIONS?.context_url,
    customColumnDatumUrl: env.GRADEBOOK_OPTIONS?.custom_column_datum_url,
    customColumnDataUrl: env.GRADEBOOK_OPTIONS?.custom_column_data_url,
    customColumnUrl: env.GRADEBOOK_OPTIONS?.custom_column_url,
    customColumnsUrl: env.GRADEBOOK_OPTIONS?.custom_columns_url,
    customOptions: {
      allowFinalGradeOverride:
        env.GRADEBOOK_OPTIONS?.course_settings.allow_final_grade_override ?? false,
      includeUngradedAssignments:
        env.GRADEBOOK_OPTIONS?.save_view_ungraded_as_zero_to_server &&
        env.GRADEBOOK_OPTIONS?.settings
          ? env.GRADEBOOK_OPTIONS.settings.view_ungraded_as_zero === 'true'
          : userSettings.contextGet('include_ungraded_assignments') || false,
      hideStudentNames: userSettings.contextGet('hide_student_names') || false,
      showConcludedEnrollments: env.GRADEBOOK_OPTIONS?.settings?.show_concluded_enrollments
        ? env.GRADEBOOK_OPTIONS.settings.show_concluded_enrollments === 'true'
        : false,
      showNotesColumn:
        env.GRADEBOOK_OPTIONS?.teacher_notes?.hidden !== undefined
          ? !env.GRADEBOOK_OPTIONS.teacher_notes.hidden
          : false,
      showTotalGradeAsPoints: env.GRADEBOOK_OPTIONS?.show_total_grade_as_points ?? false,
    },
    downloadAssignmentSubmissionsUrl: env.GRADEBOOK_OPTIONS?.download_assignment_submissions_url,
    exportGradebookCsvUrl: env.GRADEBOOK_OPTIONS?.export_gradebook_csv_url,
    finalGradeOverrideEnabled: env.GRADEBOOK_OPTIONS?.final_grade_override_enabled,
    gradeCalcIgnoreUnpostedAnonymousEnabled:
      env.GRADEBOOK_OPTIONS?.grade_calc_ignore_unposted_anonymous_enabled,
    gradebookCsvProgress: env.GRADEBOOK_OPTIONS?.gradebook_csv_progress,
    gradesAreWeighted: env.GRADEBOOK_OPTIONS?.grades_are_weighted,
    gradingPeriodSet: env.GRADEBOOK_OPTIONS?.grading_period_set,
    gradingSchemes: env.GRADEBOOK_OPTIONS?.grading_schemes,
    gradingStandard: env.GRADEBOOK_OPTIONS?.grading_standard,
    gradingStandardPointsBased: env.GRADEBOOK_OPTIONS?.grading_standard_points_based || false,
    gradingStandardScalingFactor: env.GRADEBOOK_OPTIONS?.grading_standard_scaling_factor || 1.0,
    groupWeightingScheme: env.GRADEBOOK_OPTIONS?.group_weighting_scheme,
    lastGeneratedCsvAttachmentUrl: env.GRADEBOOK_OPTIONS?.attachment_url,
    messageAttachmentUploadFolderId: env.GRADEBOOK_OPTIONS?.message_attachment_upload_folder_id,
    proxySubmissionEnabled: !!env.GRADEBOOK_OPTIONS?.proxy_submissions_allowed,
    publishToSisEnabled: env.GRADEBOOK_OPTIONS?.publish_to_sis_enabled,
    publishToSisUrl: env.GRADEBOOK_OPTIONS?.publish_to_sis_url,
    reorderCustomColumnsUrl: env.GRADEBOOK_OPTIONS?.reorder_custom_columns_url,
    saveViewUngradedAsZeroToServer: env.GRADEBOOK_OPTIONS?.save_view_ungraded_as_zero_to_server,
    selectedGradingPeriodId: userSettings.contextGet<string>('gradebook_current_grading_period'),
    settingsUpdateUrl: env.GRADEBOOK_OPTIONS?.settings_update_url,
    settingUpdateUrl: env.GRADEBOOK_OPTIONS?.setting_update_url,
    stickersEnabled: env.GRADEBOOK_OPTIONS?.stickers_enabled,
    sortOrder: defaultAssignmentSort,
    teacherNotes: env.GRADEBOOK_OPTIONS?.teacher_notes,
    userId: env.current_user_id,
  }

  return defaultGradebookOptions
}

export function mapToCamelizedGradingPeriodSet(
  gradingPeriodSet?: GradingPeriodSet | null,
): CamelizedGradingPeriodSet | null {
  if (!gradingPeriodSet) {
    return null
  }

  return {
    createdAt: new Date(gradingPeriodSet.created_at),
    displayTotalsForAllGradingPeriods: gradingPeriodSet.display_totals_for_all_grading_periods,
    enrollmentTermIDs: gradingPeriodSet.enrollment_term_ids,
    gradingPeriods: gradingPeriodSet.grading_periods.map(gradingPeriod => ({
      closeDate: new Date(gradingPeriod.close_date),
      endDate: new Date(gradingPeriod.end_date),
      id: gradingPeriod.id,
      startDate: new Date(gradingPeriod.start_date),
      isClosed: gradingPeriod.is_closed,
      title: gradingPeriod.title,
      isLast: gradingPeriod.is_last,
      weight: gradingPeriod.weight ?? 0,
    })),
    id: gradingPeriodSet.id,
    permissions: gradingPeriodSet.permissions,
    title: gradingPeriodSet.title,
    weighted: gradingPeriodSet.weighted,
  }
}

export function scoreToPercentage(score?: number, possible?: number, decimalPlaces = 2) {
  const percent = (Number(score) / Number(possible)) * 100.0
  return percent % 1 === 0 ? percent : percent.toFixed(decimalPlaces)
}

export function scoreToScaledPoints(score: number, pointsPossible: number, scalingFactor: number) {
  const scoreAsScaledPoints = score / (pointsPossible / scalingFactor)
  if (!Number.isFinite(scoreAsScaledPoints)) {
    return scoreAsScaledPoints
  }
  // @ts-expect-error
  return toNumber(divide(score, divide(pointsPossible, scalingFactor)))
}

export function getLetterGrade(
  possible?: number,
  score?: number,
  gradingStandards?: GradingStandard[] | null,
  pointsBased?: boolean,
  gradingStandardScalingFactor?: number,
) {
  if (!gradingStandards || !gradingStandards.length || !possible || !score) {
    return '-'
  }
  const rawPercentage = scoreToPercentage(score, possible)
  const percentage = parseFloat(Number(rawPercentage).toPrecision(4))
  return scoreToGrade(percentage, gradingStandards, pointsBased, gradingStandardScalingFactor)
}

type CalculateGradesForUserProps = {
  assignmentGroupMap: AssignmentGroupCriteriaMap
  gradeCalcIgnoreUnpostedAnonymousEnabled?: boolean | null
  gradingPeriodSet?: GradingPeriodSet | null
  groupWeightingScheme?: string | null
  studentId?: string
  submissions?: GradebookUserSubmissionDetails[]
}
export function calculateGradesForStudent({
  assignmentGroupMap,
  gradeCalcIgnoreUnpostedAnonymousEnabled,
  gradingPeriodSet,
  groupWeightingScheme,
  studentId,
  submissions,
}: CalculateGradesForUserProps) {
  if (!submissions || !studentId) {
    return
  }

  const camelizedGradingPeriodSet = mapToCamelizedGradingPeriodSet(gradingPeriodSet)

  const gradeCriteriaSubmissions: SubmissionGradeCriteria[] = submissions.map(submission => {
    return {
      assignment_id: submission.assignmentId,
      excused: submission.excused,
      grade: submission.grade,
      score: submission.score,
      workflow_state: submission.state as WorkflowState,
      id: submission.id,
    }
  })

  const effectiveDueDates = updateWithSubmissions(
    {},
    submissions.map(submission => ({
      assignment_id: submission.assignmentId,
      cached_due_date: submission.cachedDueDate,
      user_id: submission.userId,
    })),
    camelizedGradingPeriodSet?.gradingPeriods,
  )

  const hasGradingPeriods = gradingPeriodSet && effectiveDueDates

  return CourseGradeCalculator.calculate(
    gradeCriteriaSubmissions,
    assignmentGroupMap,
    groupWeightingScheme ?? 'points',
    gradeCalcIgnoreUnpostedAnonymousEnabled ?? false,
    hasGradingPeriods ? camelizedGradingPeriodSet : undefined,
    hasGradingPeriods ? scopeToUser(effectiveDueDates, studentId) : undefined,
  )
}

export function showInvalidGroupWarning(
  invalidAssignmentGroupsCount: number,
  groupWeightingScheme?: string | null,
) {
  return invalidAssignmentGroupsCount > 0 && groupWeightingScheme === 'percent'
}

function nonNumericGuard(value: number, message = 'No graded submissions'): string {
  return Number.isFinite(value) && !Number.isNaN(value) ? value.toString() : message
}

function percentile(values: number[], percentileValue: number): number {
  const k = Math.floor(percentileValue * (values.length - 1) + 1) - 1
  const f = (percentileValue * (values.length - 1) + 1) % 1

  return values[k] + f * (values[k + 1] - values[k])
}

function mapToSortableAssignment(
  assignment: AssignmentConnection,
  assignmentGroupPosition: number,
  gradingPeriodId?: string | null,
): SortableAssignment {
  // Used sort date logic from screenreader_gradebook_controller.js
  // @ts-expect-error
  const sortableDueDate = assignment.dueAt ? +tz.parse(assignment.dueAt) / 1000 : Number.MAX_VALUE
  return {
    ...assignment,
    sortableName: assignment.name.toLowerCase(),
    sortableDueDate,
    assignmentGroupPosition,
    gradingPeriodId,
  }
}

export function isInPastGradingPeriodAndNotAdmin(assignment: AssignmentConnection): boolean {
  return (assignment.inClosedGradingPeriod ?? false) && !ENV.current_user_is_admin
}
