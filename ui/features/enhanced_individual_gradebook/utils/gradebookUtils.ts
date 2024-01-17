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
import {useScope as useI18nScope} from '@canvas/i18n'
import round from '@canvas/round'
import * as tz from '@canvas/datetime'
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
import DateHelper from '@canvas/datetime/dateHelper'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import {scopeToUser, updateWithSubmissions} from '@canvas/grading/EffectiveDueDates'
import {scoreToGrade, type GradingStandard} from '@instructure/grading-utils'
import {divide, toNumber} from '@canvas/grading/GradeCalculationHelper'

const I18n = useI18nScope('enhanced_individual_gradebook')

export const passFailStatusOptions = [
  {
    label: I18n.t('Ungraded'),
    value: ' ',
  },
  {
    label: I18n.t('Complete'),
    value: 'complete',
  },
  {
    label: I18n.t('Incomplete'),
    value: 'incomplete',
  },
  {
    label: I18n.t('Excused'),
    value: 'EX',
  },
]

export function mapAssignmentGroupQueryResults(
  assignmentGroup: AssignmentGroupConnection[],
  assignmentGradingPeriodMap: AssignmentGradingPeriodMap
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
          assignmentGradingPeriodMap[assignment.id]
        )
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
    }
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
  enrollments: EnrollmentConnection[]
): SortableStudent[] {
  const mappedEnrollments = enrollments.reduce((prev, enrollment) => {
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
  }, {} as {[key: string]: SortableStudent})

  return Object.values(mappedEnrollments)
}

export function studentDisplayName(
  student: SortableStudent | GradebookStudentDetails,
  hideStudentNames: boolean
): string {
  return hideStudentNames ? student.hiddenName ?? I18n.t('Student') : student.sortableName
}

export function sortAssignments(
  assignments: SortableAssignment[],
  sortOrder: GradebookSortOrder
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
  submissions: GradebookUserSubmissionDetails[]
) {
  const assignmentIdMap = submissions.reduce((prev, curr) => {
    prev[curr.assignmentId] = true
    return prev
  }, {} as {[key: string]: boolean})
  return assignments.filter(assignment => assignmentIdMap[assignment.id])
}

// This logic was taken directly from ui/features/screenreader_gradebook/jquery/AssignmentDetailsDialog.js
export function computeAssignmentDetailText(
  assignment: AssignmentConnection,
  scores: number[]
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
  }
}

export function submitterPreviewText(submission: GradebookUserSubmissionDetails): string {
  if (!submission.submissionType) {
    return I18n.t('Has not submitted')
  }
  const formattedDate = DateHelper.formatDatetimeForDisplay(submission.submittedAt)
  if (submission.proxySubmitter) {
    return I18n.t('Submitted by %{proxy} on %{date}', {
      proxy: submission.proxySubmitter,
      date: formattedDate,
    })
  }
  return I18n.t('Submitted on %{date}', {date: formattedDate})
}

export function outOfText(
  assignment: AssignmentConnection,
  submission: GradebookUserSubmissionDetails
): string {
  const {gradingType, pointsPossible} = assignment

  if (submission.excused) {
    return I18n.t('Excused')
  } else if (gradingType === 'gpa_scale') {
    return ''
  } else if (gradingType === 'letter_grade' || gradingType === 'pass_fail') {
    return I18n.t('(%{score} out of %{points})', {
      points: I18n.n(pointsPossible),
      score: submission.enteredScore ?? ' -',
    })
  } else if (pointsPossible === null || pointsPossible === undefined) {
    return I18n.t('No points possible')
  } else {
    return I18n.t('(out of %{points})', {points: I18n.n(pointsPossible)})
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
    sortOrder: defaultAssignmentSort,
    teacherNotes: env.GRADEBOOK_OPTIONS?.teacher_notes,
    userId: env.current_user_id,
  }

  return defaultGradebookOptions
}

export function mapToCamelizedGradingPeriodSet(
  gradingPeriodSet?: GradingPeriodSet | null
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
  return toNumber(divide(score, divide(pointsPossible, scalingFactor)))
}

export function getLetterGrade(
  possible?: number,
  score?: number,
  gradingStadards?: GradingStandard[] | null
) {
  if (!gradingStadards || !gradingStadards.length || !possible || !score) {
    return '-'
  }
  const rawPercentage = scoreToPercentage(score, possible)
  const percentage = parseFloat(Number(rawPercentage).toPrecision(4))
  return scoreToGrade(percentage, gradingStadards)
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
    camelizedGradingPeriodSet?.gradingPeriods
  )

  const hasGradingPeriods = gradingPeriodSet && effectiveDueDates

  return CourseGradeCalculator.calculate(
    gradeCriteriaSubmissions,
    assignmentGroupMap,
    groupWeightingScheme ?? 'points',
    gradeCalcIgnoreUnpostedAnonymousEnabled ?? false,
    hasGradingPeriods ? camelizedGradingPeriodSet : undefined,
    hasGradingPeriods ? scopeToUser(effectiveDueDates, studentId) : undefined
  )
}

export function showInvalidGroupWarning(
  invalidAssignmentGroupsCount: number,
  groupWeightingScheme?: string | null
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
  gradingPeriodId?: string | null
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

export function disableGrading(
  assignment: AssignmentConnection,
  submitScoreStatus?: ApiCallStatus
): boolean {
  return (
    submitScoreStatus === ApiCallStatus.PENDING ||
    isInPastGradingPeriodAndNotAdmin(assignment) ||
    (assignment.moderatedGrading && !assignment.gradesPublished)
  )
}
