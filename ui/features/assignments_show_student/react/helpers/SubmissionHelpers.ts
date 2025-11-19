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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Assignment, Points, Submission, SubmissionType} from '../../assignments_show_student'

const I18n = createI18nScope('assignments_2_submission_helpers')

export function friendlyTypeName(type: SubmissionType): string {
  switch (type) {
    case 'basic_lti_launch':
      return I18n.t('External Tool')
    case 'media_recording':
      return I18n.t('Media')
    case 'online_text_entry':
      return I18n.t('Text')
    case 'online_upload':
      return I18n.t('Upload')
    case 'online_url':
      return I18n.t('Web URL')
    case 'student_annotation':
      return I18n.t('Annotation')
    default:
      throw new Error('submission type not yet supported in A2')
  }
}

export function isSubmitted({state, attempt}: Pick<Submission, 'state' | 'attempt'>): boolean {
  return state === 'submitted' || (state === 'graded' && attempt !== 0)
}

export function multipleTypesDrafted(submission: Submission) {
  const submissionDraft = submission?.submissionDraft
  const matchingCriteria = [
    submissionDraft?.meetsBasicLtiLaunchCriteria,
    submissionDraft?.meetsTextEntryCriteria,
    submissionDraft?.meetsUploadCriteria,
    submissionDraft?.meetsUrlCriteria,
    submissionDraft?.meetsMediaRecordingCriteria,
    submissionDraft?.meetsStudentAnnotationCriteria,
  ].filter(criteria => criteria === true)

  return matchingCriteria.length > 1
}

export function totalAllowedAttempts(
  assignment: Pick<Assignment, 'allowedAttempts'>,
  submission?: Pick<Submission, 'extraAttempts'>,
): number | null {
  return assignment.allowedAttempts != null
    ? assignment.allowedAttempts + (submission?.extraAttempts || 0)
    : null
}

export const activeTypeMeetsCriteria = (
  activeSubmissionType: SubmissionType,
  submission?: Pick<Submission, 'submissionDraft'>,
) => {
  switch (activeSubmissionType) {
    case 'media_recording':
      return submission?.submissionDraft?.meetsMediaRecordingCriteria
    case 'online_text_entry':
      return submission?.submissionDraft?.meetsTextEntryCriteria
    case 'online_upload':
      return submission?.submissionDraft?.meetsUploadCriteria
    case 'online_url':
      return submission?.submissionDraft?.meetsUrlCriteria
    case 'student_annotation':
      return submission?.submissionDraft?.meetsStudentAnnotationCriteria
    case 'basic_lti_launch':
      return submission?.submissionDraft?.meetsBasicLtiLaunchCriteria
  }
}

export const getPointsValue = (points?: null | number | Points) => {
  if (typeof points === 'number') return points
  return points?.value ?? undefined
}
