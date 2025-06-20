/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {keyBy, mapValues} from 'lodash'
import {Submission as ApiSubmission, GradingType, WorkflowState} from 'api.d'
import {SubmissionWithOriginalityReport} from '@canvas/grading/grading'
import {Submission} from './getSubmissions'

const parseDateOrNull = (date: string | null) => (date ? new Date(date) : null)

export const transformSubmission = (it: Submission): ApiSubmission => {
  const turnitinData: Record<
    string,
    NonNullable<SubmissionWithOriginalityReport['turnitin_data']>
  > = mapValues(keyBy(it.turnitinData ?? [], 'assetString'), x => ({
    status: x.status ?? '',
    state: x.state ?? '',
    similarity_score: x.score ?? 0,
    provider: 'turnitin',
  }))
  const vericiteData: Record<
    string,
    NonNullable<SubmissionWithOriginalityReport['vericite_data']>
  > = mapValues(keyBy(it.turnitinData ?? [], 'assetString'), x => ({
    status: x.status ?? '',
    state: x.state ?? '',
    similarity_score: x.score ?? 0,
    provider: 'vericite' as const,
  }))
  return {
    id: it._id,
    anonymous_id: it.anonymousId ?? undefined,
    assignment_id: it.assignment._id ?? '',
    attempt: it.attempt,
    cached_due_date: it.cachedDueDate,
    custom_grade_status_id: it.customGradeStatusId,
    points_deducted: it.deductedPoints,
    entered_grade: it.enteredGrade,
    entered_score: it.enteredScore,
    excused: it.excused ?? false,
    grade: it.grade,
    grading_type: undefined as unknown as GradingType,
    gradingType: undefined as unknown as GradingType,
    grade_matches_current_submission: it.gradeMatchesCurrentSubmission !== false,
    grading_period_id: it.gradingPeriodId ?? '',
    has_postable_comments: it.hasPostableComments,
    late: it.late,
    late_policy_status: it.latePolicyStatus === 'none' ? null : it.latePolicyStatus,
    missing: it.missing,
    posted_at: parseDateOrNull(it.postedAt),
    proxy_submitter: it.proxySubmitter ?? undefined,
    redo_request: it.redoRequest ?? false,
    score: it.score,
    seconds_late: it.secondsLate ?? 0,
    sticker: it.sticker,
    submission_type: it.submissionType as ApiSubmission['submission_type'],
    submitted_at: parseDateOrNull(it.submittedAt),
    updated_at: it.updatedAt ?? '',
    user_id: it.userId ?? '',
    sub_assignment_submissions:
      it.subAssignmentSubmissions?.map(sub => ({
        custom_grade_status_id: sub.customGradeStatusId,
        entered_grade: sub.enteredGrade,
        entered_score: sub.enteredScore,
        excused: sub.excused ?? false,
        grade: sub.grade,
        grade_matches_current_submission: sub.gradeMatchesCurrentSubmission ?? false,
        late: sub.late,
        late_policy_status: sub.latePolicyStatus === 'none' ? null : sub.latePolicyStatus,
        missing: sub.missing,
        published_grade: sub.publishedGrade,
        // scores are stored as floats, for some reason it is typed as string | null in the code
        published_score: sub.publishedScore?.toString() ?? null,
        score: sub.score,
        seconds_late: sub.secondsLate,
        sub_assignment_tag: sub.subAssignmentTag ?? '',
      })) ?? [],
    workflow_state: it.state as WorkflowState,
    // @ts-expect-error
    attachments: it.attachments.map(x => ({id: x._id})),
    // adding these keys both camel and snake cased, not sure when and how the
    // transformation happens, if ever
    has_originality_report: it.hasOriginalityReport,
    hasOriginalityReport: it.hasOriginalityReport,
    turnitin_data: turnitinData as any,
    turnitinData: turnitinData as any,
    vericite_data: vericiteData as any,
    vericiteData: vericiteData as any,
    // The following attributes are either set by gradebook or not used
    assignedAssessments: undefined,
    assignment_visible: undefined,
    gradeLocked: undefined as unknown as boolean,
    versioned_attachments: undefined,
    rawGrade: null,
    graded_at: null,
    provisional_grade_id: undefined as unknown as string,
    similarityInfo: null,
    word_count: null,
    hidden: undefined as unknown as boolean,
    submission_comments: undefined as unknown as [],
    has_sub_assignment_submissions: it.assignment.hasSubAssignments,
  }
}
